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

            try? await HKHealthStore().save(sample)
        #endif
    }

    static func saveFood(_ entry: FoodLogEntry) async {
        #if canImport(HealthKit)
            guard HKHealthStore.isHealthDataAvailable() else { return }

            let store = HKHealthStore()
            let samples = nutritionSamples(for: entry, store: store)
            guard !samples.isEmpty else { return }

            try? await store.save(samples)
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
            metadata: metadata(
                sourceID: "\(entry.id.uuidString).\(identifier.rawValue)",
                foodName: entry.foodName
            )
        )
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
