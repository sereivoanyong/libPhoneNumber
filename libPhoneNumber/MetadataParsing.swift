//
//  MetadataParsing.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

// MARK: - MetadataPhoneNumberFormat

public extension NumberFormat {
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
        nationalPrefixOptionalWhenFormatting = try container.decodeStringBoolIfPresent(forKey: .nationalPrefixOptionalWhenFormatting) ?? false

        // Default parsing logic
        pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
        format = try container.decodeIfPresent(String.self, forKey: .format)
        intlFormat = try container.decodeIfPresent(String.self, forKey: .intlFormat)
        nationalPrefixFormattingRule = try container.decodeIfPresent(String.self, forKey: .nationalPrefixFormattingRule)
        domesticCarrierCodeFormattingRule = try container.decodeIfPresent(String.self, forKey: .domesticCarrierCodeFormattingRule)
    }
}

// MARK: - Parsing helpers

extension KeyedDecodingContainer {
  
    /// Decodes a string to a boolean. Returns false if empty.
    ///
    /// - Parameter key: Coding key to decode
    func decodeStringBoolIfPresent(forKey key: Key) throws -> Bool? {
        if let string = try decodeIfPresent(String.self, forKey: key) {
            switch string {
            case "true":  return true
            case "false": return false
            default:      return nil
            }
        }
        return nil
    }

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
