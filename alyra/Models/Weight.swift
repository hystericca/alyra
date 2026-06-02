//
//  Weight.swift
//  alyra
//
//  Created by Viktor Luna on 6/1/26.
//

import Foundation

nonisolated struct WeightLogEntry: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var loggedAt: Date
    var weightKilograms: Double
    var note: String
    var reference: WeightLogReference

    private enum CodingKeys: String, CodingKey {
        case id
        case loggedAt
        case weightKilograms
        case weightPounds
        case note
        case reference
    }

    init(
        id: UUID,
        loggedAt: Date,
        weightKilograms: Double,
        note: String,
        reference: WeightLogReference = .manual
    ) {
        self.id = id
        self.loggedAt = loggedAt
        self.weightKilograms = weightKilograms
        self.note = note
        self.reference = reference
    }

    init(
        id: UUID,
        loggedAt: Date,
        displayWeight: Double,
        unitSystem: UnitSystem,
        note: String,
        reference: WeightLogReference = .manual
    ) {
        let value = Measurement(
            value: displayWeight,
            unit: unitSystem.weightUnit
        ).converted(to: .kilograms).value

        self.init(
            id: id,
            loggedAt: loggedAt,
            weightKilograms: value,
            note: note,
            reference: reference
        )
    }

    func displayWeight(for unitSystem: UnitSystem) -> Double {
        Measurement(
            value: weightKilograms,
            unit: UnitMass.kilograms
        )
        .converted(to: unitSystem.weightUnit)
        .value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        loggedAt = try container.decode(Date.self, forKey: .loggedAt)
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        reference = try container.decodeIfPresent(WeightLogReference.self, forKey: .reference) ?? .manual

        if let value = try container.decodeIfPresent(Double.self, forKey: .weightKilograms) {
            weightKilograms = value
        } else {
            let pounds = try container.decode(Double.self, forKey: .weightPounds)
            weightKilograms = Measurement(
                value: pounds,
                unit: UnitMass.pounds
            )
            .converted(to: .kilograms)
            .value
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(loggedAt, forKey: .loggedAt)
        try container.encode(weightKilograms, forKey: .weightKilograms)
        try container.encode(note, forKey: .note)
        try container.encode(reference, forKey: .reference)
    }
}

nonisolated enum WeightDataSource: String, Codable, Sendable {
    case manual
    case appleHealth
}

nonisolated struct WeightLogReference: Codable, Equatable, Sendable {
    var source: WeightDataSource
    var externalID: String?

    static let manual = WeightLogReference(source: .manual, externalID: nil)

    static func appleHealth(sampleID: String) -> WeightLogReference {
        WeightLogReference(source: .appleHealth, externalID: sampleID)
    }
}

nonisolated struct WeightImportResult: Equatable, Sendable {
    var scanned: Int
    var inserted: Int
    var updated: Int

    var summary: String {
        if scanned == 0 {
            return "No readable Apple Health weight samples were found. Check Health read access and confirm Health has weight data."
        }

        if inserted == 0 && updated == 0 {
            return "Scanned \(scanned) Apple Health weight samples. Alyra already had them."
        }

        return "Imported \(inserted) and updated \(updated) of \(scanned) Apple Health weight samples."
    }
}

nonisolated enum WeightLogMerge {
    static func merge(_ incoming: [WeightLogEntry], into entries: inout [WeightLogEntry]) -> WeightImportResult {
        var inserted = 0
        var updated = 0

        for item in incoming {
            if let index = entries.firstIndex(where: { existing in
                existing.reference.source == item.reference.source &&
                existing.reference.externalID == item.reference.externalID &&
                item.reference.externalID != nil
            }) {
                entries[index] = item
                updated += 1
            } else {
                entries.append(item)
                inserted += 1
            }
        }

        return WeightImportResult(
            scanned: incoming.count,
            inserted: inserted,
            updated: updated
        )
    }
}

enum WeightLogStore {
    private static let storageKey = "alyra.weight.logEntries"

    static func load() -> [WeightLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WeightLogEntry].self, from: data)
        } catch {
            return []
        }
    }

    static func save(_ entries: [WeightLogEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            assertionFailure("Failed to save weight log entries: \(error)")
        }
    }
}
