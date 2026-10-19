# AQD

**Your wardrobe, understood.** AQD is a private closet for iPhone. Photograph what you own, put it together into outfits and themes, plan what to wear for the week or a trip, keep track of what you actually wear, and ask an on-device Agent for help. There is no account and no cloud: everything lives on your phone.

## What it does

| | |
| --- | --- |
| **Today** | A home stack of cards you arrange yourself: today's look, your week in wear, wear insights, closet in use, upcoming plans, pieces to wear again, favorite outfits, a theme, the fit journal, weather, quick actions and personal notes or photos. Every card is configurable. |
| **Closet** | Pieces with a cover photo and details (category, color, brand, size, material, season, tags, availability), plus outfits and themes. Search, filter, sort, archive and restore. |
| **Planner** | Plan single days, routines and trips. Trips get a packing list built from their outfits. Record what you wore, browse wear history and see monthly insights. |
| **Agent** | Ask about your closet in plain words. It shows your pieces as cards, answers wear questions from what you recorded, suggests outfits, plans a trip as a varied look per day, and asks one question at a time with tappable answers when something is missing. It only ever drafts: nothing changes until you review it and tap Apply. |
| **Profile** | A private fit journal of photos and notes, an optional name and photo, style preferences, and Settings for appearance, AI sources, data export and restore. |

## Private by design

- **On the device.** Records and photos are stored locally with complete file protection and kept out of automatic backup. Corrupt or newer stores are kept, never overwritten.
- **On-device AI.** The Agent runs on Apple's Foundation Models when the phone supports it. It reads only the sources you allow, refers to your items by name, and has its replies checked against your actual closet before you see them. Every manual path works without it.
- **One optional network call.** Weather is off until you pick a place; then only that place and date go to Apple WeatherKit.
- **Your data, portable.** Export a versioned archive, restore it with a review, or erase everything locally.

## Built with

SwiftUI and SwiftData (CloudKit off) for iOS 18 and later, built with Xcode 27. Liquid Glass on iOS 26 and later, with flat fallbacks. Foundation Models for the Agent, PhotosPicker and the camera for capture, WeatherKit for the optional forecast. Pure domain rules live in a separate Swift package (`Core`) with its own tests.

```text
apps/ios/   The SwiftUI app, the Core package and the test targets
docs/       Product scope, architecture, delivery, feature contracts and decisions (ADRs)
scripts/    Native test runner, commit and layer checks, release tooling
```

## Start here

| To | Read |
| --- | --- |
| Build, test and run on a phone | [apps/ios/README.md](apps/ios/README.md) |
| Understand scope and what comes next | [docs/product.md](docs/product.md) |
| See how storage, media, Agent and weather fit together | [docs/architecture.md](docs/architecture.md) |
| Change how a feature behaves | [docs/features](docs/features) |
| Design any UI | [DESIGN.md](DESIGN.md) |
| Learn the domain words | [CONTEXT.md](CONTEXT.md) |
| Branch, commit, open a PR or release | [docs/delivery.md](docs/delivery.md) |
| Work on it as an AI agent | [AGENTS.md](AGENTS.md) |

Plans, status and evidence live in [GitHub issues](https://github.com/vn-aj-vngrd/aqd/issues), not in the repo. The connected V2 (sign-in, sync, sharing and more) is kept as a backlog in [docs/product.md](docs/product.md).
