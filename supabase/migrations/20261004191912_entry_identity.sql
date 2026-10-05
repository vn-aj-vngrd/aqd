create schema if not exists aqd_private;
revoke all on schema aqd_private from public, anon;
grant usage on schema aqd_private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  username text not null check (username ~ '^[a-zA-Z0-9_.]{3,30}$'),
  created_at timestamptz not null default now()
);
create unique index profiles_username_unique on public.profiles (lower(username));
alter table public.profiles enable row level security;
grant select, insert, update on public.profiles to authenticated;
create policy profile_read on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profile_create on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy profile_edit on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

create table public.private_pieces (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 80),
  category text not null check (category in ('tops','bottoms','dresses','layers','shoes','accessories')),
  photo_path text,
  created_at timestamptz not null,
  connected_at timestamptz not null default now()
);
create index private_pieces_owner on public.private_pieces(owner_id);
alter table public.private_pieces enable row level security;
grant select on public.private_pieces to authenticated;
create policy private_piece_read on public.private_pieces for select to authenticated using (owner_id = (select auth.uid()));

create table public.closet_connections (
  operation_id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  payload_hash text not null,
  piece_ids uuid[] not null,
  confirmed_at timestamptz not null default now()
);
create index closet_connections_owner on public.closet_connections(owner_id);
alter table public.closet_connections enable row level security;
grant select on public.closet_connections to authenticated;
create policy connection_read on public.closet_connections for select to authenticated using (owner_id = (select auth.uid()));

-- Narrow privileged command: direct table writes are denied. Server identity, transaction
-- lock, validation and receipt replay protect ownership and all-or-nothing association.
create function aqd_private.connect_closet(p_operation_id uuid, p_pieces jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  account_id uuid := auth.uid();
  receipt public.closet_connections;
  body_hash text := md5(p_pieces::text);
  piece jsonb;
  path text;
  ids uuid[] := array[]::uuid[];
begin
  if account_id is null then raise exception 'authentication_required' using errcode = '42501'; end if;
  if jsonb_typeof(p_pieces) <> 'array' or jsonb_array_length(p_pieces) not between 1 and 500 then
    raise exception 'invalid_piece_batch' using errcode = '22023';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(account_id::text, 0));
  select * into receipt from public.closet_connections where operation_id = p_operation_id;
  if found then
    if receipt.owner_id <> account_id or receipt.payload_hash <> body_hash then
      raise exception 'operation_conflict' using errcode = '22023';
    end if;
    return jsonb_build_object('piece_ids', receipt.piece_ids, 'confirmed_at', receipt.confirmed_at);
  end if;
  if exists(select 1 from public.private_pieces where owner_id = account_id) then
    raise exception 'closet_conflict' using errcode = 'P0001';
  end if;
  for piece in select value from jsonb_array_elements(p_pieces) loop
    path := piece->>'photo_path';
    if path is not null then
      if path <> account_id::text || '/' || p_operation_id::text || '/' || ((piece->>'id')::uuid)::text || '.jpg'
        or not exists(select 1 from storage.objects where bucket_id = 'closet' and name = path) then
        raise exception 'photo_not_ready' using errcode = '22023';
      end if;
    end if;
    insert into public.private_pieces(id, owner_id, name, category, photo_path, created_at)
    values ((piece->>'id')::uuid, account_id, btrim(piece->>'name'), piece->>'category', path, (piece->>'created_at')::timestamptz);
    ids := array_append(ids, (piece->>'id')::uuid);
  end loop;
  insert into public.closet_connections(operation_id, owner_id, payload_hash, piece_ids)
  values(p_operation_id, account_id, body_hash, ids) returning * into receipt;
  return jsonb_build_object('piece_ids', receipt.piece_ids, 'confirmed_at', receipt.confirmed_at);
end;
$$;
revoke all on function aqd_private.connect_closet(uuid,jsonb) from public, anon;
grant execute on function aqd_private.connect_closet(uuid,jsonb) to authenticated;

create function public.connect_closet(p_operation_id uuid, p_pieces jsonb)
returns jsonb language sql security invoker set search_path = '' as $$
  select aqd_private.connect_closet(p_operation_id, p_pieces);
$$;
revoke all on function public.connect_closet(uuid,jsonb) from public, anon;
grant execute on function public.connect_closet(uuid,jsonb) to authenticated;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values ('closet', 'closet', false, 5242880, array['image/jpeg']);
create policy closet_media_read on storage.objects for select to authenticated
using (bucket_id = 'closet' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy closet_media_create on storage.objects for insert to authenticated
with check (bucket_id = 'closet' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy closet_media_replace on storage.objects for update to authenticated
using (bucket_id = 'closet' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'closet' and (storage.foldername(name))[1] = (select auth.uid())::text);
