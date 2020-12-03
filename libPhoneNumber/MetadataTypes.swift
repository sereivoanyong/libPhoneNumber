//
//  MetadataTypes.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

public struct PhoneNumberDesc: Decodable {
    
    public let exampleNumber: String?
    public let nationalNumberPattern: String?
    public let possibleNumberPattern: String?
    public let possibleLengths: MetadataPossibleLengths?
}

public struct MetadataPossibleLengths: Decodable {
    
    let national: String?
    let localOnly: String?
}

/**
 MetadataPhoneNumberFormat object
 - Parameter pattern: Regex pattern. Optional.
 - Parameter format: Formatting template. Optional.
 - Parameter intlFormat: International formatting template. Optional.

 - Parameter leadingDigitsPatterns: Leading digits regex pattern. Optional.
 - Parameter nationalPrefixFormattingRule: National prefix formatting rule. Optional.
 - Parameter nationalPrefixOptionalWhenFormatting: National prefix optional bool. Optional.
 - Parameter domesticCarrierCodeFormattingRule: Domestic carrier code formatting rule. Optional.
 */
public struct MetadataPhoneNumberFormat: Decodable {
    public let pattern: String?
    public let format: String?
    public let intlFormat: String?
    public let leadingDigitsPatterns: [String]?
    public var nationalPrefixFormattingRule: String?
    public let nationalPrefixOptionalWhenFormatting: Bool
    public let domesticCarrierCodeFormattingRule: String?
}
