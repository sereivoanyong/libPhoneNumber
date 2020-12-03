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

public struct NumberFormat: Decodable {
    
    public let pattern: String?
    public let format: String?
    public let intlFormat: String?
    public let leadingDigitsPatterns: [String]?
    public var nationalPrefixFormattingRule: String?
    public let nationalPrefixOptionalWhenFormatting: Bool
    public let domesticCarrierCodeFormattingRule: String?
}
