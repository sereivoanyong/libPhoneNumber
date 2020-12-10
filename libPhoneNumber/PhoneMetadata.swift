//
//  PhoneMetadata.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

public struct PhoneMetadata: Decodable {
  
  public let regionCode: String
  public let countryCode: Int32
  public let internationalPrefix: String?
  public let mainCountryForCode: Bool
  public let nationalPrefix: String?
  public let nationalPrefixFormattingRule: String?
  public let nationalPrefixForParsing: String?
  public let nationalPrefixTransformRule: String?
  public let sameMobileAndFixedLinePattern: Bool
  public let intlNumberFormats: [NumberFormat]
  
  public let preferredExtnPrefix: String?
  public let emergency: PhoneNumberDesc?
  public let fixedLine: PhoneNumberDesc?
  public let generalDesc: PhoneNumberDesc?
  public let mobile: PhoneNumberDesc?
  public let pager: PhoneNumberDesc?
  public let personalNumber: PhoneNumberDesc?
  public let premiumRate: PhoneNumberDesc?
  public let sharedCost: PhoneNumberDesc?
  public let tollFree: PhoneNumberDesc?
  public let voicemail: PhoneNumberDesc?
  public let voip: PhoneNumberDesc?
  public let uan: PhoneNumberDesc?
  public let numberFormats: [NumberFormat]
  public let leadingDigits: String?
  public let mobileNumberPortableRegion: Bool
  
  
  private enum CodingKeys: String, CodingKey {
    
    case regionCode = "id"
    case countryCode
    case internationalPrefix
    case mainCountryForCode
    case nationalPrefix
    case nationalPrefixFormattingRule
    case nationalPrefixForParsing
    case nationalPrefixTransformRule
    case sameMobileAndFixedLinePattern
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
    case mobileNumberPortableRegion
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    // Custom parsing logic
    regionCode = try container.decode(String.self, forKey: .regionCode)
    countryCode = try Int32(container.decode(String.self, forKey: .countryCode))!
    mainCountryForCode = try container.decodeStringBoolIfPresent(forKey: .mainCountryForCode) ?? false
    let possibleNationalPrefix = try container.decodeIfPresent(String.self, forKey: .nationalPrefix)
    nationalPrefix = possibleNationalPrefix
    nationalPrefixForParsing = try container.decodeIfPresent(String.self, forKey: .nationalPrefixForParsing) ?? possibleNationalPrefix
    nationalPrefixFormattingRule = try container.decodeIfPresent(String.self, forKey: .nationalPrefixFormattingRule)
    if container.allKeys.contains(.availableFormats) {
      let availableFormats = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .availableFormats)
      let temporaryFormatList = availableFormats.decodeArrayOrObject(forKey: .numberFormats) as [NumberFormat]
      numberFormats = temporaryFormatList.withDefaultNationalPrefixFormattingRule(nationalPrefixFormattingRule)
      intlNumberFormats = temporaryFormatList.withDefaultNationalPrefixFormattingRule(nationalPrefixFormattingRule)
    } else {
      numberFormats = []
      intlNumberFormats = []
    }
    
    // Default parsing logic
    internationalPrefix = try container.decodeIfPresent(String.self, forKey: .internationalPrefix)
    nationalPrefixTransformRule = try container.decodeIfPresent(String.self, forKey: .nationalPrefixTransformRule)
    sameMobileAndFixedLinePattern = try container.decodeStringBoolIfPresent(forKey: .mainCountryForCode) ?? false
    preferredExtnPrefix = try container.decodeIfPresent(String.self, forKey: .preferredExtnPrefix)
    emergency = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .emergency)
    fixedLine = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .fixedLine)
    generalDesc = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .generalDesc)
    mobile = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .mobile)
    pager = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .pager)
    personalNumber = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .personalNumber)
    premiumRate = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .premiumRate)
    sharedCost = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .sharedCost)
    tollFree = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .tollFree)
    voicemail = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .voicemail)
    voip = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .voip)
    uan = try container.decodeIfPresent(PhoneNumberDesc.self, forKey: .uan)
    leadingDigits = try container.decodeIfPresent(String.self, forKey: .leadingDigits)
    mobileNumberPortableRegion = try container.decodeStringBoolIfPresent(forKey: .mobileNumberPortableRegion) ?? false
  }
}

extension Collection {
  
  fileprivate func withDefaultNationalPrefixFormattingRule(_ nationalPrefixFormattingRule: String?) -> [Element] where Element == NumberFormat {
    return map { format -> NumberFormat in
      var modifiedFormat = format
      if modifiedFormat.nationalPrefixFormattingRule == nil {
        modifiedFormat.nationalPrefixFormattingRule = nationalPrefixFormattingRule
      }
      return modifiedFormat
    }
  }
}

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
