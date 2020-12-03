//
//  PartialFormatter.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 29/11/2015.
//  Copyright © 2020 Roy Marmelstein. All rights reserved.
//

import Foundation

/// Partial formatter
public final class PartialFormatter {
    private let phoneNumberKit: PhoneNumberKit

    let regexManager: RegexManager
    let metadataManager: MetadataManager
    let parser: PhoneNumberParser

    public init(phoneNumberKit: PhoneNumberKit, defaultRegionCode: String = PhoneNumberKit.defaultRegionCode(), withPrefix: Bool = true, maxDigits: Int? = nil) {
        self.phoneNumberKit = phoneNumberKit
        self.regexManager = phoneNumberKit.regexManager
        self.metadataManager = phoneNumberKit.metadataManager
        self.parser = phoneNumberKit.parseManager.parser
        self.defaultRegionCode = defaultRegionCode
        self.updateMetadataForDefaultRegion()
        self.withPrefix = withPrefix
        self.maxDigits = maxDigits
    }

    public var defaultRegionCode: String {
        didSet {
            self.updateMetadataForDefaultRegion()
        }
    }

    public var maxDigits: Int?

    func updateMetadataForDefaultRegion() {
        if let regionMetadata = metadataManager.territoriesByRegionCodes[defaultRegionCode] {
            defaultMetadata = metadataManager.mainTerritoryByCountryCodes[regionMetadata.countryCode]
        } else {
            defaultMetadata = nil
        }
        currentMetadata = defaultMetadata
    }

    var defaultMetadata: MetadataTerritory?
    var currentMetadata: MetadataTerritory?
    var prefixBeforeNationalNumber = String()
    var shouldAddSpaceAfterNationalPrefix = false
    var withPrefix = true

    // MARK: Status

    public var currentRegionCode: String {
        if phoneNumberKit.countryCode(forRegionCode: defaultRegionCode) != 1 {
            return currentMetadata?.regionCode ?? "US"
        } else {
            return currentMetadata?.countryCode == 1
                ? defaultRegionCode
                : currentMetadata?.regionCode ?? defaultRegionCode
        }
    }

    public func nationalNumber(from rawNumber: String) -> String {
        let iddFreeNumber = extractIDD(rawNumber)
        var nationalNumber = parser.normalizePhoneNumber(iddFreeNumber)
        if prefixBeforeNationalNumber.count > 0 {
            nationalNumber = extractCountryCallingCode(nationalNumber)
        }

        nationalNumber = extractNationalPrefix(nationalNumber)

        if let maxDigits = maxDigits {
            let extra = nationalNumber.count - maxDigits

            if extra > 0 {
                nationalNumber = String(nationalNumber.dropLast(extra))
            }
        }

        return nationalNumber
    }

    // MARK: Lifecycle

    /**
     Formats a partial string (for use in TextField)

     - parameter rawNumber: Unformatted phone number string

     - returns: Formatted phone number string.
     */
    public func formatPartial(_ rawNumber: String) -> String {
        // Always reset variables with each new raw number
        resetVariables()

        guard isValidRawNumber(rawNumber) else {
            return rawNumber
        }
        let split = splitNumberAndPausesOrWaits(rawNumber)
        
        var nationalNumber = self.nationalNumber(from: split.number)
        if let formats = availableFormats(nationalNumber) {
            if let formattedNumber = applyFormat(nationalNumber, formats: formats) {
                nationalNumber = formattedNumber
            } else {
                for format in formats {
                    if let template = createFormattingTemplate(format, rawNumber: nationalNumber) {
                        nationalNumber = applyFormattingTemplate(template, rawNumber: nationalNumber)
                        break
                    }
                }
            }
        }

        var finalNumber = String()
        if withPrefix && prefixBeforeNationalNumber.count > 0 {
            finalNumber.append(prefixBeforeNationalNumber)
        }
        if withPrefix && shouldAddSpaceAfterNationalPrefix && prefixBeforeNationalNumber.count > 0 && prefixBeforeNationalNumber.last != PhoneNumberConstants.separatorBeforeNationalNumber.first {
            finalNumber.append(PhoneNumberConstants.separatorBeforeNationalNumber)
        }
        if nationalNumber.count > 0 {
            finalNumber.append(nationalNumber)
        }
        if finalNumber.last == PhoneNumberConstants.separatorBeforeNationalNumber.first {
            finalNumber = String(finalNumber[..<finalNumber.index(before: finalNumber.endIndex)])
        }
        finalNumber.append(split.pausesOrWaits)
        return finalNumber
    }

    // MARK: Formatting Functions

    internal func resetVariables() {
        currentMetadata = defaultMetadata
        prefixBeforeNationalNumber = String()
        shouldAddSpaceAfterNationalPrefix = false
    }

    // MARK: Formatting Tests

    internal func isValidRawNumber(_ rawNumber: String) -> Bool {
        do {
            // In addition to validPhoneNumberPattern,
            // accept any sequence of digits and whitespace, prefixed or not by a plus sign
            let validPartialPattern = "[+＋]?(\\s*\\d)+\\s*$|\(PhoneNumberPatterns.validPhoneNumberPattern)"
            let validNumberMatches = try regexManager.matchesByRegex(pattern: validPartialPattern, string: rawNumber)
            let validStart = regexManager.stringPositionByRegex(PhoneNumberPatterns.validStartPattern, string: rawNumber)
            if validNumberMatches.count == 0 || validStart != 0 {
                return false
            }
        } catch {
            return false
        }
        return true
    }

    internal func isNanpaNumberWithNationalPrefix(_ rawNumber: String) -> Bool {
        guard currentMetadata?.countryCode == 1 && rawNumber.count > 1 else { return false }

        let firstCharacter = String(describing: rawNumber.first)
        let secondCharacter = String(describing: rawNumber[rawNumber.index(rawNumber.startIndex, offsetBy: 1)])
        return (firstCharacter == "1" && secondCharacter != "0" && secondCharacter != "1")
    }

    func isFormatEligible(_ format: MetadataPhoneNumberFormat) -> Bool {
        guard let phoneFormat = format.format else {
            return false
        }
        do {
            let validRegex = try regexManager.regex(pattern: PhoneNumberPatterns.eligibleAsYouTypePattern)
            if validRegex.firstMatch(in: phoneFormat, options: [], range: NSRange(location: 0, length: phoneFormat.count)) != nil {
                return true
            }
        } catch {}
        return false
    }

    // MARK: Formatting Extractions

    func extractIDD(_ rawNumber: String) -> String {
        var processedNumber = rawNumber
        do {
            if let internationalPrefix = currentMetadata?.internationalPrefix {
                let prefixPattern = String(format: PhoneNumberPatterns.iddPattern, arguments: [internationalPrefix])
                let matches = try regexManager.matchedStringByRegex(prefixPattern, string: rawNumber)
                if let m = matches.first {
                    let startCallingCode = m.count
                    let index = rawNumber.index(rawNumber.startIndex, offsetBy: startCallingCode)
                    processedNumber = String(rawNumber[index...])
                    prefixBeforeNationalNumber = String(rawNumber[..<index])
                }
            }
        } catch {
            return processedNumber
        }
        return processedNumber
    }

    func extractNationalPrefix(_ rawNumber: String) -> String {
        var processedNumber = rawNumber
        var startOfNationalNumber: Int = 0
        if isNanpaNumberWithNationalPrefix(rawNumber) {
            prefixBeforeNationalNumber.append("1 ")
        } else {
            do {
                if let nationalPrefix = currentMetadata?.nationalPrefixForParsing {
                    let nationalPrefixPattern = String(format: PhoneNumberPatterns.nationalPrefixParsingPattern, arguments: [nationalPrefix])
                    let matches = try regexManager.matchedStringByRegex(nationalPrefixPattern, string: rawNumber)
                    if let m = matches.first {
                        startOfNationalNumber = m.count
                    }
                }
            } catch {
                return processedNumber
            }
        }
        let index = rawNumber.index(rawNumber.startIndex, offsetBy: startOfNationalNumber)
        processedNumber = String(rawNumber[index...])
        prefixBeforeNationalNumber.append(String(rawNumber[..<index]))
        return processedNumber
    }

    func extractCountryCallingCode(_ rawNumber: String) -> String {
        var processedNumber = rawNumber
        if rawNumber.isEmpty {
            return rawNumber
        }
        var numberWithoutCountryCallingCode = String()
        if !prefixBeforeNationalNumber.isEmpty && prefixBeforeNationalNumber.first != "+" {
            prefixBeforeNationalNumber.append(PhoneNumberConstants.separatorBeforeNationalNumber)
        }
        if let potentialCountryCode = parser.extractPotentialCountryCode(rawNumber, nationalNumber: &numberWithoutCountryCallingCode), potentialCountryCode != 0 {
            processedNumber = numberWithoutCountryCallingCode
            currentMetadata = metadataManager.mainTerritoryByCountryCodes[potentialCountryCode]
            let potentialCountryCodeString = String(potentialCountryCode)
            prefixBeforeNationalNumber.append(potentialCountryCodeString)
            prefixBeforeNationalNumber.append(" ")
        } else if !withPrefix && prefixBeforeNationalNumber.isEmpty {
            let potentialCountryCodeString = String(describing: currentMetadata?.countryCode)
            prefixBeforeNationalNumber.append(potentialCountryCodeString)
            prefixBeforeNationalNumber.append(" ")
        }
        return processedNumber
    }
    
    func splitNumberAndPausesOrWaits(_ rawNumber: String) -> (number: String, pausesOrWaits: String) {
        if rawNumber.isEmpty {
            return (rawNumber, "")
        }
        
        let splitByComma = rawNumber.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
        let splitBySemiColon = rawNumber.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        
        if splitByComma[0].count != splitBySemiColon[0].count {
            let foundCommasFirst = splitByComma[0].count < splitBySemiColon[0].count
            
            if foundCommasFirst {
                return (String(splitByComma[0]), "," + splitByComma[1])
            }
            else {
                return (String(splitBySemiColon[0]), ";" + splitBySemiColon[1])
            }
        }
        return (rawNumber, "")
    }
    
    func availableFormats(_ rawNumber: String) -> [MetadataPhoneNumberFormat]? {
        var tempPossibleFormats = [MetadataPhoneNumberFormat]()
        var possibleFormats = [MetadataPhoneNumberFormat]()
        if let metadata = currentMetadata {
            let formatList = metadata.numberFormats
            for format in formatList {
                if isFormatEligible(format) {
                    tempPossibleFormats.append(format)
                    if let leadingDigitPattern = format.leadingDigitsPatterns?.last {
                        if regexManager.stringPositionByRegex(leadingDigitPattern, string: String(rawNumber)) == 0 {
                            possibleFormats.append(format)
                        }
                    } else {
                        if regexManager.matchesEntirely(format.pattern, string: String(rawNumber)) {
                            possibleFormats.append(format)
                        }
                    }
                }
            }
            if possibleFormats.count == 0 {
                possibleFormats.append(contentsOf: tempPossibleFormats)
            }
            return possibleFormats
        }
        return nil
    }

    func applyFormat(_ rawNumber: String, formats: [MetadataPhoneNumberFormat]) -> String? {
        for format in formats {
            if let pattern = format.pattern, let formatTemplate = format.format {
                let patternRegExp = String(format: PhoneNumberPatterns.formatPattern, arguments: [pattern])
                do {
                    let matches = try regexManager.matchesByRegex(pattern: patternRegExp, string: rawNumber)
                    if matches.count > 0 {
                        if let nationalPrefixFormattingRule = format.nationalPrefixFormattingRule {
                            let separatorRegex = try regexManager.regex(pattern: PhoneNumberPatterns.prefixSeparatorPattern)
                            let nationalPrefixMatches = separatorRegex.matches(in: nationalPrefixFormattingRule, options: [], range: NSRange(location: 0, length: nationalPrefixFormattingRule.count))
                            if nationalPrefixMatches.count > 0 {
                                shouldAddSpaceAfterNationalPrefix = true
                            }
                        }
                        let formattedNumber = regexManager.replaceStringByRegex(pattern, string: rawNumber, template: formatTemplate)
                        return formattedNumber
                    }
                } catch {}
            }
        }
        return nil
    }

    func createFormattingTemplate(_ format: MetadataPhoneNumberFormat, rawNumber: String) -> String? {
        guard var numberPattern = format.pattern, let numberFormat = format.format else {
            return nil
        }
        guard numberPattern.range(of: "|") == nil else {
            return nil
        }
        do {
            let characterClassRegex = try regexManager.regex(pattern: PhoneNumberPatterns.characterClassPattern)
            numberPattern = characterClassRegex.stringByReplacingMatches(in: numberPattern, options: [], range: NSRange(location: 0, length: numberPattern.utf16.count), withTemplate: "\\\\d")

            let standaloneDigitRegex = try regexManager.regex(pattern: PhoneNumberPatterns.standaloneDigitPattern)
            numberPattern = standaloneDigitRegex.stringByReplacingMatches(in: numberPattern, options: [], range: NSRange(location: 0, length: numberPattern.utf16.count), withTemplate: "\\\\d")

            if let tempTemplate = getFormattingTemplate(numberPattern, numberFormat: numberFormat, rawNumber: rawNumber) {
                if let nationalPrefixFormattingRule = format.nationalPrefixFormattingRule {
                    let separatorRegex = try regexManager.regex(pattern: PhoneNumberPatterns.prefixSeparatorPattern)
                    let nationalPrefixMatch = separatorRegex.firstMatch(in: nationalPrefixFormattingRule, options: [], range: NSRange(location: 0, length: nationalPrefixFormattingRule.count))
                    if nationalPrefixMatch != nil {
                        shouldAddSpaceAfterNationalPrefix = true
                    }
                }
                return tempTemplate
            }
        } catch {}
        return nil
    }

    func getFormattingTemplate(_ numberPattern: String, numberFormat: String, rawNumber: String) -> String? {
        do {
            let matches = try regexManager.matchedStringByRegex(numberPattern, string: PhoneNumberConstants.longPhoneNumber)
            if let match = matches.first {
                if match.count < rawNumber.count {
                    return nil
                }
                var template = regexManager.replaceStringByRegex(numberPattern, string: match, template: numberFormat)
                template = regexManager.replaceStringByRegex("9", string: template, template: PhoneNumberConstants.digitPlaceholder)
                return template
            }
        } catch {}
        return nil
    }

    func applyFormattingTemplate(_ template: String, rawNumber: String) -> String {
        var rebuiltString = String()
        var rebuiltIndex = 0
        for character in template {
            if character == PhoneNumberConstants.digitPlaceholder.first {
                if rebuiltIndex < rawNumber.count {
                    let nationalCharacterIndex = rawNumber.index(rawNumber.startIndex, offsetBy: rebuiltIndex)
                    rebuiltString.append(rawNumber[nationalCharacterIndex])
                    rebuiltIndex += 1
                }
            } else {
                if rebuiltIndex < rawNumber.count {
                    rebuiltString.append(character)
                }
            }
        }
        if rebuiltIndex < rawNumber.count {
            let nationalCharacterIndex = rawNumber.index(rawNumber.startIndex, offsetBy: rebuiltIndex)
            let remainingNationalNumber: String = String(rawNumber[nationalCharacterIndex...])
            rebuiltString.append(remainingNationalNumber)
        }
        rebuiltString = rebuiltString.trimmingCharacters(in: .whitespacesAndNewlines)

        return rebuiltString
    }
}
