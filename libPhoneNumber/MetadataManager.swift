//
//  Metadata.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

/// Internal object for metadata parsing
private struct PhoneNumberMetadata: Decodable {
    
    let territories: [PhoneMetadata]
    
    private enum CodingKeys: String, CodingKey {
        
        case phoneNumberMetadata
        case territories
        case territory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metadataObject = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .phoneNumberMetadata)
        let territoryObject = try metadataObject.nestedContainer(keyedBy: CodingKeys.self, forKey: .territories)
        territories = try territoryObject.decode([PhoneMetadata].self, forKey: .territory)
    }
}

private func populateTerritories() -> [PhoneMetadata] {
    do {
        guard let url = Bundle.module.url(forResource: "PhoneNumberMetadata", withExtension: "json") else {
            debugPrint("PhoneNumberUtil was unable to read the included metadata")
            return []
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
    
    let territories: [PhoneMetadata]
    let territoriesByCountryCodes: [Int32: [PhoneMetadata]]
    let mainTerritoryByCountryCodes: [Int32: PhoneMetadata]
    let territoriesByRegionCodes: [String: PhoneMetadata]

    // MARK: Lifecycle

    /// Private init populates metadata territories and the two hashed dictionaries for faster lookup.
    ///
    /// - Parameter metadataCallback: a closure that returns metadata as JSON Data.
    init() {
        self.territories = populateTerritories()
        var territoriesByCountryCodes: [Int32: [PhoneMetadata]] = [:]
        var mainTerritoryByCountryCodes: [Int32: PhoneMetadata] = [:]
        var territoriesByCountry: [String: PhoneMetadata] = [:]
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
