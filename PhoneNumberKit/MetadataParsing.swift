//
//  MetadataParsing.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 2019-02-10.
//  Copyright © 2019 Roy Marmelstein. All rights reserved.
//

import Foundation

// MARK: - MetadataTerritory

public extension MetadataTerritory {
    private enum CodingKeys: String, CodingKey {
        case codeID = "id"
        case countryCode
        case internationalPrefix
        case mainCountryForCode
        case nationalPrefix
        case nationalPrefixFormattingRule
        case nationalPrefixForParsing
        case nationalPrefixTransformRule
        case preferredExtnPrefix
        case emergency
        case fixedLine
        case generalDesc
        case mobile
        case pager
        case personalNumber
        case premiumRate
        case sharedCost
        case tollFree
        case voicemail
        case voip
        case uan
        case numberFormats = "numberFormat"
        case leadingDigits
        case availableFormats
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Custom parsing logic
        codeID = try container.decode(String.self, forKey: .codeID)
        countryCode = try UInt64(container.decode(String.self, forKey: .countryCode))!
        mainCountryForCode = try container.decodeIfPresent(String.self, forKey: .mainCountryForCode).flatMap(Bool.init) ?? false
        let possibleNationalPrefix = try container.decodeIfPresent(String.self, forKey: .nationalPrefix)
        nationalPrefix = possibleNationalPrefix
        nationalPrefixForParsing = try container.decodeIfPresent(String.self, forKey: .nationalPrefixForParsing) ?? possibleNationalPrefix
        nationalPrefixFormattingRule = try container.decodeIfPresent(String.self, forKey: .nationalPrefixFormattingRule)
        let availableFormats = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .availableFormats)
        let temporaryFormatList = availableFormats.decodeArrayOrObject(forKey: .numberFormats) as [MetadataPhoneNumberFormat]
        numberFormats = temporaryFormatList.withDefaultNationalPrefixFormattingRule(nationalPrefixFormattingRule)

        // Default parsing logic
        internationalPrefix = try container.decodeIfPresent(String.self, forKey: .internationalPrefix)
        nationalPrefixTransformRule = try container.decodeIfPresent(String.self, forKey: .nationalPrefixTransformRule)
        preferredExtnPrefix = try container.decodeIfPresent(String.self, forKey: .preferredExtnPrefix)
        emergency = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .emergency)
        fixedLine = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .fixedLine)
        generalDesc = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .generalDesc)
        mobile = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .mobile)
        pager = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .pager)
        personalNumber = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .personalNumber)
        premiumRate = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .premiumRate)
        sharedCost = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .sharedCost)
        tollFree = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .tollFree)
        voicemail = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .voicemail)
        voip = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .voip)
        uan = try container.decodeIfPresent(MetadataPhoneNumberDesc.self, forKey: .uan)
        leadingDigits = try container.decodeIfPresent(String.self, forKey: .leadingDigits)
    }
}

// MARK: - MetadataPhoneNumberFormat

public extension MetadataPhoneNumberFormat {
    private enum CodingKeys: String, CodingKey {
        case pattern
        case format
        case intlFormat
        case leadingDigitsPatterns = "leadingDigits"
        case nationalPrefixFormattingRule
        case nationalPrefixOptionalWhenFormatting
        case domesticCarrierCodeFormattingRule = "carrierCodeFormattingRule"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Custom parsing logic
        leadingDigitsPatterns = container.decodeArrayOrObject(forKey: .leadingDigitsPatterns)
        nationalPrefixOptionalWhenFormatting = try container.decodeIfPresent(String.self, forKey: .nationalPrefixOptionalWhenFormatting).flatMap(Bool.init)

        // Default parsing logic
        pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        intlFormat = try container.decodeIfPresent(String.self, forKey: .intlFormat)
        nationalPrefixFormattingRule = try container.decodeIfPresent(String.self, forKey: .nationalPrefixFormattingRule)
        domesticCarrierCodeFormattingRule = try container.decodeIfPresent(String.self, forKey: .domesticCarrierCodeFormattingRule)
    }
}

// MARK: - PhoneNumberMetadata

extension PhoneNumberMetadata {
    private enum CodingKeys: String, CodingKey {
        case phoneNumberMetadata
        case territories
        case territory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metadataObject = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .phoneNumberMetadata)
        let territoryObject = try metadataObject.nestedContainer(keyedBy: CodingKeys.self, forKey: .territories)
        territories = try territoryObject.decode([MetadataTerritory].self, forKey: .territory)
    }
}

// MARK: - Parsing helpers

private extension KeyedDecodingContainer {

    /// Decodes either a single object or an array into an array. Returns an empty array if empty.
    ///
    /// - Parameter key: Coding key to decode
    func decodeArrayOrObject<T: Decodable>(forKey key: Key) -> [T] {
        if let array = try? decode([T].self, forKey: key) {
            return array
        }
        if let object = try? decode(T.self, forKey: key) {
            return [object]
        }
        return []
    }
}

private extension Collection where Element == MetadataPhoneNumberFormat {
    func withDefaultNationalPrefixFormattingRule(_ nationalPrefixFormattingRule: String?) -> [Element] {
        return self.map { format -> MetadataPhoneNumberFormat in
            var modifiedFormat = format
            if modifiedFormat.nationalPrefixFormattingRule == nil {
                modifiedFormat.nationalPrefixFormattingRule = nationalPrefixFormattingRule
            }
            return modifiedFormat
        }
    }
}
