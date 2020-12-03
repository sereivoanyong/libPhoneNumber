//
//  NumberFormat.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

public struct NumberFormat: Decodable {
  
  public let pattern: String?
  public let format: String?
  public let intlFormat: String?
  public let leadingDigitsPatterns: [String]?
  public var nationalPrefixFormattingRule: String?
  public let nationalPrefixOptionalWhenFormatting: Bool
  public let domesticCarrierCodeFormattingRule: String?
  
  private enum CodingKeys: String, CodingKey {
    
    case pattern
    case format
    case intlFormat
    case leadingDigitsPatterns = "leadingDigits"
    case nationalPrefixFormattingRule
    case nationalPrefixOptionalWhenFormatting
    case domesticCarrierCodeFormattingRule = "carrierCodeFormattingRule"
  }
  
  public init(from decoder: Decoder) throws {
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
