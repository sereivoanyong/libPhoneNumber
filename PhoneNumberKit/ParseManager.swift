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
        var countryCode: UInt64
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
        if countryCode != regionMetadata.countryCode, let countryMetadata = metadataManager.mainTerritoryByCode[countryCode] {
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
            if let regionCode = getRegionCode(of: finalNationalNumber, countryCode: countryCode, leadingZero: leadingZero), let foundMetadata = metadataManager.territoriesByRegionCodes[regionCode] {
                regionMetadata = foundMetadata
            }
            type = parser.checkNumberType(String(nationalNumber), metadata: regionMetadata, leadingZero: leadingZero)
            if type == .unknown {
                throw PhoneNumberError.unknownType
            }
        }

        let phoneNumber = PhoneNumber(numberString: numberString, countryCode: countryCode, leadingZero: leadingZero, nationalNumber: finalNationalNumber, numberExtension: numberExtension, type: type, regionID: regionMetadata.codeID)
        return phoneNumber
    }

    // Parse task

    /**
     Fastest way to parse an array of phone numbers. Uses custom region code.
     - Parameter numberStrings: An array of raw number strings.
     - Parameter regionCode: ISO 639 compliant region code.
     - parameter ignoreType:   Avoids number type checking for faster performance.
     - Returns: An array of valid PhoneNumber objects.
     */
    func parseMultiple(_ numberStrings: [String], regionCode: String, ignoreType: Bool, shouldReturnFailedEmptyNumbers: Bool = false, testCallback: (() -> Void)? = nil) -> [PhoneNumber] {
        var multiParseArray = [PhoneNumber]()
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.phonenumberkit.multipleparse", qos: .default)
        for (index, numberString) in numberStrings.enumerated() {
            group.enter()
            queue.async(group: group) {
                do {
                    let phoneNumber = try parse(numberString, regionCode: regionCode, ignoreType: ignoreType)
                    multiParseArray.append(phoneNumber)
                } catch {
                    if shouldReturnFailedEmptyNumbers {
                        multiParseArray.append(PhoneNumber.notPhoneNumber())
                    }
                }
                group.leave()
            }
            if index == numberStrings.count / 2 {
                testCallback?()
            }
        }
        group.wait()
        return multiParseArray
    }

    /// Get correct ISO 639 compliant region code for a number.
    ///
    /// - Parameters:
    ///   - nationalNumber: national number.
    ///   - countryCode: country code.
    ///   - leadingZero: whether or not the number has a leading zero.
    /// - Returns: ISO 639 compliant region code.
    func getRegionCode(of nationalNumber: UInt64, countryCode: UInt64, leadingZero: Bool) -> String? {
        guard let regions = metadataManager.territoriesByCode[countryCode] else { return nil }

        if regions.count == 1 {
            return regions[0].codeID
        }

        let nationalNumberString = String(nationalNumber)
        for region in regions {
            if let leadingDigits = region.leadingDigits {
                if regexManager.matchesAtStart(leadingDigits, string: nationalNumberString) {
                    return region.codeID
                }
            }
            if leadingZero, parser.checkNumberType("0" + nationalNumberString, metadata: region) != .unknown {
                return region.codeID
            }
            if parser.checkNumberType(nationalNumberString, metadata: region) != .unknown {
                return region.codeID
            }
        }
        return nil
    }
}
