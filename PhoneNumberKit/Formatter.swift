//
//  Formatter.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 03/11/2015.
//  Copyright © 2020 Roy Marmelstein. All rights reserved.
//

import Foundation

struct Formatter {
    let regexManager: RegexManager

    // MARK: Formatting functions

    /// Formats phone numbers for display
    ///
    /// - Parameters:
    ///   - phoneNumber: Phone number object.
    ///   - format: Format.
    ///   - regionMetadata: Region meta data.
    /// - Returns: Formatted Modified national number ready for display.
    func format(phoneNumber: PhoneNumber, format: PhoneNumberFormat, regionMetadata: MetadataTerritory?) -> String {
        var formattedNationalNumber = phoneNumber.adjustedNationalNumber()
        if let regionMetadata = regionMetadata {
            formattedNationalNumber = formatNationalNumber(formattedNationalNumber, regionMetadata: regionMetadata, format: format)
            if let formattedExtension = formatExtension(phoneNumber.numberExtension, regionMetadata: regionMetadata) {
                formattedNationalNumber = formattedNationalNumber + formattedExtension
            }
        }
        return formattedNationalNumber
    }

    /// Formats extension for display
    ///
    /// - Parameters:
    ///   - numberExtension: Number extension string.
    ///   - regionMetadata: Region meta data.
    /// - Returns: Modified number extension with either a preferred extension prefix or the default one.
    func formatExtension(_ numberExtension: String?, regionMetadata: MetadataTerritory) -> String? {
        if let extns = numberExtension {
            if let preferredExtnPrefix = regionMetadata.preferredExtnPrefix {
                return "\(preferredExtnPrefix)\(extns)"
            } else {
                return "\(PhoneNumberConstants.defaultExtnPrefix)\(extns)"
            }
        }
        return nil
    }

    /// Formats national number for display
    ///
    /// - Parameters:
    ///   - nationalNumber: National number string.
    ///   - regionMetadata: Region meta data.
    ///   - format: Format.
    /// - Returns: Modified nationalNumber for display.
    func formatNationalNumber(_ nationalNumber: String, regionMetadata: MetadataTerritory, format: PhoneNumberFormat) -> String {
        let formats = regionMetadata.numberFormats
        var selectedFormat: MetadataPhoneNumberFormat?
        for format in formats {
            if let leadingDigitPattern = format.leadingDigitsPatterns?.last {
                if regexManager.stringPositionByRegex(leadingDigitPattern, string: String(nationalNumber)) == 0 {
                    if regexManager.matchesEntirely(format.pattern, string: String(nationalNumber)) {
                        selectedFormat = format
                        break
                    }
                }
            } else {
                if regexManager.matchesEntirely(format.pattern, string: String(nationalNumber)) {
                    selectedFormat = format
                    break
                }
            }
        }
        if let formatPattern = selectedFormat {
            guard let numberFormatRule = (format == PhoneNumberFormat.international && formatPattern.intlFormat != nil) ? formatPattern.intlFormat : formatPattern.format, let pattern = formatPattern.pattern else {
                return nationalNumber
            }
            var formattedNationalNumber = String()
            var prefixFormattingRule = String()
            if let nationalPrefixFormattingRule = formatPattern.nationalPrefixFormattingRule, let nationalPrefix = regionMetadata.nationalPrefix {
                prefixFormattingRule = regexManager.replaceStringByRegex(PhoneNumberPatterns.npPattern, string: nationalPrefixFormattingRule, template: nationalPrefix)
                prefixFormattingRule = regexManager.replaceStringByRegex(PhoneNumberPatterns.fgPattern, string: prefixFormattingRule, template: "\\$1")
            }
            if format == PhoneNumberFormat.national, regexManager.hasValue(prefixFormattingRule) {
                let replacePattern = regexManager.replaceFirstStringByRegex(PhoneNumberPatterns.firstGroupPattern, string: numberFormatRule, templateString: prefixFormattingRule)
                formattedNationalNumber = regexManager.replaceStringByRegex(pattern, string: nationalNumber, template: replacePattern)
            } else {
                formattedNationalNumber = regexManager.replaceStringByRegex(pattern, string: nationalNumber, template: numberFormatRule)
            }
            return formattedNationalNumber
        } else {
            return nationalNumber
        }
    }
}

public extension PhoneNumber {
    /**
     Adjust national number for display by adding leading zero if needed. Used for basic formatting functions.
     - Returns: A string representing the adjusted national number.
     */
    func adjustedNationalNumber() -> String {
        if leadingZero {
            return "0" + String(nationalNumber)
        } else {
            return String(nationalNumber)
        }
    }
}
