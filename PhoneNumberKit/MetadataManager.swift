//
//  Metadata.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 03/10/2015.
//  Copyright © 2020 Roy Marmelstein. All rights reserved.
//

import Foundation

struct MetadataManager {
    let territories: [MetadataTerritory]
    let territoriesByCode: [UInt64: [MetadataTerritory]]
    let mainTerritoryByCode: [UInt64: MetadataTerritory]
    let territoriesByCountry: [String: MetadataTerritory]

    // MARK: Lifecycle

    /// Private init populates metadata territories and the two hashed dictionaries for faster lookup.
    ///
    /// - Parameter metadataCallback: a closure that returns metadata as JSON Data.
    init(metadataCallback: MetadataCallback) {
        self.territories = Self.populateTerritories(metadataCallback: metadataCallback)
        var territoriesByCode: [UInt64: [MetadataTerritory]] = [:]
        var mainTerritoryByCode: [UInt64: MetadataTerritory] = [:]
        var territoriesByCountry: [String: MetadataTerritory] = [:]
        for item in self.territories {
            var currentTerritories = territoriesByCode[item.countryCode] ?? []
            // In the case of multiple countries sharing a calling code, such as the NANPA countries,
            // the one indicated with "isMainCountryForCode" in the metadata should be first.
            if item.mainCountryForCode {
                currentTerritories.insert(item, at: 0)
            } else {
                currentTerritories.append(item)
            }
            territoriesByCode[item.countryCode] = currentTerritories
            if mainTerritoryByCode[item.countryCode] == nil || item.mainCountryForCode {
                mainTerritoryByCode[item.countryCode] = item
            }
            territoriesByCountry[item.codeID] = item
        }
        self.territoriesByCode = territoriesByCode
        self.mainTerritoryByCode = mainTerritoryByCode
        self.territoriesByCountry = territoriesByCountry
    }

    /// Populates the metadata from a metadataCallback.
    ///
    /// - Parameter metadataCallback: a closure that returns metadata as JSON Data.
    /// - Returns: array of MetadataTerritory objects
    private static func populateTerritories(metadataCallback: MetadataCallback) -> [MetadataTerritory] {
        do {
            let jsonData = try metadataCallback()
            let jsonDecoder = JSONDecoder()
            let metadata = try jsonDecoder.decode(PhoneNumberMetadata.self, from: jsonData)
            return metadata.territories
        } catch {
            debugPrint("ERROR: Unable to load PhoneNumberMetadata.json resource: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: Filters

    /// Get an array of MetadataTerritory objects corresponding to a given country code.
    ///
    /// - parameter code:  international country code (e.g 44 for the UK).
    ///
    /// - returns: optional array of MetadataTerritory objects.
    func filterTerritories(byCode code: UInt64) -> [MetadataTerritory]? {
        return territoriesByCode[code]
    }

    /// Get the MetadataTerritory objects for an ISO 639 compliant region code.
    ///
    /// - parameter country: ISO 639 compliant region code (e.g "GB" for the UK).
    ///
    /// - returns: A MetadataTerritory object.
    func filterTerritories(byCountry country: String) -> MetadataTerritory? {
        return territoriesByCountry[country.uppercased()]
    }

    /// Get the main MetadataTerritory objects for a given country code.
    ///
    /// - parameter code: An international country code (e.g 1 for the US).
    ///
    /// - returns: A MetadataTerritory object.
    func mainTerritory(forCode code: UInt64) -> MetadataTerritory? {
        return mainTerritoryByCode[code]
    }
}
