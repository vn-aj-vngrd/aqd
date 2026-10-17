import AQDCore
import Foundation
import SwiftData

enum LocalSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [StoredPiece.self, StoredPhoto.self, StoredPieceSave.self, StoredPieceDraft.self, StoredPieceDeletion.self, StoredTodayConfiguration.self] }
}

enum LocalSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV1.models + [StoredPhotoCleanup.self] }
}

enum LocalSchemaV3: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(3, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV2.models + [StoredLocalExperience.self] }
}

enum LocalSchemaV4: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(4, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV3.models + [StoredOutfit.self, StoredOutfitDraft.self, StoredOutfitSave.self] }
}

enum LocalSchemaV5: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(5, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV4.models + [StoredOutfitTheme.self, StoredThemeDraft.self, StoredThemeSave.self] }
}

enum LocalSchemaV6: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(6, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV5.models + [StoredOutfitPlanEntry.self, StoredOutfitPlanDraft.self, StoredOutfitPlanSave.self] }
}

enum LocalSchemaV7: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(7, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV6.models + [StoredOutfitWear.self, StoredOutfitWearDraft.self, StoredOutfitWearSave.self] }
}

enum LocalSchemaV8: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(8, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV7.models + [StoredOutfitMutation.self] }
}

enum LocalSchemaV9: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(9, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV8.models + [StoredPieceDeletionReview.self] }
}

enum LocalSchemaV10: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(10, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV9.models + [StoredThemeDeletion.self] }
}

enum LocalSchemaV11: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(11, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV10.models + [StoredPlanEntryDeletion.self] }
}

enum LocalSchemaV12: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(12, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV11.models + [StoredPlanDefinition.self, StoredPlanAuthoringDraft.self, StoredPlanAuthoringSave.self] }
}

enum LocalSchemaV13: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(13, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV12.models + [StoredPackingState.self, StoredPackingCheck.self] }
}

enum LocalSchemaV14: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(14, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV13.models + [StoredHistoryMutation.self] }
}

enum LocalSchemaV15: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(15, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV14.models + [StoredLocalIdentity.self, StoredIdentityDraft.self, StoredIdentitySave.self] }
}

enum LocalSchemaV16: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(16, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV15.models + [StoredFitMemory.self, StoredFitDraft.self, StoredFitSave.self, StoredFitDeletion.self] }
}

enum LocalSchemaV17: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(17, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV16.models + [StoredTodayLayout.self, StoredTodayDraft.self, StoredTodaySave.self, StoredTodayUndo.self, StoredTodayPersonalCard.self] }
}

enum LocalSchemaV18: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(18, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV17.models + [StoredTodayCardDeletion.self] }
}

enum LocalSchemaV19: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(19, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV18.models + [StoredPhotoSource.self] }
}

enum LocalSchemaV20: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(20, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV19.models + [StoredWeatherState.self, StoredWeatherSave.self] }
}

enum LocalSchemaV21: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(21, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV20.models + [StoredAgentConversation.self, StoredAgentOperation.self] }
}

enum LocalSchemaV22: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(22, 0, 0) }
    static var models: [any PersistentModel.Type] { LocalSchemaV21.models + [StoredLocalSettings.self, StoredSettingsSave.self, StoredLocalMutation.self] }
}

enum LocalMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [LocalSchemaV1.self, LocalSchemaV2.self, LocalSchemaV3.self, LocalSchemaV4.self, LocalSchemaV5.self, LocalSchemaV6.self, LocalSchemaV7.self, LocalSchemaV8.self, LocalSchemaV9.self, LocalSchemaV10.self, LocalSchemaV11.self, LocalSchemaV12.self, LocalSchemaV13.self, LocalSchemaV14.self, LocalSchemaV15.self, LocalSchemaV16.self, LocalSchemaV17.self, LocalSchemaV18.self, LocalSchemaV19.self, LocalSchemaV20.self, LocalSchemaV21.self, LocalSchemaV22.self] }
    static var stages: [MigrationStage] {
        [.lightweight(fromVersion: LocalSchemaV1.self, toVersion: LocalSchemaV2.self),
         .lightweight(fromVersion: LocalSchemaV2.self, toVersion: LocalSchemaV3.self),
         .lightweight(fromVersion: LocalSchemaV3.self, toVersion: LocalSchemaV4.self),
         .lightweight(fromVersion: LocalSchemaV4.self, toVersion: LocalSchemaV5.self),
         .lightweight(fromVersion: LocalSchemaV5.self, toVersion: LocalSchemaV6.self),
         .lightweight(fromVersion: LocalSchemaV6.self, toVersion: LocalSchemaV7.self),
         .lightweight(fromVersion: LocalSchemaV7.self, toVersion: LocalSchemaV8.self),
         .lightweight(fromVersion: LocalSchemaV8.self, toVersion: LocalSchemaV9.self),
         .lightweight(fromVersion: LocalSchemaV9.self, toVersion: LocalSchemaV10.self),
         .lightweight(fromVersion: LocalSchemaV10.self, toVersion: LocalSchemaV11.self),
         .lightweight(fromVersion: LocalSchemaV11.self, toVersion: LocalSchemaV12.self),
         .lightweight(fromVersion: LocalSchemaV12.self, toVersion: LocalSchemaV13.self),
         .lightweight(fromVersion: LocalSchemaV13.self, toVersion: LocalSchemaV14.self),
         .lightweight(fromVersion: LocalSchemaV14.self, toVersion: LocalSchemaV15.self),
         .lightweight(fromVersion: LocalSchemaV15.self, toVersion: LocalSchemaV16.self),
         .lightweight(fromVersion: LocalSchemaV16.self, toVersion: LocalSchemaV17.self),
         .lightweight(fromVersion: LocalSchemaV17.self, toVersion: LocalSchemaV18.self),
         .lightweight(fromVersion: LocalSchemaV18.self, toVersion: LocalSchemaV19.self),
         .lightweight(fromVersion: LocalSchemaV19.self, toVersion: LocalSchemaV20.self),
         .lightweight(fromVersion: LocalSchemaV20.self, toVersion: LocalSchemaV21.self),
         .lightweight(fromVersion: LocalSchemaV21.self, toVersion: LocalSchemaV22.self)]
    }
}
