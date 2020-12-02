//
//  ParseManager.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 01/11/2015.
//  Copyright © 2020 Roy Marmelstein. All rights reserved.
//

import Foundation

/**
 Manager for parsing flow.
 */
struct ParseManager {
    let regexManager: RegexManager
    let metadataManager: MetadataManager
    let parser: PhoneNumberParser

    init(regexManager: RegexManager, metadataManager: MetadataManager) {
        self.regexManager = regexManager
        self.metadataManager = metadataManager
        self.parser = PhoneNumberParser(regexManager: regexManager, metadataManager: metadataManager)
    }

    /**
     Parse a string into a phone number object with a custom region. Can throw.
     - Parameter numberString: String to be parsed to phone number struct.
     - Parameter regionCode: ISO 639 compliant region code.
     - parameter ignoreType:   Avoids number type checking for faster performance.
     */
    func parse(_ numberString: String, regionCode: String, ignoreType: Bool) throws -> PhoneNumber {
        assert(regionCode == regionCode.uppercased())
        // Extract number (2)

        var nationalNumber = numberString

        let match = try regexManager.phoneDataDetectorMatch(numberString)
        let matchedNumber = nationalNumber.substring(with: match.range)
        // Replace Arabic and Persian numerals and let the rest unchanged
        nationalNumber = regexManager.stringByReplacingOccurrences(matchedNumber, map: PhoneNumberPatterns.allNormalizationMappings, keepUnmapped: true)

        // Strip and extract extension (3)
        var numberExtension: String?
        if let rawExtension = parser.stripExtension(&nationalNumber) {
            numberExtension = parser.normalizePhoneNumber(rawExtension)
        }
        // Country code parse (4)
        guard var regionMetadata = metadataManager.territoriesByRegionCodes[regionCode] else {
            throw PhoneNumberError.invalidCountryCode
        }
        var countryCode: Int32
        do {
            countryCode = try parser.extractCountryCode(nationalNumber, nationalNumber: &nationalNumber, metadata: regionMetadata)
        } catch {
            let plusRemovedNumberString = regexManager.replaceStringByRegex(PhoneNumberPatterns.leadingPlusCharsPattern, string: nationalNumber as String)
            countryCode = try parser.extractCountryCode(plusRemovedNumberString, nationalNumber: &nationalNumber, metadata: regionMetadata)
        }
        if countryCode == 0 {
            countryCode = regionMetadata.countryCode
        }
        // Normalized number (5)
        let normalizedNationalNumber = parser.normalizePhoneNumber(nationalNumber)
        nationalNumber = normalizedNationalNumber

        // If country code is not default, grab correct metadata (6)
        if countryCode != regionMetadata.countryCode, let countryMetadata = metadataManager.mainTerritoryByCountryCodes[countryCode] {
            regionMetadata = countryMetadata
        }
        // National Prefix Strip (7)
        parser.stripNationalPrefix(&nationalNumber, metadata: regionMetadata)

        // Test number against general number description for correct metadata (8)
        if let generalNumberDesc = regionMetadata.generalDesc, !regexManager.hasValue(generalNumberDesc.nationalNumberPattern) || !parser.isNumberMatchingDesc(nationalNumber, numberDesc: generalNumberDesc) {
            throw PhoneNumberError.notANumber
        }
        // Finalize remaining parameters and create phone number object (9)
        let leadingZero = nationalNumber.hasPrefix("0")
        guard let finalNationalNumber = UInt64(nationalNumber) else {
            throw PhoneNumberError.notANumber
        }

        // Check if the number if of a known type (10)
        var type: PhoneNumberType = .unknown
        if !ignoreType {
            if let regionCode = self.regionCode(nationalNumber: finalNationalNumber, countryCode: countryCode, leadingZero: leadingZero), let foundMetadata = metadataManager.territoriesByRegionCodes[regionCode] {
                regionMetadata = foundMetadata
            }
            type = parser.type(String(nationalNumber), metadata: regionMetadata, leadingZero: leadingZero)
            if type == .unknown {
                throw PhoneNumberError.unknownType
            }
        }

        let phoneNumber = PhoneNumber(string: numberString, countryCode: countryCode, leadingZero: leadingZero, nationalNumber: finalNationalNumber, numberExtension: numberExtension, type: type, regionCode: regionMetadata.regionCode)
        return phoneNumber
    }

    // Parse task

    /// Get correct ISO 639 compliant region code for a number.
    ///
    /// - Parameters:
    ///   - nationalNumber: national number.
    ///   - countryCode: country code.
    ///   - leadingZero: whether or not the number has a leading zero.
    /// - Returns: ISO 639 compliant region code.
    func regionCode(nationalNumber: UInt64, countryCode: Int32, leadingZero: Bool) -> String? {
        guard let territories = metadataManager.territoriesByCountryCodes[countryCode] else { return nil }

        if territories.count == 1 {
            return territories[0].regionCode
        }

        let nationalNumberString = String(nationalNumber)
        for territory in territories {
            if let leadingDigits = territory.leadingDigits {
                if regexManager.matchesAtStart(leadingDigits, string: nationalNumberString) {
                    return territory.regionCode
                }
            }
            if leadingZero && parser.type("0" + nationalNumberString, metadata: territory, leadingZero: false) != .unknown {
                return territory.regionCode
            }
            if parser.type(nationalNumberString, metadata: territory, leadingZero: false) != .unknown {
                return territory.regionCode
            }
        }
        return nil
    }
}
