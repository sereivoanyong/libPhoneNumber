//
//  PhoneNumberUtil.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation
#if os(iOS)
import CoreTelephony
#endif

final public class PhoneNumberUtil {
    // Manager objects
    let regexCache: RegexCache
    let metadataManager: MetadataManager

    // MARK: Lifecycle

    public init() {
        regexCache = RegexCache()
        metadataManager = MetadataManager()
    }

    // MARK: Parsing

    /// Parses a number string, used to create PhoneNumber objects. Throws.
    ///
    /// - Parameters:
    ///   - numberString: the raw number string.
    ///   - regionCode: ISO 639 compliant region code.
    ///   - ignoreType: Avoids number type checking for faster performance.
    /// - Returns: PhoneNumber object.
    public func parse(_ numberString: String, regionCode: String = PhoneNumberUtil.defaultRegionCode(), ignoreType: Bool = false) throws -> PhoneNumber {
        var numberStringWithPlus = numberString

        do {
            return try parseHelper(numberString, regionCode: regionCode, ignoreType: ignoreType)
        } catch {
            if numberStringWithPlus.first != "+" {
                numberStringWithPlus = "+" + numberStringWithPlus
            }
        }

        return try parseHelper(numberStringWithPlus, regionCode: regionCode, ignoreType: ignoreType)
    }
    
    // MARK: Checking
    
    /// Checks if a number string is a valid PhoneNumber object
    ///
    /// - Parameters:
    ///   - numberString: the raw number string.
    ///   - region: ISO 639 compliant region code.
    ///   - ignoreType: Avoids number type checking for faster performance.
    /// - Returns: Bool
    public func isValidPhoneNumber(_ numberString: String, regionCode: String = PhoneNumberUtil.defaultRegionCode(), ignoreType: Bool = false) -> Bool {
        return (try? parse(numberString, regionCode: regionCode, ignoreType: ignoreType)) != nil
    }

    // MARK: Formatting

    /// Formats a PhoneNumber object for dispaly.
    ///
    /// - parameter phoneNumber: PhoneNumber object.
    /// - parameter format: PhoneNumberFormat enum.
    /// - parameter withPrefix: Whether or not to include the prefix.
    ///
    /// - returns: Formatted representation of the PhoneNumber.
    public func format(_ phoneNumber: PhoneNumber, format: PhoneNumberFormat, withPrefix: Bool = true) -> String {
        if format == .e164 {
            let formattedNationalNumber = phoneNumber.adjustedNationalNumber()
            if !withPrefix {
                return formattedNationalNumber
            }
            return "+\(phoneNumber.countryCode)\(formattedNationalNumber)"
        } else {
            let regionMetadata = metadataManager.mainTerritoryByCountryCodes[phoneNumber.countryCode]
            let formattedNationalNumber = self.format(phoneNumber: phoneNumber, format: format, regionMetadata: regionMetadata)
            if format == .international, withPrefix {
                return "+\(phoneNumber.countryCode) \(formattedNationalNumber)"
            } else {
                return formattedNationalNumber
            }
        }
    }

    // MARK: Country and region code

    /// Get a list of all the countries in the metadata database
    ///
    /// - returns: An array of ISO 639 compliant region codes.
    public func allRegionCodes() -> [String] {
        return metadataManager.territories.map { $0.regionCode }
    }

    /// Get an array of ISO 639 compliant region codes corresponding to a given country code.
    ///
    /// - parameter countryCode: international country code (e.g 44 for the UK).
    ///
    /// - returns: optional array of ISO 639 compliant region codes.
    public func regionCodes(forCountryCode countryCode: Int32) -> [String]? {
        return metadataManager.territoriesByCountryCodes[countryCode]?.map { $0.regionCode }
    }

    /// Get an main ISO 639 compliant region code for a given country code.
    ///
    /// - parameter countryCode: international country code (e.g 1 for the US).
    ///
    /// - returns: ISO 639 compliant region code string.
    public func mainRegionCode(forCountryCode countryCode: Int32) -> String? {
        return metadataManager.mainTerritoryByCountryCodes[countryCode]?.regionCode
    }

    /// Get an international country code for an ISO 639 compliant region code
    ///
    /// - parameter regionCode: ISO 639 compliant region code.
    ///
    /// - returns: international country code (e.g. 33 for France).
    public func countryCode(forRegionCode regionCode: String) -> Int32? {
        return metadataManager.territoriesByRegionCodes[regionCode]?.countryCode
    }

    /// Get leading digits for an ISO 639 compliant region code.
    ///
    /// - parameter regionCode: ISO 639 compliant region code.
    ///
    /// - returns: leading digits (e.g. 876 for Jamaica).
    public func leadingDigits(forRegionCode regionCode: String) -> String? {
        return metadataManager.territoriesByRegionCodes[regionCode]?.leadingDigits
    }

    /// Determine the region code of a given phone number.
    ///
    /// - parameter phoneNumber: PhoneNumber object
    ///
    /// - returns: Region code, eg "US", or nil if the region cannot be determined.
    public func regionCode(of phoneNumber: PhoneNumber) -> String? {
        return regionCodeHelper(nationalNumber: phoneNumber.nationalNumber, countryCode: phoneNumber.countryCode, leadingZero: phoneNumber.italianLeadingZero)
    }

    /// Get an example phone number for an ISO 639 compliant region code.
    ///
    /// - parameter regionCode: ISO 639 compliant region code.
    /// - parameter type: The `PhoneNumberType` desired. default: `.mobile`
    ///
    /// - returns: An example phone number
    public func exampleNumber(forRegionCode regionCode: String, ofType type: PhoneNumberType = .mobile) -> PhoneNumber? {
        let metadata = self.metadata(forRegionCode: regionCode)
        let example: String?
        switch type {
        case .fixedLine: example = metadata?.fixedLine?.exampleNumber
        case .mobile: example = metadata?.mobile?.exampleNumber
        case .fixedLineOrMobile: example = metadata?.mobile?.exampleNumber
        case .pager: example = metadata?.pager?.exampleNumber
        case .personalNumber: example = metadata?.personalNumber?.exampleNumber
        case .premiumRate: example = metadata?.premiumRate?.exampleNumber
        case .sharedCost: example = metadata?.sharedCost?.exampleNumber
        case .tollFree: example = metadata?.tollFree?.exampleNumber
        case .voicemail: example = metadata?.voicemail?.exampleNumber
        case .voip: example = metadata?.voip?.exampleNumber
        case .uan: example = metadata?.uan?.exampleNumber
        case .unknown: return nil
        }
        do {
            return try example.flatMap { try parse($0, regionCode: regionCode, ignoreType: false) }
        } catch {
            print("[PhoneNumberUtil] Failed to parse example number for \(regionCode) region")
            return nil
        }
    }

    /// Get a formatted example phone number for an ISO 639 compliant region code.
    ///
    /// - parameter regionCode: ISO 639 compliant region code.
    /// - parameter type: `PhoneNumberType` desired. default: `.mobile`
    /// - parameter format: `PhoneNumberFormat` to use for formatting. default: `.international`
    /// - parameter withPrefix: Whether or not to include the prefix.
    ///
    /// - returns: A formatted example phone number
    public func formattedExampleNumber(
        forRegionCode regionCode: String,
        ofType type: PhoneNumberType = .mobile,
        format: PhoneNumberFormat = .international,
        withPrefix: Bool = true
    ) -> String? {
        return exampleNumber(forRegionCode: regionCode, ofType: type)
            .flatMap { self.format($0, format: format, withPrefix: withPrefix) }
    }

    /// Get the MetadataTerritory objects for an ISO 639 compliant region code.
    ///
    /// - parameter regionCode: ISO 639 compliant region code (e.g "GB" for the UK).
    ///
    /// - returns: A MetadataTerritory object, or nil if no metadata was found for the country code
    public func metadata(forRegionCode regionCode: String) -> PhoneMetadata? {
        return metadataManager.territoriesByRegionCodes[regionCode]
    }

    /// Get an array of MetadataTerritory objects corresponding to a given country code.
    ///
    /// - parameter countryCode: international country code (e.g 44 for the UK)
    public func metadata(forCountryCode countryCode: Int32) -> [PhoneMetadata]? {
        return metadataManager.territoriesByCountryCodes[countryCode]
    }

    /// Get an array of possible phone number lengths for the country, as specified by the parameters.
    ///
    /// - parameter country: ISO 639 compliant region code.
    /// - parameter phoneNumberType: PhoneNumberType enum.
    /// - parameter lengthType: PossibleLengthType enum.
    ///
    /// - returns: Array of possible lengths for the country. May be empty.
    public func possiblePhoneNumberLengths(regionCode: String, phoneNumberType: PhoneNumberType, lengthType: PhoneNumberPossibleLengthType) -> [Int] {
        guard let territory = metadataManager.territoriesByRegionCodes[regionCode] else { return [] }

        let possibleLengths = possiblePhoneNumberLengths(forTerritory: territory, phoneNumberType: phoneNumberType)

        switch lengthType {
        case .national:     return possibleLengths?.national.flatMap { parsePossibleLengths($0) } ?? []
        case .localOnly:    return possibleLengths?.localOnly.flatMap { parsePossibleLengths($0) } ?? []
        }
    }

    private func possiblePhoneNumberLengths(forTerritory territory: PhoneMetadata, phoneNumberType: PhoneNumberType) -> PhoneNumberPossibleLengths? {
        switch phoneNumberType {
        case .fixedLine:        return territory.fixedLine?.possibleLengths
        case .mobile:           return territory.mobile?.possibleLengths
        case .pager:            return territory.pager?.possibleLengths
        case .personalNumber:   return territory.personalNumber?.possibleLengths
        case .premiumRate:      return territory.premiumRate?.possibleLengths
        case .sharedCost:       return territory.sharedCost?.possibleLengths
        case .tollFree:         return territory.tollFree?.possibleLengths
        case .voicemail:        return territory.voicemail?.possibleLengths
        case .voip:             return territory.voip?.possibleLengths
        case .uan:              return territory.uan?.possibleLengths
        case .fixedLineOrMobile:    return nil // caller needs to combine results for .fixedLine and .mobile
        case .unknown:          return nil
        }
    }

    /// Parse lengths string into array of Int, e.g. "6,[8-10]" becomes [6,8,9,10]
    private func parsePossibleLengths(_ lengths: String) -> [Int] {
        let components = lengths.components(separatedBy: ",")
        let results = components.reduce([Int](), { result, component in
            let newComponents = parseLengthComponent(component)
            return result + newComponents
        })

        return results
    }

    /// Parses numbers and ranges into array of Int
    private func parseLengthComponent(_ component: String) -> [Int] {
        if let int = Int(component) {
            return [int]
        } else {
            let trimmedComponent = component.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            let rangeLimits = trimmedComponent.components(separatedBy: "-").compactMap { Int($0) }

            guard rangeLimits.count == 2,
                let rangeStart = rangeLimits.first,
                let rangeEnd = rangeLimits.last
                else { return [] }

            return Array(rangeStart...rangeEnd)
        }
    }

    // MARK: Class functions

    /// Get a user's default region code
    ///
    /// - returns: A computed value for the user's current region - based on the iPhone's carrier and if not available, the device region.
    public static func defaultRegionCode() -> String {
#if os(iOS) && !targetEnvironment(simulator) && !targetEnvironment(macCatalyst)
        let networkInfo = CTTelephonyNetworkInfo()
        var carrier: CTCarrier?
        if #available(iOS 12.0, *) {
            carrier = networkInfo.serviceSubscriberCellularProviders?.values.first
        } else {
            carrier = networkInfo.subscriberCellularProvider
        }

        if let isoCountryCode = carrier?.isoCountryCode {
            return isoCountryCode.uppercased()
        }
#endif
        return Locale.current.regionCode ?? PhoneNumberConstants.defaultRegionCode
    }
}

// MARK: - Manager for parsing flow.
extension PhoneNumberUtil {
    /**
     Parse a string into a phone number object with a custom region. Can throw.
     - Parameter numberString: String to be parsed to phone number struct.
     - Parameter regionCode: ISO 639 compliant region code.
     - parameter ignoreType:   Avoids number type checking for faster performance.
     */
    func parseHelper(_ numberString: String, regionCode: String, ignoreType: Bool) throws -> PhoneNumber {
        assert(regionCode == regionCode.uppercased())
        // Extract number (2)

        var nationalNumber = numberString

        let match = try regexCache.phoneDataDetectorMatch(numberString)
        let matchedNumber = nationalNumber.substring(with: match.range)
        // Replace Arabic and Persian numerals and let the rest unchanged
        nationalNumber = regexCache.stringByReplacingOccurrences(matchedNumber, map: PhoneNumberPatterns.allNormalizationMappings, keepUnmapped: true)

        // Strip and extract extension (3)
        var numberExtension: String?
        if let rawExtension = stripExtension(&nationalNumber) {
            numberExtension = normalizePhoneNumber(rawExtension)
        }
        // Country code parse (4)
        guard var regionMetadata = metadataManager.territoriesByRegionCodes[regionCode] else {
            throw PhoneNumberError.invalidCountryCode
        }
        var countryCode: Int32
        do {
            countryCode = try extractCountryCode(nationalNumber, nationalNumber: &nationalNumber, metadata: regionMetadata)
        } catch {
            let plusRemovedNumberString = regexCache.replaceStringByRegex(PhoneNumberPatterns.leadingPlusCharsPattern, string: nationalNumber)
            countryCode = try extractCountryCode(plusRemovedNumberString, nationalNumber: &nationalNumber, metadata: regionMetadata)
        }
        if countryCode == 0 {
            countryCode = regionMetadata.countryCode
        }
        // Normalized number (5)
        let normalizedNationalNumber = normalizePhoneNumber(nationalNumber)
        nationalNumber = normalizedNationalNumber

        // If country code is not default, grab correct metadata (6)
        if countryCode != regionMetadata.countryCode, let countryMetadata = metadataManager.mainTerritoryByCountryCodes[countryCode] {
            regionMetadata = countryMetadata
        }
        // National Prefix Strip (7)
        stripNationalPrefix(&nationalNumber, metadata: regionMetadata)

        // Test number against general number description for correct metadata (8)
        if let generalNumberDesc = regionMetadata.generalDesc, !regexCache.hasValue(generalNumberDesc.nationalNumberPattern) || !isNumberMatchingDesc(nationalNumber, numberDesc: generalNumberDesc) {
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
            if let regionCode = self.regionCodeHelper(nationalNumber: finalNationalNumber, countryCode: countryCode, leadingZero: leadingZero), let foundMetadata = metadataManager.territoriesByRegionCodes[regionCode] {
                regionMetadata = foundMetadata
            }
            type = self.type(String(nationalNumber), metadata: regionMetadata, leadingZero: leadingZero)
            if type == .unknown {
                throw PhoneNumberError.unknownType
            }
        }

        return PhoneNumber(countryCode: countryCode, nationalNumber: finalNationalNumber, extension: numberExtension, italianLeadingZero: leadingZero, numberOfLeadingZeros: 0, rawInput: numberString, countryCodeSource: .unspecified, preferredDomesticCarrierCode: nil, type: type)
    }

    // Parse task

    /// Get correct ISO 639 compliant region code for a number.
    ///
    /// - Parameters:
    ///   - nationalNumber: national number.
    ///   - countryCode: country code.
    ///   - leadingZero: whether or not the number has a leading zero.
    /// - Returns: ISO 639 compliant region code.
    func regionCodeHelper(nationalNumber: UInt64, countryCode: Int32, leadingZero: Bool) -> String? {
        guard let territories = metadataManager.territoriesByCountryCodes[countryCode] else { return nil }

        if territories.count == 1 {
            return territories[0].regionCode
        }

        let nationalNumberString = String(nationalNumber)
        for territory in territories {
            if let leadingDigits = territory.leadingDigits {
                if regexCache.matchesAtStart(leadingDigits, string: nationalNumberString) {
                    return territory.regionCode
                }
            }
            if leadingZero && type("0" + nationalNumberString, metadata: territory, leadingZero: false) != .unknown {
                return territory.regionCode
            }
            if type(nationalNumberString, metadata: territory, leadingZero: false) != .unknown {
                return territory.regionCode
            }
        }
        return nil
    }
}


// MARK: - Parser. Contains parsing functions.
extension PhoneNumberUtil {
    // MARK: Normalizations

    /**
     Normalize a phone number (e.g +33 612-345-678 to 33612345678).
     - Parameter number: Phone number string.
     - Returns: Normalized phone number string.
     */
    func normalizePhoneNumber(_ number: String) -> String {
        let normalizationMappings = PhoneNumberPatterns.allNormalizationMappings
        return regexCache.stringByReplacingOccurrences(number, map: normalizationMappings)
    }

    // MARK: Extractions

    /**
     Extract country code (e.g +33 612-345-678 to 33).
     - Parameter number: Number string.
     - Parameter nationalNumber: National number string - inout.
     - Parameter metadata: Metadata territory object.
     - Returns: Country code is UInt64.
     */
    func extractCountryCode(_ number: String, nationalNumber: inout String, metadata: PhoneMetadata) throws -> Int32 {
        var fullNumber = number
        guard let possibleCountryIddPrefix = metadata.internationalPrefix else {
            return 0
        }
        let countryCodeSource = stripInternationalPrefixAndNormalize(&fullNumber, possibleIddPrefix: possibleCountryIddPrefix)
        if countryCodeSource != .fromDefaultCountry {
            if fullNumber.count <= PhoneNumberConstants.minLengthForNSN {
                throw PhoneNumberError.tooShort
            }
            if let potentialCountryCode = extractPotentialCountryCode(fullNumber, nationalNumber: &nationalNumber), potentialCountryCode != 0 {
                return potentialCountryCode
            } else {
                return 0
            }
        } else {
            let defaultCountryCode = String(metadata.countryCode)
            if fullNumber.hasPrefix(defaultCountryCode) {
                var potentialNationalNumber = (fullNumber as NSString).substring(from: defaultCountryCode.utf16.count)
                guard let validNumberPattern = metadata.generalDesc?.nationalNumberPattern, let possibleNumberPattern = metadata.generalDesc?.possibleNumberPattern else {
                    return 0
                }
                stripNationalPrefix(&potentialNationalNumber, metadata: metadata)
                let potentialNationalNumberStr = potentialNationalNumber
                if (!regexCache.matchesEntirely(validNumberPattern, string: fullNumber) && regexCache.matchesEntirely(validNumberPattern, string: potentialNationalNumberStr)) || !regexCache.testStringLengthAgainstPattern(possibleNumberPattern, string: fullNumber) {
                    nationalNumber = potentialNationalNumberStr
                    if let countryCode = Int32(defaultCountryCode) {
                        return countryCode
                    }
                }
            }
        }
        return 0
    }

    /**
     Extract potential country code (e.g +33 612-345-678 to 33).
     - Parameter fullNumber: Full number string.
     - Parameter nationalNumber: National number string.
     - Returns: Country code is UInt64. Optional.
     */
    func extractPotentialCountryCode(_ fullNumber: String, nationalNumber: inout String) -> Int32? {
        let fullNumber = fullNumber as NSString
        if fullNumber.length == 0 || fullNumber.substring(to: 1) == "0" {
            return 0
        }
        let numberLength = fullNumber.length
        let maxCountryCode = PhoneNumberConstants.maxLengthCountryCode
        var startPosition = 0
        if fullNumber.hasPrefix("+") {
            if fullNumber.length == 1 {
                return 0
            }
            startPosition = 1
        }
        for i in 1...numberLength {
            if i > maxCountryCode {
                break
            }
            let stringRange = NSRange(location: startPosition, length: i)
            let subNumber = fullNumber.substring(with: stringRange)
            if let potentialCountryCode = Int32(subNumber), metadataManager.territoriesByCountryCodes[potentialCountryCode] != nil {
                nationalNumber = fullNumber.substring(from: i)
                return potentialCountryCode
            }
        }
        return 0
    }

    // MARK: Validations

    func type(_ nationalNumber: String, metadata: PhoneMetadata, leadingZero: Bool) -> PhoneNumberType {
        if leadingZero {
            let type = self.type("0" + nationalNumber, metadata: metadata, leadingZero: false)
            if type != .unknown {
                return type
            }
        }

        guard let generalNumberDesc = metadata.generalDesc else {
            return .unknown
        }
        if !regexCache.hasValue(generalNumberDesc.nationalNumberPattern) || !isNumberMatchingDesc(nationalNumber, numberDesc: generalNumberDesc) {
            return .unknown
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.pager) {
            return .pager
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.premiumRate) {
            return .premiumRate
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.tollFree) {
            return .tollFree
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.sharedCost) {
            return .sharedCost
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.voip) {
            return .voip
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.personalNumber) {
            return .personalNumber
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.uan) {
            return .uan
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.voicemail) {
            return .voicemail
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.fixedLine) {
            if metadata.fixedLine?.nationalNumberPattern == metadata.mobile?.nationalNumberPattern {
                return .fixedLineOrMobile
            } else if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.mobile) {
                return .fixedLineOrMobile
            } else {
                return .fixedLine
            }
        }
        if isNumberMatchingDesc(nationalNumber, numberDesc: metadata.mobile) {
            return .mobile
        }
        return .unknown
    }

    /**
     Checks if number matches description.
     - Parameter nationalNumber: National number string.
     - Parameter numberDesc:  PhoneNumberDesc of a given phone number type.
     - Returns: True or false.
     */
    func isNumberMatchingDesc(_ nationalNumber: String, numberDesc: PhoneNumberDesc?) -> Bool {
        return regexCache.matchesEntirely(numberDesc?.nationalNumberPattern, string: nationalNumber)
    }

    /**
     Checks and strips if prefix is international dialing pattern.
     - Parameter number: Number string.
     - Parameter iddPattern:  iddPattern for a given country.
     - Returns: True or false and modifies the number accordingly.
     */
    func parsePrefixAsIdd(_ number: inout String, iddPattern: String) -> Bool {
        if regexCache.stringPositionByRegex(iddPattern, string: number) == 0 {
            do {
                guard let matched = try regexCache.matchesByRegex(pattern: iddPattern, string: number).first else {
                    return false
                }
                let matchedString = number.substring(with: matched.range)
                let matchEnd = matchedString.count
                let remainString = (number as NSString).substring(from: matchEnd)
                let capturingDigitPatterns = try NSRegularExpression(pattern: PhoneNumberPatterns.capturingDigitPattern, options: NSRegularExpression.Options.caseInsensitive)
                if let firstMatch = capturingDigitPatterns.firstMatch(in: remainString, options: [], range: NSRange(location: 0, length: remainString.utf16.count)) {
                    let digitMatched = remainString.substring(with: firstMatch.range)
                    if !digitMatched.isEmpty {
                        let normalizedGroup = regexCache.stringByReplacingOccurrences(digitMatched, map: PhoneNumberPatterns.allNormalizationMappings)
                        if normalizedGroup == "0" {
                            return false
                        }
                    }
                }
                number = remainString
                return true
            } catch {
                return false
            }
        }
        return false
    }

    // MARK: Strip helpers

    /**
     Strip an extension (e.g +33 612-345-678 ext.89 to 89).
     - Parameter number: Number string.
     - Returns: Modified number without extension and optional extension as string.
     */
    func stripExtension(_ number: inout String) -> String? {
        do {
            let matches = try regexCache.matchesByRegex(pattern: PhoneNumberPatterns.extnPattern, string: number)
            if let match = matches.first {
                let adjustedRange = NSRange(location: match.range.location + 1, length: match.range.length - 1)
                let matchString = number.substring(with: adjustedRange)
                let stringRange = NSRange(location: 0, length: match.range.location)
                number = number.substring(with: stringRange)
                return matchString
            }
            return nil
        } catch {
            return nil
        }
    }

    /**
     Strip international prefix.
     - Parameter number: Number string.
     - Parameter possibleIddPrefix:  Possible idd prefix for a given country.
     - Returns: Modified normalized number without international prefix and a PNCountryCodeSource enumeration.
     */
    func stripInternationalPrefixAndNormalize(_ number: inout String, possibleIddPrefix: String?) -> PhoneNumber.CountryCodeSource {
        if regexCache.matchesAtStart(PhoneNumberPatterns.leadingPlusCharsPattern, string: number) {
            number = regexCache.replaceStringByRegex(PhoneNumberPatterns.leadingPlusCharsPattern, string: number)
            return .fromNumberWithPlusSign
        }
        number = normalizePhoneNumber(number)
        guard let possibleIddPrefix = possibleIddPrefix else {
            return .fromNumberWithoutPlusSign
        }
        let prefixResult = parsePrefixAsIdd(&number, iddPattern: possibleIddPrefix)
        if prefixResult {
            return .fromNumberWithIDD
        } else {
            return .fromDefaultCountry
        }
    }

    /**
     Strip national prefix.
     - Parameter number: Number string.
     - Parameter metadata:  Final country's metadata.
     - Returns: Modified number without national prefix.
     */
    func stripNationalPrefix(_ number: inout String, metadata: PhoneMetadata) {
        guard let possibleNationalPrefix = metadata.nationalPrefixForParsing else {
            return
        }
        let prefixPattern = String(format: "^(?:%@)", possibleNationalPrefix)
        do {
            let matches = try regexCache.matchesByRegex(pattern: prefixPattern, string: number)
            if let firstMatch = matches.first {
                let nationalNumberRule = metadata.generalDesc?.nationalNumberPattern
                let firstMatchString = number.substring(with: firstMatch.range)
                let numOfGroups = firstMatch.numberOfRanges - 1
                var transformedNumber: String = String()
                let firstRange = firstMatch.range(at: numOfGroups)
                let firstMatchStringWithGroup = (firstRange.location != NSNotFound && firstRange.location < number.count) ? number.substring(with: firstRange) : String()
                let firstMatchStringWithGroupHasValue = regexCache.hasValue(firstMatchStringWithGroup)
                if let transformRule = metadata.nationalPrefixTransformRule, firstMatchStringWithGroupHasValue {
                    transformedNumber = regexCache.replaceFirstStringByRegex(prefixPattern, string: number, templateString: transformRule)
                } else {
                    let index = number.index(number.startIndex, offsetBy: firstMatchString.count)
                    transformedNumber = String(number[index...])
                }
                if regexCache.hasValue(nationalNumberRule), regexCache.matchesEntirely(nationalNumberRule, string: number), self.regexCache.matchesEntirely(nationalNumberRule, string: transformedNumber) == false {
                    return
                }
                number = transformedNumber
                return
            }
        } catch {
            return
        }
    }
}

// MARK: - Formatter
extension PhoneNumberUtil {
    // MARK: Formatting functions

    /// Formats phone numbers for display
    ///
    /// - Parameters:
    ///   - phoneNumber: Phone number object.
    ///   - format: Format.
    ///   - regionMetadata: Region meta data.
    /// - Returns: Formatted Modified national number ready for display.
    func format(phoneNumber: PhoneNumber, format: PhoneNumberFormat, regionMetadata: PhoneMetadata?) -> String {
        var formattedNationalNumber = phoneNumber.adjustedNationalNumber()
        if let regionMetadata = regionMetadata {
            formattedNationalNumber = formatNationalNumber(formattedNationalNumber, regionMetadata: regionMetadata, format: format)
            if let formattedExtension = formatExtension(phoneNumber.extension, regionMetadata: regionMetadata) {
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
    func formatExtension(_ numberExtension: String?, regionMetadata: PhoneMetadata) -> String? {
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
    func formatNationalNumber(_ nationalNumber: String, regionMetadata: PhoneMetadata, format: PhoneNumberFormat) -> String {
        let formats = regionMetadata.numberFormats
        var selectedFormat: NumberFormat?
        for format in formats {
            if let leadingDigitPattern = format.leadingDigitsPatterns?.last {
                if regexCache.stringPositionByRegex(leadingDigitPattern, string: String(nationalNumber)) == 0 {
                    if regexCache.matchesEntirely(format.pattern, string: String(nationalNumber)) {
                        selectedFormat = format
                        break
                    }
                }
            } else {
                if regexCache.matchesEntirely(format.pattern, string: String(nationalNumber)) {
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
                prefixFormattingRule = regexCache.replaceStringByRegex(PhoneNumberPatterns.npPattern, string: nationalPrefixFormattingRule, template: nationalPrefix)
                prefixFormattingRule = regexCache.replaceStringByRegex(PhoneNumberPatterns.fgPattern, string: prefixFormattingRule, template: "\\$1")
            }
            if format == PhoneNumberFormat.national, regexCache.hasValue(prefixFormattingRule) {
                let replacePattern = regexCache.replaceFirstStringByRegex(PhoneNumberPatterns.firstGroupPattern, string: numberFormatRule, templateString: prefixFormattingRule)
                formattedNationalNumber = regexCache.replaceStringByRegex(pattern, string: nationalNumber, template: replacePattern)
            } else {
                formattedNationalNumber = regexCache.replaceStringByRegex(pattern, string: nationalNumber, template: numberFormatRule)
            }
            return formattedNationalNumber
        } else {
            return nationalNumber
        }
    }
}


#if canImport(UIKit)
extension PhoneNumberUtil {

    /// Configuration for the CountryCodePicker presented from PhoneNumberTextField if `withDefaultPickerUI` is `true`
    public enum CountryCodePicker {
        /// Common Country Codes are shown below the Current section in the CountryCodePicker by default
        public static var commonCountryCodes: [String] = []

        /// When the Picker is shown from the textfield it is presented modally
        public static var forceModalPresentation: Bool = false
    }
}
#endif
