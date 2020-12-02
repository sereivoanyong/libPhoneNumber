//
//  Metadata.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 03/10/2015.
//  Copyright © 2020 Roy Marmelstein. All rights reserved.
//

import Foundation

private func populateTerritories() -> [MetadataTerritory] {
    do {
        guard let url = Bundle.module.url(forResource: "PhoneNumberMetadata", withExtension: "json") else {
          throw PhoneNumberError.metadataNotFound
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let metadata = try decoder.decode(PhoneNumberMetadata.self, from: data)
        return metadata.territories
    } catch {
        debugPrint("ERROR: Unable to load PhoneNumberMetadata.json resource: \(error.localizedDescription)")
        return []
    }
}

struct MetadataManager {
    let territories: [MetadataTerritory]
    let territoriesByCountryCodes: [Int32: [MetadataTerritory]]
    let mainTerritoryByCountryCodes: [Int32: MetadataTerritory]
    let territoriesByRegionCodes: [String: MetadataTerritory]

    // MARK: Lifecycle

    /// Private init populates metadata territories and the two hashed dictionaries for faster lookup.
    ///
    /// - Parameter metadataCallback: a closure that returns metadata as JSON Data.
    init() {
        self.territories = populateTerritories()
        var territoriesByCountryCodes: [Int32: [MetadataTerritory]] = [:]
        var mainTerritoryByCountryCodes: [Int32: MetadataTerritory] = [:]
        var territoriesByCountry: [String: MetadataTerritory] = [:]
        for item in self.territories {
            var currentTerritories = territoriesByCountryCodes[item.countryCode] ?? []
            // In the case of multiple countries sharing a calling code, such as the NANPA countries,
            // the one indicated with "isMainCountryForCode" in the metadata should be first.
            if item.mainCountryForCode {
                currentTerritories.insert(item, at: 0)
            } else {
                currentTerritories.append(item)
            }
            territoriesByCountryCodes[item.countryCode] = currentTerritories
            if mainTerritoryByCountryCodes[item.countryCode] == nil || item.mainCountryForCode {
              mainTerritoryByCountryCodes[item.countryCode] = item
            }
            territoriesByCountry[item.regionCode] = item
        }
        self.territoriesByCountryCodes = territoriesByCountryCodes
        self.mainTerritoryByCountryCodes = mainTerritoryByCountryCodes
        self.territoriesByRegionCodes = territoriesByCountry
    }
}
