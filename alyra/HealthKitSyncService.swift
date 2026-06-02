import Foundation

#if canImport(HealthKit)
    import HealthKit
#endif

enum HealthKitSyncScope: String, CaseIterable, Identifiable {
    case weight
    case nutrition

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weight: "Weight"
        case .nutrition: "Food nutrition"
        }
    }
}

enum HealthKitSyncAvailability: Equatable {
    case available
    case unavailable(String)

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .available:
            "Available"
        case .unavailable(let reason):
            reason
        }
    }
}

enum HealthKitSyncService {
    static var availability: HealthKitSyncAvailability {
        #if canImport(HealthKit)
            HKHealthStore.isHealthDataAvailable()
                ? .available
                : .unavailable("Health data is not available on this device.")
        #else
            .unavailable("HealthKit is not available in this build.")
        #endif
    }

    static func requestAuthorization(scopes: Set<HealthKitSyncScope>) async throws {
        #if canImport(HealthKit)
            guard HKHealthStore.isHealthDataAvailable() else { return }

            let shareTypes = sampleTypes(for: scopes)
            let readTypes = objectTypes(for: scopes)
            try await HKHealthStore().requestAuthorization(toShare: shareTypes, read: readTypes)
        #endif
    }

    static func saveWeight(_ entry: WeightLogEntry) async {
        #if canImport(HealthKit)
            guard
                HKHealthStore.isHealthDataAvailable(),
                let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
                HKHealthStore().authorizationStatus(for: bodyMassType) == .sharingAuthorized
            else {
                return
            }

            let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: entry.weightKilograms)
            let sample = HKQuantitySample(
                type: bodyMassType,
                quantity: quantity,
                start: entry.loggedAt,
                end: entry.loggedAt,
                metadata: metadata(sourceID: entry.id.uuidString)
            )

            let store = HKHealthStore()
            await deleteExistingSample(type: bodyMassType, sourceID: entry.id.uuidString, store: store)
            try? await store.save(sample)
        #endif
    }

    static func deleteWeight(_ entry: WeightLogEntry) async {
        #if canImport(HealthKit)
            guard
                HKHealthStore.isHealthDataAvailable(),
                let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)
            else {
                return
            }

            await deleteExistingSample(type: bodyMassType, sourceID: entry.id.uuidString, store: HKHealthStore())
        #endif
    }

    static func importWeights(from start: Date, to end: Date) async throws -> [WeightLogEntry] {
        #if canImport(HealthKit)
            guard
                HKHealthStore.isHealthDataAvailable(),
                let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)
            else {
                return []
            }

            let store = HKHealthStore()
            let predicate = HKQuery.predicateForSamples(
                withStart: start,
                end: end,
                options: []
            )

            return try await withCheckedThrowingContinuation { continuation in
                let sort = NSSortDescriptor(
                    key: HKSampleSortIdentifierEndDate,
                    ascending: true
                )

                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sort]
                ) { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }

                    let logs = (samples as? [HKQuantitySample] ?? []).map { sample in
                        WeightLogEntry(
                            id: sample.uuid,
                            loggedAt: sample.endDate,
                            weightKilograms: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                            note: "Imported from Apple Health",
                            reference: .appleHealth(sampleID: sample.uuid.uuidString)
                        )
                    }

                    continuation.resume(returning: logs)
                }

                store.execute(query)
            }
        #else
            return []
        #endif
    }

    static func saveFood(_ entry: FoodLogEntry) async {
        #if canImport(HealthKit)
            guard
                HKHealthStore.isHealthDataAvailable(),
                let foodType = HKObjectType.correlationType(forIdentifier: .food)
            else {
                return
            }

            let store = HKHealthStore()
            let samples = nutritionSamples(for: entry, store: store)
            guard !samples.isEmpty else { return }

            await deleteExistingFoodObjects(for: entry, foodType: foodType, store: store)

            let correlation = HKCorrelation(
                type: foodType,
                start: entry.loggedAt,
                end: entry.loggedAt,
                objects: Set(samples),
                metadata: metadata(sourceID: foodSourceID(entry), foodName: entry.foodName)
            )

            try? await store.save(correlation)
        #endif
    }

    static func deleteFood(_ entry: FoodLogEntry) async {
        #if canImport(HealthKit)
            guard
                HKHealthStore.isHealthDataAvailable(),
                let foodType = HKObjectType.correlationType(forIdentifier: .food)
            else {
                return
            }

            await deleteExistingFoodObjects(for: entry, foodType: foodType, store: HKHealthStore())
        #endif
    }
}

#if canImport(HealthKit)
private extension HealthKitSyncService {
    static func sampleTypes(for scopes: Set<HealthKitSyncScope>) -> Set<HKSampleType> {
        Set(objectTypes(for: scopes).compactMap { $0 as? HKSampleType })
    }

    static func objectTypes(for scopes: Set<HealthKitSyncScope>) -> Set<HKObjectType> {
        var types = Set<HKObjectType>()

        if scopes.contains(.weight),
           let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(type)
        }

        if scopes.contains(.nutrition) {
            nutritionIdentifiers.compactMap(HKQuantityType.quantityType(forIdentifier:)).forEach {
                types.insert($0)
            }
        }

        return types
    }

    static var nutritionIdentifiers: [HKQuantityTypeIdentifier] {
        [
            .dietaryEnergyConsumed,
            .dietaryProtein,
            .dietaryCarbohydrates,
            .dietaryFatTotal,
            .dietaryFiber,
        ]
    }

    static func nutritionSamples(for entry: FoodLogEntry, store: HKHealthStore) -> [HKQuantitySample] {
        [
            nutritionSample(
                identifier: .dietaryEnergyConsumed,
                value: entry.nutrients.calories,
                unit: .kilocalorie(),
                entry: entry,
                store: store
            ),
            nutritionSample(
                identifier: .dietaryProtein,
                value: entry.nutrients.protein,
                unit: .gram(),
                entry: entry,
                store: store
            ),
            nutritionSample(
                identifier: .dietaryCarbohydrates,
                value: entry.nutrients.carbs,
                unit: .gram(),
                entry: entry,
                store: store
            ),
            nutritionSample(
                identifier: .dietaryFatTotal,
                value: entry.nutrients.fat,
                unit: .gram(),
                entry: entry,
                store: store
            ),
            nutritionSample(
                identifier: .dietaryFiber,
                value: entry.nutrients.fiber,
                unit: .gram(),
                entry: entry,
                store: store
            ),
        ]
        .compactMap { $0 }
    }

    static func nutritionSample(
        identifier: HKQuantityTypeIdentifier,
        value: Double,
        unit: HKUnit,
        entry: FoodLogEntry,
        store: HKHealthStore
    ) -> HKQuantitySample? {
        guard
            value > 0,
            let type = HKQuantityType.quantityType(forIdentifier: identifier),
            store.authorizationStatus(for: type) == .sharingAuthorized
        else {
            return nil
        }

        let quantity = HKQuantity(unit: unit, doubleValue: value)
        return HKQuantitySample(
            type: type,
            quantity: quantity,
            start: entry.loggedAt,
            end: entry.loggedAt,
            metadata: metadata(sourceID: nutritionSourceID(entry: entry, identifier: identifier))
        )
    }

    static func deleteExistingFoodObjects(
        for entry: FoodLogEntry,
        foodType: HKCorrelationType,
        store: HKHealthStore
    ) async {
        await deleteExistingSample(
            type: foodType,
            sourceID: foodSourceID(entry),
            store: store
        )
        await deleteExistingNutritionSamples(for: entry, store: store)
    }

    static func deleteExistingNutritionSamples(for entry: FoodLogEntry, store: HKHealthStore) async {
        for identifier in nutritionIdentifiers {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            await deleteExistingSample(
                type: type,
                sourceID: nutritionSourceID(entry: entry, identifier: identifier),
                store: store
            )
        }
    }

    static func foodSourceID(_ entry: FoodLogEntry) -> String {
        entry.id.uuidString
    }

    static func nutritionSourceID(
        entry: FoodLogEntry,
        identifier: HKQuantityTypeIdentifier
    ) -> String {
        "\(entry.id.uuidString).\(identifier.rawValue)"
    }

    static func deleteExistingSample(
        type: HKObjectType,
        sourceID: String,
        store: HKHealthStore
    ) async {
        let predicate = NSPredicate(
            format: "%K.%K == %@",
            HKPredicateKeyPathMetadata,
            HKMetadataKeyExternalUUID,
            sourceID
        )

        _ = try? await store.deleteObjects(of: type, predicate: predicate)
    }

    static func metadata(sourceID: String, foodName: String? = nil) -> [String: Any] {
        var metadata: [String: Any] = [
            HKMetadataKeyExternalUUID: sourceID,
        ]

        if let foodName, !foodName.isEmpty {
            metadata[HKMetadataKeyFoodType] = foodName
        }

        return metadata
    }
}
#endif
