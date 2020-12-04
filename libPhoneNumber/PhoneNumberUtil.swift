//
//  PhoneNumberUtil.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

/// Simple ASCII digits map used to populate ALPHA_PHONE_MAPPINGS and
/// ALL_PLUS_NUMBER_GROUPING_SYMBOLS.
private let kAsciiDigitMappings: [Character: Character] = ["0": "0", "1": "1", "2": "2", "3": "3", "4": "4", "5": "5", "6": "6", "7": "7", "8": "8", "9": "9"]

final public class PhoneNumberUtil {
  
  /// Flags to use when compiling regular expressions for phone numbers.
  static let regexOptions: NSRegularExpression.Options = [.caseInsensitive]
  /// The minimum and maximum length of the national significant number.
  private static let minimumLengthForNSN: Int = 2
  /// The ITU says the maximum length should be 15, but we have found longer numbers in Germany.
  static let maximumLengthForNSN: Int = 17
  /// The maximum length of the country calling code.
  static let maximumLengthForCountryCode: Int32 = 3
  // We don't allow input strings for parsing to be longer than 250 chars. This prevents malicious
  // input from overflowing the regular-expression engine.
  private static let maximumInputStringLength: Int = 250
  
  /// Region-code for the unknown region.
  private static let unknownRegionCode: String = "ZZ"
  
  private static let nanpaCountryCode: Int32 = 1
  
  /// The prefix that needs to be inserted in front of a Colombian landline number when dialed from
  /// a mobile phone in Colombia.
  private static let colombiaMobileToFixedLinePrefix: String = "3"
  
  /// Map of country calling codes that use a mobile token before the area code. One example of when
  /// this is relevant is when determining the length of the national destination code, which should
  /// be the length of the area code plus the length of the mobile token.
  private static let mobileTokenMappings: [Int32: String] = [:]
  
  /// Set of country codes that have geographically assigned mobile numbers (see GEO_MOBILE_COUNTRIES
  /// below) which are not based on *area codes*. For example, in China mobile numbers start with a
  /// carrier indicator, and beyond that are geographically assigned: this carrier indicator is not
  /// considered to be an area code.
  private static let geoMobileCountryCodesWithoutMobileAreaCodes: Set<Int32> = {
    var geoMobileCountryCodesWithoutMobileAreaCodes = Set<Int32>()
    geoMobileCountryCodesWithoutMobileAreaCodes.insert(86)  // China
    return geoMobileCountryCodesWithoutMobileAreaCodes
  }()

  /// Set of country calling codes that have geographically assigned mobile numbers. This may not be
  /// complete; we add calling codes case by case, as we find geographical mobile numbers or hear
  /// from user reports. Note that countries like the US, where we can't distinguish between
  /// fixed-line or mobile numbers, are not listed here, since we consider FIXED_LINE_OR_MOBILE to be
  /// a possibly geographically-related type anyway (like FIXED_LINE).
  private static let geoMobileCountryCodes: Set<Int32> = {
    var geoMobileCountryCodes = Set<Int32>()
    geoMobileCountryCodes.insert(52)  // Mexico
    geoMobileCountryCodes.insert(54)  // Argentina
    geoMobileCountryCodes.insert(55)  // Brazil
    geoMobileCountryCodes.insert(62)  // Indonesia: some prefixes only (fixed CMDA wireless)
    geoMobileCountryCodes.formUnion(geoMobileCountryCodesWithoutMobileAreaCodes)
    return geoMobileCountryCodes
  }()
  
  // 99
  /// The PLUS_SIGN signifies the international prefix.
  static let plusSign: Character = "+"
  
  private static let starSign: Character = "*"

  private static let rfc3966ExtnPrefix = ";ext="
  
  // 104
  private static let rfc3966Prefix = "tel:"
  
  private static let rfc3966PhoneContext = ";phone-context="
  
  private static let rfc3966ISDNSubaddress = ";isub="
  
  /// A map that contains characters that are essential when dialling. That means any of the
  /// characters in this map must not be removed from a number when dialling, otherwise the call
  /// will not reach the intended destination.
  private static let diallableCharMappings: [Character: Character] = kAsciiDigitMappings.merging([plusSign: plusSign, "*": "*", "#": "#"]) { _, _ in fatalError("duplicated characters") }
  
  // Only upper-case variants of alpha characters are stored.
  private static let alphaMappings: [Character: Character] = {
    var alphaMappings = [Character: Character](minimumCapacity: 40)
    alphaMappings["A"] = "2"
    alphaMappings["B"] = "2"
    alphaMappings["C"] = "2"
    alphaMappings["D"] = "3"
    alphaMappings["E"] = "3"
    alphaMappings["F"] = "3"
    alphaMappings["G"] = "4"
    alphaMappings["H"] = "4"
    alphaMappings["I"] = "4"
    alphaMappings["J"] = "5"
    alphaMappings["K"] = "5"
    alphaMappings["L"] = "5"
    alphaMappings["M"] = "6"
    alphaMappings["N"] = "6"
    alphaMappings["O"] = "6"
    alphaMappings["P"] = "7"
    alphaMappings["Q"] = "7"
    alphaMappings["R"] = "7"
    alphaMappings["S"] = "7"
    alphaMappings["T"] = "8"
    alphaMappings["U"] = "8"
    alphaMappings["V"] = "8"
    alphaMappings["W"] = "9"
    alphaMappings["X"] = "9"
    alphaMappings["Y"] = "9"
    alphaMappings["Z"] = "9"
    return alphaMappings
  }()
  
  // 117
  /// For performance reasons, amalgamate both into one map.
  private static let alphaPhoneMappings: [Character: Character] = alphaMappings.merging(kAsciiDigitMappings) { _, _ in fatalError("duplicated characters") }
  
  // 121
  /// Separate map of all symbols that we wish to retain when formatting alpha numbers. This
  /// includes digits, ASCII letters and number grouping symbols such as "-" and " ".
  private static let allPlusNumberGroupingSymbols: [Character: Character] = alphaMappings.keys
    .reduce(into: [:]) { result, character in
      result[Character(character.lowercased())] = character
      result[character] = character
    }
    .merging(kAsciiDigitMappings) { _, _ in fatalError("character mismatch") }
    .merging([
      "-": "-",
      "\u{FF0D}": "-",
      "\u{2010}": "-",
      "\u{2011}": "-",
      "\u{2012}": "-",
      "\u{2013}": "-",
      "\u{2014}": "-",
      "\u{2015}": "-",
      "\u{2212}": "-",
      "/": "/",
      "\u{FF0F}": "/",
      " ": " ",
      "\u{3000}": " ",
      "\u{2060}": " ",
      ".": ".",
      "\u{FF0E}": "."
    ]) { _, _ in fatalError("character mismatch") }
  
  /// 229
  /// Pattern that makes it easy to distinguish whether a region has a single international dialing
  /// prefix or not. If a region has a single international prefix (e.g. 011 in USA), it will be
  /// represented as a string that contains a sequence of ASCII digits, and possibly a tilde, which
  /// signals waiting for the tone. If there are multiple available international prefixes in a
  /// region, they will be represented as a regex string that always contains one or more characters
  /// that are not ASCII digits or a tilde.
  private static let singleInternationalPrefixPattern: NSRegularExpression = try! NSRegularExpression(pattern: "[\\d]+(?:[~\u{2053}\u{223C}\u{FF5E}][\\d]+)?", options: [])
  
  // 238
  /// Regular expression of acceptable punctuation found in phone numbers, used to find numbers in
  /// text and to decide what is a viable phone number. This excludes diallable characters.
  /// This consists of dash characters, white space characters, full stops, slashes,
  /// square brackets, parentheses and tildes. It also includes the letter 'x' as that is found as a
  /// placeholder for carrier information in some phone numbers. Full-width variants are also
  /// present.
  static let validPunctuation: String = "-x\u{2010}-\u{2015}\u{2212}\u{30FC}\u{FF0D}-\u{FF0F}\u{00A0}\u{00AD}\u{200B}\u{2060}\u{3000}()\u{FF08}\u{FF09}\u{FF3B}\u{FF3D}.\\[\\]/~\u{2053}\u{223C}\u{FF5E}"
  
  // 241
  private static let digits: String = "\\p{Nd}"
  /// We accept alpha characters in phone numbers, ASCII only, upper and lower case.
  private static let validAlpha: String = String(alphaMappings.keys).replacingOccurrences(of: "[, \\[\\]]", with: "") + String(alphaMappings.keys).lowercased().replacingOccurrences(of: "[, \\[\\]]", with: "")
  static let plusChars: String = "+\u{FF0B}"
  static let plusCharsPattern: NSRegularExpression = try! NSRegularExpression(pattern: "[\(plusChars)]+", options: [])
  private static let separatorPattern: NSRegularExpression = try! NSRegularExpression(pattern: "[\(validPunctuation)]+", options: [])
  private static let capturingDigitsPattern: NSRegularExpression = try! NSRegularExpression(pattern: "(\(digits))", options: [])
  
  // 258
  /// Regular expression of acceptable characters that may start a phone number for the purposes of
  /// parsing. This allows us to strip away meaningless prefixes to phone numbers that may be
  /// mistakenly given to us. This consists of digits, the plus symbol and arabic-indic digits. This
  /// does not contain alpha characters, although they may be used later in the number. It also does
  /// not include other punctuation, as this will be stripped later during parsing and is of no
  /// information value when parsing a number.
  private static let validStartChar: String = "[\(plusChars)\(digits)]"
  private static let validStartCharPattern: NSRegularExpression = try! NSRegularExpression(pattern: validStartChar, options: [])
  
  // 266
  /// Regular expression of characters typically used to start a second phone number for the purposes
  /// of parsing. This allows us to strip off parts of the number that are actually the start of
  /// another number, such as for: (530) 583-6985 x302/x2303 -> the second extension here makes this
  /// actually two phone numbers, (530) 583-6985 x302 and (530) 583-6985 x2303. We remove the second
  /// extension so that the first number is parsed correctly.
  private static let secondNumberStart: String = "[\\\\/] *x"
  static let secondNumberStartPattern: NSRegularExpression = try! NSRegularExpression(pattern: secondNumberStart, options: [])
  
  // 272
  /// Regular expression of trailing characters that we want to remove. We remove all characters that
  /// are not alpha or numerical characters. The hash character is retained here, as it may signify
  /// the previous block was an extension.
  private static let unwantedEndChars: String = "[[\\P{N}&&\\P{L}]&&[^#]]+$"
  static let unwantedEndCharsPattern: NSRegularExpression = try! NSRegularExpression(pattern: unwantedEndChars, options: [])
  
  /// 277
  /// We use this pattern to check if the phone number has at least three letters in it - if so, then
  /// we treat it as a number where some phone-number digits are represented by letters.
  private static let validAlphaPhonePattern: NSRegularExpression = try! NSRegularExpression(pattern: "(?:.*?[A-Za-z]){3}.*", options: [])
  
  // 295
  /// Regular expression of viable phone numbers. This is location independent. Checks we have at
  /// least three leading digits, and only valid punctuation, alpha characters and
  /// digits in the phone number. Does not include extension data.
  /// The symbol 'x' is allowed here as valid punctuation since it is often used as a placeholder for
  /// carrier codes, for example in Brazilian phone numbers. We also allow multiple "+" characters at
  /// the start.
  /// Corresponds to the following:
  /// [digits]{minLengthNsn}|
  /// plus_sign*(([punctuation]|[star])*[digits]){3,}([punctuation]|[star]|[digits]|[alpha])*
  ///
  /// The first reg-ex is to allow short numbers (two digits long) to be parsed if they are entered
  /// as "15" etc, but only if there is no punctuation in them. The second expression restricts the
  /// number of digits to three or more, but then allows them to be in international form, and to
  /// have alpha-characters and punctuation.
  ///
  /// Note VALID_PUNCTUATION starts with a -, so must be the first in the range.
  private static let validPhoneNumber: String = "\(digits){\(minimumLengthForNSN)}|[\(plusChars)]*+(?:[\(validPunctuation)\(starSign)]*\(digits)){3,}[\(validPunctuation)\(starSign)\(validAlpha)\(digits)]*"
  
  // 309
  /// Regexp of all possible ways to write extensions, for use when parsing. This will be run as a
  /// case-insensitive regexp match. Wide character versions are also provided after each ASCII
  /// version.
  private static let extnPatternsForParsing: String = extnPattern(forParsing: true)
  
  // 310
  static let extnPatternsForMatching: String = extnPattern(forParsing: false)
  
  // 316
  /// Helper method for constructing regular expressions for parsing. Creates an expression that
  /// captures up to maxLength digits.
  private static func extnDigits(maximumLength: Int) -> String {
    return "(\(digits){1,\(maximumLength)})"
  }
  
  /// Helper initialiser method to create the regular-expression pattern to match extensions.
  /// Note that there are currently six capturing groups for the extension itself. If this number is
  /// changed, MaybeStripExtension needs to be updated.
  private static func extnPattern(forParsing: Bool) -> String {
    // We cap the maximum length of an extension based on the ambiguity of the way the extension is
    // prefixed. As per ITU, the officially allowed length for extensions is actually 40, but we
    // don't support this since we haven't seen real examples and this introduces many false
    // interpretations as the extension labels are not standardized.
    let extLimitAfterExplicitLabel = 20
    let extLimitAfterLikelyLabel = 15
    let extLimitAfterAmbiguousChar = 9
    let extLimitWhenNotSure = 6

    let possibleSeparatorsBetweenNumberAndExtLabel = "[ \u{00A0}\\t,]*"
    // Optional full stop (.) or colon, followed by zero or more spaces/tabs/commas.
    let possibleCharsAfterExtLabel = "[:\\.\u{FF0E}]?[ \u{00A0}\\t,-]*"
    let optionalExtnSuffix = "#?"

    // Here the extension is called out in more explicit way, i.e mentioning it obvious patterns
    // like "ext.". Canonical-equivalence doesn't seem to be an option with Android java, so we
    // allow two options for representing the accented o - the character itself, and one in the
    // unicode decomposed form with the combining acute accent.
    let explicitExtLabels = "(?:e?xt(?:ensi(?:o\u{0301}?|\u{00F3}))?n?|\u{FF45}?\u{FF58}\u{FF54}\u{FF4E}?|\u{0434}\u{043E}\u{0431}|anexo)"
    // One-character symbols that can be used to indicate an extension, and less commonly used
    // or more ambiguous extension labels.
    let ambiguousExtLabels = "(?:[x\u{FF58}#\u{FF03}~\u{FF5E}]|int|\u{FF49}\u{FF4E}\u{FF54})"
    // When extension is not separated clearly.
    let ambiguousSeparator = "[- ]+"

    let rfcExtn = rfc3966ExtnPrefix + extnDigits(maximumLength: extLimitAfterExplicitLabel)
    let explicitExtn = possibleSeparatorsBetweenNumberAndExtLabel + explicitExtLabels
      + possibleCharsAfterExtLabel + extnDigits(maximumLength: extLimitAfterExplicitLabel)
      + optionalExtnSuffix
    let ambiguousExtn = possibleSeparatorsBetweenNumberAndExtLabel + ambiguousExtLabels
      + possibleCharsAfterExtLabel + extnDigits(maximumLength: extLimitAfterAmbiguousChar)
      + optionalExtnSuffix
    let americanStyleExtnWithSuffix = "\(ambiguousSeparator)\(extnDigits(maximumLength: extLimitWhenNotSure))#"

    // The first regular expression covers RFC 3966 format, where the extension is added using
    // ";ext=". The second more generic where extension is mentioned with explicit labels like
    // "ext:". In both the above cases we allow more numbers in extension than any other extension
    // labels. The third one captures when single character extension labels or less commonly used
    // labels are used. In such cases we capture fewer extension digits in order to reduce the
    // chance of falsely interpreting two numbers beside each other as a number + extension. The
    // fourth one covers the special case of American numbers where the extension is written with a
    // hash at the end, such as "- 503#".
    let extensionPattern = "\(rfcExtn)|\(explicitExtn)|\(ambiguousExtn)|\(americanStyleExtnWithSuffix)"
    // Additional pattern that is supported when parsing extensions, not when matching.
    if forParsing {
      // This is same as possibleSeparatorsBetweenNumberAndExtLabel, but not matching comma as
      // extension label may have it.
      let possibleSeparatorsNumberExtLabelNoComma = "[ \u{00A0}\\t]*"
      // ",," is commonly used for auto dialling the extension when connected. First comma is matched
      // through possibleSeparatorsBetweenNumberAndExtLabel, so we do not repeat it here. Semi-colon
      // works in Iphone and Android also to pop up a button with the extension number following.
      let autoDiallingAndExtLabelsFound = "(?:,{2}|;)"

      let autoDiallingExtn = possibleSeparatorsNumberExtLabelNoComma
          + autoDiallingAndExtLabelsFound + possibleCharsAfterExtLabel
          + extnDigits(maximumLength: extLimitAfterLikelyLabel) +  optionalExtnSuffix
      let onlyCommasExtn = "\(possibleSeparatorsNumberExtLabelNoComma)(?:,)+\(possibleCharsAfterExtLabel)\(extnDigits(maximumLength: extLimitAfterAmbiguousChar))\(optionalExtnSuffix)"
      // Here the first pattern is exclusively for extension autodialling formats which are used
      // when dialling and in this case we accept longer extensions. However, the second pattern
      // is more liberal on the number of commas that acts as extension labels, so we have a strict
      // cap on the number of digits in such extensions.
      return "\(extensionPattern)|\(autoDiallingExtn)|\(onlyCommasExtn)"
    }
    return extensionPattern
  }
  
  // 402
  /// Regexp of all known extension prefixes used by different regions followed by 1 or more valid
  /// digits, for use when parsing.
  private static let extnPattern = try! NSRegularExpression(pattern: "(?:\(extnPatternsForParsing))$", options: regexOptions)
  
  // 407
  /// We append optionally the extension pattern to the end here, as a valid phone number may
  /// have an extension prefix appended, followed by 1 or more digits.
  private static let validPhoneNumberPattern: NSRegularExpression = try! NSRegularExpression(pattern: "\(validPhoneNumber)(?:\(extnPatternsForParsing))?", options: regexOptions)
  
  // 410
  static let nonDigitsPattern: NSRegularExpression = try! NSRegularExpression(pattern: "(\\D+)", options: [])
  
  /// The `firstGroupPattern` was originally set to $1 but there are some countries for which the
  /// first group is not used in the national pattern (e.g. Argentina) so the $1 group does not match
  /// correctly.  Therefore, we use \d, so that the first group actually used in the pattern will be
  /// matched.
  private static let firstGroupPattern: NSRegularExpression = try! NSRegularExpression(pattern: "(\\$\\d)", options: [])
  /// Constants used in the formatting rules to represent the national prefix, first group and
  /// carrier code respectively.
  private static let npString: String = "$NP"
  private static let fgString: String = "$FG"
  private static let ccString: String = "$CC"
  
  // 426
  /// A pattern that is used to determine if the national prefix formatting rule has the first group
  /// only, i.e., does not start with the national prefix. Note that the pattern explicitly allows
  /// for unbalanced parentheses.
  private static let firstGroupOnlyPrefixPattern: NSRegularExpression = try! NSRegularExpression(pattern: "\\(?\\$1\\)?", options: [])
  
  // 430
  public static let regionCodeForNonGeoEntity: String = "001"
  
  // 648 - Aka metadataSource
  /// A source of metadata for different regions.
  let metadataManager: MetadataManager
  
  // 654
  /// A mapping from a country calling code to the region codes which denote the region represented
  /// by that country calling code. In the case of multiple regions sharing a calling code, such as
  /// the NANPA regions, the one indicated with "isMainCountryForCode" in the metadata should be
  /// first.
  private let regionCodesByCountryCode: [Int32: [String]]
  
  // 662
  /// The set of regions that share country calling code 1.
  /// There are roughly 26 regions.
  /// We set the initial capacity of the HashSet to 35 to offer a load factor of roughly 0.75.
  private let nanpaRegionCodes: Set<String>
  
  // 667
  /// A cache for frequently used region-specific regular expressions.
  let regexCache: RegexCache
  
  // 672
  /// The set of region codes the library supports.
  /// There are roughly 240 of them and we set the initial capacity of the HashSet to 320 to offer a
  /// load factor of roughly 0.75.
  public let supportedRegionCodes: Set<String>
  
  //676
  /// The set of country calling codes that map to the non-geo entity region ("001"). This set
  /// currently contains < 12 elements so the default capacity of 16 (load factor=0.75) is fine.
  private let countryCodesForNonGeographicalRegion: Set<Int32>
  
  // MARK: Lifecycle
  
  public init() {
    metadataManager = MetadataManager()
    regionCodesByCountryCode = RegionCodesByCountryCode.regionCodesByCountryCode()
    regexCache = RegexCache()
    var supportedRegionCodes = Set<String>(minimumCapacity: 320)
    var countryCodesForNonGeographicalRegion = Set<Int32>()
    for (countryCode, regionCodes) in regionCodesByCountryCode {
      // We can assume that if the country calling code maps to the non-geo entity region code then
      // that's the only region code it maps to.
      if regionCodes.count == 1 && regionCodes[0] == Self.regionCodeForNonGeoEntity {
        // This is the subset of all country codes that map to the non-geo entity region code.
        countryCodesForNonGeographicalRegion.insert(countryCode)
      } else {
        // The supported regions set does not include the "001" non-geo entity region code.
        supportedRegionCodes.formUnion(regionCodes)
      }
    }
    self.supportedRegionCodes = supportedRegionCodes
    self.countryCodesForNonGeographicalRegion = countryCodesForNonGeographicalRegion
    // If the non-geo entity still got added to the set of supported regions it must be because
    // there are entries that list the non-geo entity alongside normal regions (which is wrong).
    // If we discover this, remove the non-geo entity from the set of supported regions and log.
    if supportedRegionCodes.remove(Self.regionCodeForNonGeoEntity) != nil {
      debugPrint("WARNING", "invalid metadata (country calling code was mapped to the non-geo entity as well as specific region(s))")
    }
    var nanpaRegionCodes = Set<String>(minimumCapacity: 35)
    nanpaRegionCodes.formUnion(regionCodesByCountryCode[Self.nanpaCountryCode]!)
    self.nanpaRegionCodes = nanpaRegionCodes
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
            let metadata = metadataManager.metadataByCountryCode[phoneNumber.countryCode]
            let formattedNationalNumber = self.format(phoneNumber: phoneNumber, format: format, metadata: metadata)
            if format == .international, withPrefix {
                return "+\(phoneNumber.countryCode) \(formattedNationalNumber)"
            } else {
                return formattedNationalNumber
            }
        }
    }

    // MARK: Country and region code

    /// Get leading digits for an ISO 639 compliant region code.
    ///
    /// - parameter regionCode: ISO 639 compliant region code.
    ///
    /// - returns: leading digits (e.g. 876 for Jamaica).
    public func leadingDigits(forRegionCode regionCode: String) -> String? {
        return metadataManager.metadataByRegionCode[regionCode]?.leadingDigits
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
        return exampleNumber(regionCode: regionCode, type: type)
            .flatMap { self.format($0, format: format, withPrefix: withPrefix) }
    }

    /// Get an array of Metadata objects corresponding to a given country code.
    ///
    /// - parameter countryCode: international country code (e.g 44 for the UK)
    public func metadata(forCountryCode countryCode: Int32) -> PhoneMetadata? {
        return metadataManager.metadataByCountryCode[countryCode]
    }

    /// Get an array of Metadata objects corresponding to a given country code.
    ///
    /// - parameter countryCode: international country code (e.g 44 for the UK)
    public func metadatas(forCountryCode countryCode: Int32) -> [PhoneMetadata]? {
        return metadataManager.metadatasByCountryCode[countryCode]
    }

    /// Get an array of possible phone number lengths for the country, as specified by the parameters.
    ///
    /// - parameter country: ISO 639 compliant region code.
    /// - parameter phoneNumberType: PhoneNumberType enum.
    /// - parameter lengthType: PossibleLengthType enum.
    ///
    /// - returns: Array of possible lengths for the country. May be empty.
    public func possiblePhoneNumberLengths(regionCode: String, phoneNumberType: PhoneNumberType, lengthType: PhoneNumberPossibleLengthType) -> [Int] {
        guard let metadata = metadataManager.metadataByRegionCode[regionCode] else { return [] }

        let possibleLengths = possiblePhoneNumberLengths(metadata: metadata, phoneNumberType: phoneNumberType)

        switch lengthType {
        case .national:     return possibleLengths?.national.flatMap { parsePossibleLengths($0) } ?? []
        case .localOnly:    return possibleLengths?.localOnly.flatMap { parsePossibleLengths($0) } ?? []
        }
    }

    private func possiblePhoneNumberLengths(metadata: PhoneMetadata, phoneNumberType: PhoneNumberType) -> PhoneNumberPossibleLengths? {
        switch phoneNumberType {
        case .fixedLine:        return metadata.fixedLine?.possibleLengths
        case .mobile:           return metadata.mobile?.possibleLengths
        case .pager:            return metadata.pager?.possibleLengths
        case .personalNumber:   return metadata.personalNumber?.possibleLengths
        case .premiumRate:      return metadata.premiumRate?.possibleLengths
        case .sharedCost:       return metadata.sharedCost?.possibleLengths
        case .tollFree:         return metadata.tollFree?.possibleLengths
        case .voicemail:        return metadata.voicemail?.possibleLengths
        case .voip:             return metadata.voip?.possibleLengths
        case .uan:              return metadata.uan?.possibleLengths
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
        guard var metadata = metadataManager.metadataByRegionCode[regionCode] else {
            throw PhoneNumberError.invalidCountryCode
        }
        var countryCode: Int32
        do {
            countryCode = try extractCountryCode(nationalNumber, nationalNumber: &nationalNumber, metadata: metadata)
        } catch {
            let plusRemovedNumberString = regexCache.replaceStringByRegex(pattern: PhoneNumberPatterns.leadingPlusCharsPattern, string: nationalNumber)
            countryCode = try extractCountryCode(plusRemovedNumberString, nationalNumber: &nationalNumber, metadata: metadata)
        }
        if countryCode == 0 {
            countryCode = metadata.countryCode
        }
        // Normalized number (5)
        let normalizedNationalNumber = normalizePhoneNumber(nationalNumber)
        nationalNumber = normalizedNationalNumber

        // If country code is not default, grab correct metadata (6)
        if countryCode != metadata.countryCode, let metadataByCountry = metadataManager.metadataByCountryCode[countryCode] {
            metadata = metadataByCountry
        }
        // National Prefix Strip (7)
        stripNationalPrefix(&nationalNumber, metadata: metadata)

        // Test number against general number description for correct metadata (8)
        if let generalNumberDesc = metadata.generalDesc, !regexCache.hasValue(generalNumberDesc.nationalNumberPattern) || !isNumberMatchingDesc(nationalNumber, numberDesc: generalNumberDesc) {
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
            if let regionCode = regionCodeHelper(nationalNumber: finalNationalNumber, countryCode: countryCode, leadingZero: leadingZero), let foundMetadata = metadataManager.metadataByRegionCode[regionCode] {
                metadata = foundMetadata
            }
            type = phoneNumberType(nationalNumber: String(nationalNumber), metadata: metadata, leadingZero: leadingZero)
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
        guard let metadatas = metadataManager.metadatasByCountryCode[countryCode] else { return nil }

        if metadatas.count == 1 {
            return metadatas[0].regionCode
        }

        let nationalNumberString = String(nationalNumber)
        for metadata in metadatas {
            if let leadingDigits = metadata.leadingDigits {
                if regexCache.matchesAtStartByRegex(pattern: leadingDigits, string: nationalNumberString) {
                    return metadata.regionCode
                }
            }
            if leadingZero && phoneNumberType(nationalNumber: "0" + nationalNumberString, metadata: metadata, leadingZero: false) != .unknown {
                return metadata.regionCode
            }
            if phoneNumberType(nationalNumber: nationalNumberString, metadata: metadata, leadingZero: false) != .unknown {
                return metadata.regionCode
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
     - Parameter metadata: Metadata object.
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
                if (!regexCache.matchesEntirelyByRegex(pattern: validNumberPattern, string: fullNumber) && regexCache.matchesEntirelyByRegex(pattern: validNumberPattern, string: potentialNationalNumberStr)) || !regexCache.testStringLengthAgainstPattern(pattern: possibleNumberPattern, string: fullNumber) {
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
            if let potentialCountryCode = Int32(subNumber), metadataManager.metadatasByCountryCode[potentialCountryCode] != nil {
                nationalNumber = fullNumber.substring(from: i)
                return potentialCountryCode
            }
        }
        return 0
    }

    // MARK: Validations

    func phoneNumberType(nationalNumber: String, metadata: PhoneMetadata, leadingZero: Bool = true) -> PhoneNumberType {
        if leadingZero {
            let type = self.phoneNumberType(nationalNumber: "0" + nationalNumber, metadata: metadata, leadingZero: false)
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
        return regexCache.matchesEntirelyByRegex(pattern: numberDesc?.nationalNumberPattern, string: nationalNumber)
    }

    /**
     Checks and strips if prefix is international dialing pattern.
     - Parameter number: Number string.
     - Parameter iddPattern:  iddPattern for a given country.
     - Returns: True or false and modifies the number accordingly.
     */
    func parsePrefixAsIdd(_ number: inout String, iddPattern: String) -> Bool {
        guard regexCache.stringPositionByRegex(pattern: iddPattern, string: number) == 0 else {
            return false
        }
        do {
            guard let match = try? regexCache.matchesByRegex(pattern: iddPattern, string: number).first else {
                return false
            }
            let matchedString = number.substring(with: match.range)
            let matchEnd = matchedString.count
            let remainString = (number as NSString).substring(from: matchEnd)
            let capturingDigitPatterns = try NSRegularExpression(pattern: PhoneNumberPatterns.capturingDigitPattern, options: .caseInsensitive)
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

    // MARK: Strip helpers

    /**
     Strip an extension (e.g +33 612-345-678 ext.89 to 89).
     - Parameter number: Number string.
     - Returns: Modified number without extension and optional extension as string.
     */
    func stripExtension(_ number: inout String) -> String? {
        if let match = try? regexCache.matchesByRegex(pattern: PhoneNumberPatterns.extnPattern, string: number).first {
            let adjustedRange = NSRange(location: match.range.location + 1, length: match.range.length - 1)
            let matchString = number.substring(with: adjustedRange)
            let stringRange = NSRange(location: 0, length: match.range.location)
            number = number.substring(with: stringRange)
            return matchString
        }
        return nil
    }

    /**
     Strip international prefix.
     - Parameter number: Number string.
     - Parameter possibleIddPrefix:  Possible idd prefix for a given country.
     - Returns: Modified normalized number without international prefix and a PNCountryCodeSource enumeration.
     */
    func stripInternationalPrefixAndNormalize(_ number: inout String, possibleIddPrefix: String?) -> PhoneNumber.CountryCodeSource {
        if regexCache.matchesAtStartByRegex(pattern: PhoneNumberPatterns.leadingPlusCharsPattern, string: number) {
            number = regexCache.replaceStringByRegex(pattern: PhoneNumberPatterns.leadingPlusCharsPattern, string: number)
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
        guard let firstMatch = try? regexCache.matchesByRegex(pattern: prefixPattern, string: number).first else {
            return
        }
        let nationalNumberRule = metadata.generalDesc?.nationalNumberPattern
        let firstMatchString = number.substring(with: firstMatch.range)
        let numOfGroups = firstMatch.numberOfRanges - 1
        var transformedNumber = ""
        let firstRange = firstMatch.range(at: numOfGroups)
        let firstMatchStringWithGroup = firstRange.length > 0 && firstRange.location < number.utf16.count ? number.substring(with: firstRange) : ""
        let firstMatchStringWithGroupHasValue = regexCache.hasValue(firstMatchStringWithGroup)
        if let transformRule = metadata.nationalPrefixTransformRule, firstMatchStringWithGroupHasValue {
            transformedNumber = regexCache.replaceFirstStringByRegex(pattern: prefixPattern, string: number, template: transformRule)
        } else {
            let index = number.index(number.startIndex, offsetBy: firstMatchString.count)
            transformedNumber = String(number[index...])
        }
        if regexCache.hasValue(nationalNumberRule) && regexCache.matchesEntirelyByRegex(pattern: nationalNumberRule, string: number) && !regexCache.matchesEntirelyByRegex(pattern: nationalNumberRule, string: transformedNumber) {
            return
        }
        number = transformedNumber
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
    ///   - metadata: Region meta data.
    /// - Returns: Formatted Modified national number ready for display.
    func format(phoneNumber: PhoneNumber, format: PhoneNumberFormat, metadata: PhoneMetadata?) -> String {
        var formattedNationalNumber = phoneNumber.adjustedNationalNumber()
        if let metadata = metadata {
            formattedNationalNumber = formatNationalNumber(formattedNationalNumber, metadata: metadata, format: format)
            if let formattedExtension = formatExtension(phoneNumber.extension, metadata: metadata) {
                formattedNationalNumber = formattedNationalNumber + formattedExtension
            }
        }
        return formattedNationalNumber
    }

    /// Formats extension for display
    ///
    /// - Parameters:
    ///   - numberExtension: Number extension string.
    ///   - metadata: Region meta data.
    /// - Returns: Modified number extension with either a preferred extension prefix or the default one.
    func formatExtension(_ numberExtension: String?, metadata: PhoneMetadata) -> String? {
        if let extns = numberExtension {
            if let preferredExtnPrefix = metadata.preferredExtnPrefix {
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
    ///   - metadata: Region meta data.
    ///   - format: Format.
    /// - Returns: Modified nationalNumber for display.
    func formatNationalNumber(_ nationalNumber: String, metadata: PhoneMetadata, format: PhoneNumberFormat) -> String {
        let formats = metadata.numberFormats
        var selectedFormat: NumberFormat?
        for format in formats {
            if let leadingDigitPattern = format.leadingDigitsPatterns?.last {
                if regexCache.stringPositionByRegex(pattern: leadingDigitPattern, string: nationalNumber) == 0 {
                    if regexCache.matchesEntirelyByRegex(pattern: format.pattern, string: nationalNumber) {
                        selectedFormat = format
                        break
                    }
                }
            } else {
                if regexCache.matchesEntirelyByRegex(pattern: format.pattern, string: nationalNumber) {
                    selectedFormat = format
                    break
                }
            }
        }
        if let formatPattern = selectedFormat {
            guard let numberFormatRule = (format == PhoneNumberFormat.international && formatPattern.intlFormat != nil) ? formatPattern.intlFormat : formatPattern.format, let pattern = formatPattern.pattern else {
                return nationalNumber
            }
            var formattedNationalNumber = ""
            var prefixFormattingRule = ""
            if let nationalPrefixFormattingRule = formatPattern.nationalPrefixFormattingRule, let nationalPrefix = metadata.nationalPrefix {
                prefixFormattingRule = regexCache.replaceStringByRegex(pattern: PhoneNumberPatterns.npPattern, string: nationalPrefixFormattingRule, template: nationalPrefix)
                prefixFormattingRule = regexCache.replaceStringByRegex(pattern: PhoneNumberPatterns.fgPattern, string: prefixFormattingRule, template: "\\$1")
            }
            if format == PhoneNumberFormat.national, regexCache.hasValue(prefixFormattingRule) {
                let replacePattern = regexCache.replaceFirstStringByRegex(pattern: PhoneNumberPatterns.firstGroupPattern, string: numberFormatRule, template: prefixFormattingRule)
                formattedNationalNumber = regexCache.replaceStringByRegex(pattern: pattern, string: nationalNumber, template: replacePattern)
            } else {
                formattedNationalNumber = regexCache.replaceStringByRegex(pattern: pattern, string: nationalNumber, template: numberFormatRule)
            }
            return formattedNationalNumber
        } else {
            return nationalNumber
        }
    }
}

extension PhoneNumberUtil {
  
  // 723
  /// Attempts to extract a possible number from the string passed in. This currently strips all
  /// leading characters that cannot be used to start a phone number. Characters that can be used to
  /// start a phone number are defined in the VALID_START_CHAR_PATTERN. If none of these characters
  /// are found in the number passed in, an empty string is returned. This function also attempts to
  /// strip off any alternative extensions or endings if two or more are present, such as in the case
  /// of: (530) 583-6985 x302/x2303. The second extension here makes this actually two phone numbers,
  /// (530) 583-6985 x302 and (530) 583-6985 x2303. We remove the second extension so that the first
  /// number is parsed correctly.
  ///
  /// - Parameter string: the string that might contain a phone number.
  /// - Returns: the number, stripped of any non-phone-number prefix (such as "Tel:") or an empty
  ///   string if no character used to start phone numbers (such as + or any digit) is found in the
  ///   number.
  func extractPossibleNumber(_ string: String) -> String {
    if let match = Self.validStartCharPattern.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) {
      var number = (string as NSString).substring(with: NSRange(location: match.range.location, length: string.utf16.count - match.range.location))
      // Remove trailing non-alpha non-numerical characters.
      if let trailingCharsMatch = Self.unwantedEndCharsPattern.firstMatch(in: number, options: [], range: NSRange(location: 0, length: number.utf16.count)) {
        number = (number as NSString).substring(with: NSRange(location: 0, length: trailingCharsMatch.range.location))
      }
      // Check for extra numbers at the end.
      if let secondNumberMatch = Self.secondNumberStartPattern.firstMatch(in: number, options: [], range: NSRange(location: 0, length: number.utf16.count)) {
        number = (number as NSString).substring(with: NSRange(location: 0, length: secondNumberMatch.range.location))
      }
      return number
    } else {
      return ""
    }
  }
  
  // 754
  /// Checks to see if the string of characters could possibly be a phone number at all. At the
  /// moment, checks to see that the string begins with at least 2 digits, ignoring any punctuation
  /// commonly found in phone numbers.
  /// This method does not require the number to be normalized in advance - but does assume that
  /// leading non-number symbols have been removed, such as by the method extractPossibleNumber.
  ///
  /// - Parameter string: string to be checked for viability as a phone number.
  /// - Returns: true if the number could be a phone number of some sort, otherwise false.
  static func isViablePhoneNumber(string: String) -> Bool {
    if string.utf16.count < Self.minimumLengthForNSN {
      return false
    }
    return Self.validPhoneNumberPattern.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) != nil
  }
  
  // 778
  /// Normalizes a string of characters representing a phone number. This performs the following
  /// conversions:
  ///   - Punctuation is stripped.
  ///   For ALPHA/VANITY numbers:
  ///   - Letters are converted to their numeric representation on a telephone keypad. The keypad
  ///     used here is the one defined in ITU Recommendation E.161. This is only done if there are 3
  ///     or more letters in the number, to lessen the risk that such letters are typos.
  ///   For other numbers:
  ///   - Wide-ascii digits are converted to normal ASCII (European) digits.
  ///   - Arabic-Indic numerals are converted to European numerals.
  ///   - Spurious alpha characters are stripped.
  ///
  /// - Parameter number: a StringBuilder of characters representing a phone number that will be
  ///   normalized in place
  static func normalize(_ string: String) -> String {
    var normalizedString: String
    if validAlphaPhonePattern.firstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count)) != nil {
      normalizedString = normalizeHelper(string, normalizationReplacements: Self.alphaPhoneMappings, removeNonMatches: true)
    } else {
      normalizedString = normalizeDigitsOnly(string)
    }
    return normalizedString
  }
  
  // 795
  /// Normalizes a string of characters representing a phone number. This converts wide-ascii and
  /// arabic-indic numerals to European numerals, and strips punctuation and alpha characters.
  /// - Parameter number: a string of characters representing a phone number.
  /// - Returns: the normalized string version of the phone number.
  public static func normalizeDigitsOnly(_ string: String) -> String {
    return normalizeDigits(string, keepNonDigits: false /* strip non-digits */)
  }
  
  // 799
  static func normalizeDigits(_ string: String, keepNonDigits: Bool) -> String {
    var normalizedDigits = ""
    for character in string {
      let digit = Int(String(character), radix: 10)
      if digit != -1 {
        normalizedDigits.append(character)
      } else if keepNonDigits {
        normalizedDigits.append(character)
      }
    }
    return normalizedDigits
  }
  
  // 820
  /// Normalizes a string of characters representing a phone number. This strips all characters which
  /// are not diallable on a mobile phone keypad (including all non-ASCII digits).
  /// - Parameter number: a string of characters representing a phone number.
  /// - Returns: the normalized string version of the phone number.
  public static func normalizeDiallableCharsOnly(_ string: String) -> String {
    return normalizeHelper(string, normalizationReplacements: Self.diallableCharMappings, removeNonMatches: true /* remove non matches */)
  }
  
  // 828
  /// Converts all alpha characters in a number to their respective digits on a keypad, but retains
  /// existing formatting.
  public static func convertAlphaCharactersInNumber(_ string: String) -> String {
    return normalizeHelper(string, normalizationReplacements: Self.alphaPhoneMappings, removeNonMatches: false)
  }
  
  // 1002
  /// Normalizes a string of characters representing a phone number by replacing all characters found
  /// in the accompanying map with the values therein, and stripping all other characters if
  /// removeNonMatches is true.
  /// - Parameters:
  ///   - string: a string of characters representing a phone number.
  ///   - normalizationReplacements: a mapping of characters to what they should be replaced by in
  ///     the normalized version of the phone number
  ///   - removeNonMatches: indicates whether characters that are not able to be replaced should
  ///     be stripped from the number. If this is false, they will be left unchanged in the number.
  /// - Returns: the normalized string version of the phone number.
  private static func normalizeHelper(_ string: String, normalizationReplacements: [Character: Character], removeNonMatches: Bool) -> String {
    var normalizedString = ""
    for character in string {
      if let newDigit = normalizationReplacements[character] {
        normalizedString.append(newDigit)
      } else if !removeNonMatches {
        normalizedString.append(character)
      }
      // If neither of the above are true, we remove this character.
    }
    return normalizedString
  }
  
  // 1044
  /// Returns all global network calling codes the library has metadata for.
  /// - Returns: An unordered set of the country calling codes for every non-geographical entity the
  /// library supports.
  public func supportedGlobalNetworkCountryCodes() -> Set<Int32> {
    return countryCodesForNonGeographicalRegion
  }
  
  // 1057
  /// Returns all country calling codes the library has metadata for, covering both non-geographical
  /// entities (global network calling codes) and those used for geographical entities. This could be
  /// used to populate a drop-down box of country calling codes for a phone-number widget, for
  /// instance.
  /// - Returns: An unordered set of the country calling codes for every geographical and
  /// non-geographical entity the library supports
  public func supportedCountryCodes() -> Set<Int32> {
    return Set<Int32>(regionCodesByCountryCode.keys)
  }
  
  // 1210
  /// Tests whether a phone number has a geographical association. It checks if the number is
  /// associated with a certain region in the country to which it belongs. Note that this doesn't
  /// verify if the number is actually in use.
  @available(*, unavailable)
  public func isGeographical(_ phoneNumber: PhoneNumber) -> Bool {
    fatalError()
    // FIXME:
//    return isNumberGeographical(getNumberType(phoneNumber), phoneNumber.getCountryCode());
  }
  
  // 1218
  /// Overload of isNumberGeographical(PhoneNumber), since calculating the phone number type is
  /// expensive; if we have already done this, we don't want to do it again.
  public func isGeographicalPhoneNumber(type: PhoneNumberType, countryCode: Int32) -> Bool {
    return type == .fixedLine || type == .fixedLineOrMobile || (Self.geoMobileCountryCodes.contains(countryCode) && type == .mobile)
  }
  
  // 1228
  /// Helper function to check region code is not unknown or null.
  private func isValid(regionCode: String) -> Bool {
    return supportedRegionCodes.contains(regionCode)
  }
  
  // 1235
  /// Helper function to check the country calling code is valid.
  private func hasValid(countryCode: Int32) -> Bool {
    return regionCodesByCountryCode.keys.contains(countryCode)
  }
  
  // 1402
  private func metadata(countryCode: Int32, regionCode: String) -> PhoneMetadata? {
    return regionCode == Self.regionCodeForNonGeoEntity ? metadataForNonGeographicalRegion(countryCode: countryCode) : metadata(forRegionCode: regionCode)
  }
  
  // 1875
  /// Gets the national significant number of a phone number. Note a national significant number
  /// doesn't contain a national prefix or any formatting.
  /// - Parameter number: the phone number for which the national significant number is needed.
  /// - Returns: the national significant number of the PhoneNumber object passed in.
  public func nationalSignificantNumber(of phoneNumber: PhoneNumber) -> String {
    // If leading zero(s) have been set, we prefix this now. Note this is not a national prefix.
    var nationalNumber = ""
    if phoneNumber.italianLeadingZero && phoneNumber.numberOfLeadingZeros > 0 {
      let zeros = [Character](repeating: "0", count: phoneNumber.numberOfLeadingZeros)
      nationalNumber += String(zeros)
    }
    nationalNumber += String(phoneNumber.nationalNumber)
    return nationalNumber
  }
  
  // 1890
  /// A helper function that is used by format and formatByPattern.
  private func prefixNumber(countryCode: Int32, numberFormat: PhoneNumberFormat, formattedNumber: inout String) {
    switch numberFormat {
    case .e164:
      formattedNumber = "\(Self.plusSign)\(countryCode)\(formattedNumber)"
    case .international:
      formattedNumber = "\(Self.plusSign)\(countryCode) \(formattedNumber)"
    case .rfc3966:
      formattedNumber = "\(Self.rfc3966Prefix)\(Self.plusSign)\(countryCode)-\(formattedNumber)"
    case .national:
      return
    }
  }
  
  // 1911
  /// Simple wrapper of formatNsn for the common case of no carrier code.
  @available(*, unavailable)
  private func formatNsn(string: String, metadata: PhoneMetadata, numberFormat: PhoneNumberFormat) -> String {
    fatalError()
    // FIXME:
//    "return formatNsn(number, metadata, numberFormat, null);
  }
  
  // 2108
  /// Gets a valid number for the specified number type (it may belong to any country).
  /// - Parameter type: the type of number that is needed.
  /// - Returns: a valid number for the specified type. Returns null when the metadata
  /// does not contain such information. This should only happen when no numbers of this type are
  /// allocated anywhere in the world anymore.
  public func exampleNumber(type: PhoneNumberType) -> PhoneNumber? {
    for regionCode in supportedRegionCodes {
      if let exampleNumber = exampleNumber(regionCode: regionCode, type: type) {
        return exampleNumber
      }
    }
    // If there wasn't an example number for a region, try the non-geographical entities.
    for countryCode in countryCodesForNonGeographicalRegion {
      guard let desc = numberDesc(metadata: metadataForNonGeographicalRegion(countryCode: countryCode)!, type: type) else {
        continue
      }
      if let exampleNumber = desc.exampleNumber {
        do {
          return try parse("+\(countryCode)\(exampleNumber)", defaultRegionCode: Self.unknownRegionCode)
        } catch {
          debugPrint("SEVERE", error)
        }
      }
    }
    // There are no example numbers of this type for any country in the library.
    return nil
  }
  
  // 2184
  func numberDesc(metadata: PhoneMetadata, type: PhoneNumberType) -> PhoneNumberDesc? {
    switch type {
    case .premiumRate:
      return metadata.premiumRate
    case .tollFree:
      return metadata.tollFree
    case .mobile:
      return metadata.mobile
    case .fixedLine, .fixedLineOrMobile:
      return metadata.fixedLine
    case .sharedCost:
      return metadata.sharedCost
    case .voip:
      return metadata.voip
    case .personalNumber:
      return metadata.personalNumber
    case .pager:
      return metadata.pager
    case .uan:
      return metadata.uan
    case .voicemail:
      return metadata.voicemail
    default:
      return metadata.generalDesc
    }
  }
  
  // 2280
  /// Returns the metadata for the given region code or {@code null} if the region code is invalid
  /// or unknown.
  func metadata(forRegionCode regionCode: String) -> PhoneMetadata? {
    if !isValid(regionCode: regionCode) {
      return nil
    }
    return metadataManager.metadata(forRegionCode: regionCode)
  }
  
  // 2287
  func metadataForNonGeographicalRegion(countryCode: Int32) -> PhoneMetadata? {
    if !regionCodesByCountryCode.keys.contains(countryCode) {
      return nil
    }
    return metadataManager.metadataForNonGeographicalRegion(forCountryCode: countryCode)
  }
  
  // 2338
  public func isValid(phoneNumber: PhoneNumber, regionCode: String) -> Bool {
    let countryCode = phoneNumber.countryCode
    guard let metadata = self.metadata(countryCode: countryCode, regionCode: regionCode) else {
      return false
    }
    if regionCode != Self.regionCodeForNonGeoEntity && countryCode != (try? self.countryCode(forValidRegionCode: regionCode)) {
      // Either the region code was invalid, or the country calling code for this number does not
      // match that of the region code.
      return false
    }
    let nationalSignificantNumber = self.nationalSignificantNumber(of: phoneNumber)
    return phoneNumberType(nationalNumber: nationalSignificantNumber, metadata: metadata) != .unknown
  }
  
  // 2361
  /// Returns the region where a phone number is from. This could be used for geocoding at the region
  /// level. Only guarantees correct results for valid, full numbers (not short-codes, or invalid
  /// numbers).
  /// - Parameter number: the phone number whose origin we want to know.
  /// - Returns: the region where the phone number is from, or null if no region matches this calling
  /// code.
  public func regionCode(for phoneNumber: PhoneNumber) -> String? {
    let countryCode = phoneNumber.countryCode
    guard let regionCodes = regionCodesByCountryCode[countryCode] else {
      debugPrint("INFO", "Missing/invalid country_code (\(countryCode))")
      return nil
    }
    if regionCodes.count == 1 {
      return regionCodes.first
    } else {
      return regionCode(for: phoneNumber, in: regionCodes)
    }
  }
  
  // 2375
  private func regionCode(for phoneNumber: PhoneNumber, in regionCodes: [String]) -> String? {
    let nationalNumber = nationalSignificantNumber(of: phoneNumber)
    for regionCode in regionCodes {
      // If leadingDigits is present, use this. Otherwise, do full validation.
      // Metadata cannot be null because the region codes come from the country calling code map.
      if let metadata = self.metadata(forRegionCode: regionCode) {
        if let leadingDigits = metadata.leadingDigits {
          if try! regexCache.regex(pattern: leadingDigits).firstMatch(in: nationalNumber, options: [], range: NSRange(location: 0, length: nationalNumber.utf16.count)) != nil {
            return regionCode
          }
        } else if phoneNumberType(nationalNumber: nationalNumber, metadata: metadata) != .unknown {
          return regionCode
        }
      }
    }
    return nil
  }
  
  // 2402
  /// Returns the region code that matches the specific country calling code. In the case of no
  /// region code being found, ZZ will be returned. In the case of multiple regions, the one
  /// designated in the metadata as the "main" region for this calling code will be returned. If the
  /// countryCallingCode entered is valid but doesn't match a specific region (such as in the case of
  /// non-geographical calling codes like 800) the value "001" will be returned (corresponding to
  /// the value for World in the UN M.49 schema).
  public func regionCode(forCountryCode countryCode: Int32) -> String? {
    return regionCodesByCountryCode[countryCode]?.first
  }
  
  // 2412
  /// Returns a list with the region codes that match the specific country calling code. For
  /// non-geographical country calling codes, the region code 001 is returned. Also, in the case
  /// of no region code being found, an empty list is returned.
  public func regionCodes(forCountryCode countryCode: Int32) -> [String]? {
    return regionCodesByCountryCode[countryCode]
  }
  
  // 2425
  /// Returns the country calling code for a specific region. For example, this would be 1 for the
  /// United States, and 64 for New Zealand.
  /// - Parameter regionCode: the region that we want to get the country calling code for.
  /// - Returns: the country calling code for the region denoted by regionCode.
  public func countryCode(forRegionCode regionCode: String) -> Int32? {
    if !isValid(regionCode: regionCode) {
      debugPrint("WARNING", "Invalid region code (\(regionCode)) provided.")
      return nil
    }
    return try! countryCode(forValidRegionCode: regionCode)
  }
  
  // 2444
  /// Returns the country calling code for a specific region. For example, this would be 1 for the
  /// United States, and 64 for New Zealand. Assumes the region is already valid.
  /// - Parameter regionCode: the region that we want to get the country calling code for.
  /// - Throws: `NSError` if the region is invalid.
  /// - Returns: The country calling code for the region denoted by regionCode.
  private func countryCode(forValidRegionCode regionCode: String) throws -> Int32 {
    guard let metadata = metadata(forRegionCode: regionCode) else {
      throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid region code: \(regionCode)"])
    }
    return metadata.countryCode
  }
  
  /// Parses a string and returns it as a phone number in proto buffer format. The method is quite
  /// lenient and looks for a number in the input text (raw input) and does not check whether the
  /// string is definitely only a phone number. To do this, it ignores punctuation and white-space,
  /// as well as any text before the number (e.g. a leading "Tel: ") and trims the non-number bits.
  /// It will accept a number in any format (E164, national, international etc), assuming it can be
  /// interpreted with the defaultRegion supplied. It also attempts to convert any alpha characters
  /// into digits if it thinks this is a vanity number of the type "1800 MICROSOFT".
  ///
  /// <p> This method will throw a {@link com.google.i18n.phonenumbers.NumberParseException} if the
  /// number is not considered to be a possible number. Note that validation of whether the number
  /// is actually a valid number for a particular region is not performed. This can be done
  /// separately with {@link #isValidNumber}.
  ///
  /// <p> Note this method canonicalizes the phone number such that different representations can be
  /// easily compared, no matter what form it was originally entered in (e.g. national,
  /// international). If you want to record context about the number being parsed, such as the raw
  /// input that was entered, how the country code was derived etc. then call {@link
  /// #parseAndKeepRawInput} instead.
  ///
  /// - Parameters:
  ///   - numberToParse:  number that we are attempting to parse. This can contain formatting such
  ///     as +, ( and -, as well as a phone number extension. It can also be provided in RFC3966
  ///     format.
  ///   - defaultRegionCode:  region that we are expecting the number to be from. This is only used if
  ///     the number being parsed is not written in international format. The country_code for the
  ///     number in this case would be stored as that of the default region supplied. If the number
  ///     is guaranteed to start with a '+' followed by the country calling code, then RegionCode.ZZ
  ///     or null can be supplied.
  /// - Throws: NumberParseException  if the string is not considered to be a viable phone number (e.g.
  ///   too few or too many digits) or if no default region was supplied and the number is not in
  ///   international format (does not start with +)
  /// - Returns: A phone number proto buffer filled with the parsed number.
  public func parse(_ numberToParse: String, defaultRegionCode: String) throws -> PhoneNumber {
    fatalError()
    // FIXME:
//    return parse(numberToParse, defaultRegion, phoneNumber)
  }
  
  // 3567
  /// Returns true if the supplied region supports mobile number portability. Returns false for
  /// invalid, unknown or regions that don't support mobile number portability.
  /// - Parameter regionCode: the region for which we want to know whether it supports mobile number
  ///   portability or not.
  public func isMobileNumberPortableRegion(regionCode: String) -> Bool {
    guard let metadata = metadata(forRegionCode: regionCode) else {
      return false
    }
    return metadata.mobileNumberPortableRegion
  }
  
  // 2083
  /// Gets a valid number for the specified region and number type.
  /// - Parameters:
  ///   - regionCode: the region for which an example number is needed.
  ///   - type: the type of number that is needed.
  /// - Returns: a valid number for the specified region and type. Returns null when the metadata
  ///   does not contain such information or if an invalid region or region 001 was entered.
  ///   For 001 (representing non-geographical numbers), call
  ///   {@link #getExampleNumberForNonGeoEntity} instead.
  public func exampleNumber(regionCode: String, type: PhoneNumberType) -> PhoneNumber? {
    // Check the region code is valid.
    if !isValid(regionCode: regionCode) {
      return nil
    }
    if let desc = numberDesc(metadata: metadata(forRegionCode: regionCode)!, type: type) {
      if let exampleNumber = desc.exampleNumber {
        return try? parse(exampleNumber, regionCode: regionCode)
      }
    }
    return nil
  }
  
  /*
  // 3202
  /// Parses a string and fills up the phoneNumber. This method is the same as the public
  /// parse() method, with the exception that it allows the default region to be null, for use by
  /// isNumberMatch(). checkRegion should be set to false if it is permitted for the default region
  /// to be null or unknown ("ZZ").
  ///
  /// Note if any new field is added to this method that should always be filled in, even when
  /// keepRawInput is false, it should also be handled in the copyCoreFieldsOnly() method.
  private func parseHelper(numberToParse: String?, defaultRegion: String?, keepRawInput: Bool, checkRegion: Bool) throws -> PhoneNumber {
    guard let numberToParse = numberToParse else {
      throw PhoneNumberParseError.notANumber("The phone number supplied was null.")
    }
    guard numberToParse.utf16.count <= Self.maximumInputStringLength else {
      throw PhoneNumberParseError.tooLong("The string supplied was too long to parse.")
    }
    
    var nationalNumber = ""
    var numberBeingParsed = numberToParse
    buildNationalNumberForParsing(numberBeingParsed, nationalNumber);
    
    if (!isViablePhoneNumber(nationalNumber)) {
      throw new NumberParseException(NumberParseException.ErrorType.NOT_A_NUMBER,
                                     "The string supplied did not seem to be a phone number.");
    }
    
    // Check the region supplied is valid, or that the extracted number starts with some sort of +
    // sign so the number's region can be determined.
    if (checkRegion && !checkRegionForParsing(nationalNumber, defaultRegion)) {
      throw new NumberParseException(NumberParseException.ErrorType.INVALID_COUNTRY_CODE,
                                     "Missing or invalid default region.");
    }
    
    if (keepRawInput) {
      phoneNumber.setRawInput(numberBeingParsed);
    }
    // Attempt to parse extension first, since it doesn't require region-specific data and we want
    // to have the non-normalised number here.
    String extension = maybeStripExtension(nationalNumber);
    if (extension.length() > 0) {
      phoneNumber.setExtension(extension);
    }
    
    PhoneMetadata regionMetadata = getMetadataForRegion(defaultRegion);
    // Check to see if the number is given in international format so we know whether this number is
    // from the default region or not.
    StringBuilder normalizedNationalNumber = new StringBuilder();
    int countryCode = 0;
    try {
      // TODO: This method should really just take in the string buffer that has already
      // been created, and just remove the prefix, rather than taking in a string and then
      // outputting a string buffer.
      countryCode = maybeExtractCountryCode(nationalNumber, regionMetadata,
                                            normalizedNationalNumber, keepRawInput, phoneNumber);
    } catch (NumberParseException e) {
      Matcher matcher = PLUS_CHARS_PATTERN.matcher(nationalNumber);
      if (e.getErrorType() == NumberParseException.ErrorType.INVALID_COUNTRY_CODE
            && matcher.lookingAt()) {
        // Strip the plus-char, and try again.
        countryCode = maybeExtractCountryCode(nationalNumber.substring(matcher.end()),
                                              regionMetadata, normalizedNationalNumber,
                                              keepRawInput, phoneNumber);
        if (countryCode == 0) {
          throw new NumberParseException(NumberParseException.ErrorType.INVALID_COUNTRY_CODE,
                                         "Could not interpret numbers after plus-sign.");
        }
      } else {
        throw new NumberParseException(e.getErrorType(), e.getMessage());
      }
    }
    if (countryCode != 0) {
      String phoneNumberRegion = getRegionCodeForCountryCode(countryCode);
      if (!phoneNumberRegion.equals(defaultRegion)) {
        // Metadata cannot be null because the country calling code is valid.
        regionMetadata = getMetadataForRegionOrCallingCode(countryCode, phoneNumberRegion);
      }
    } else {
      // If no extracted country calling code, use the region supplied instead. The national number
      // is just the normalized version of the number we were given to parse.
      normalizedNationalNumber.append(normalize(nationalNumber));
      if (defaultRegion != null) {
        countryCode = regionMetadata.getCountryCode();
        phoneNumber.setCountryCode(countryCode);
      } else if (keepRawInput) {
        phoneNumber.clearCountryCodeSource();
      }
    }
    if (normalizedNationalNumber.length() < MIN_LENGTH_FOR_NSN) {
      throw new NumberParseException(NumberParseException.ErrorType.TOO_SHORT_NSN,
                                     "The string supplied is too short to be a phone number.");
    }
    if (regionMetadata != null) {
      StringBuilder carrierCode = new StringBuilder();
      StringBuilder potentialNationalNumber = new StringBuilder(normalizedNationalNumber);
      maybeStripNationalPrefixAndCarrierCode(potentialNationalNumber, regionMetadata, carrierCode);
      // We require that the NSN remaining after stripping the national prefix and carrier code be
      // long enough to be a possible length for the region. Otherwise, we don't do the stripping,
      // since the original number could be a valid short number.
      ValidationResult validationResult = testNumberLength(potentialNationalNumber, regionMetadata);
      if (validationResult != ValidationResult.TOO_SHORT
            && validationResult != ValidationResult.IS_POSSIBLE_LOCAL_ONLY
            && validationResult != ValidationResult.INVALID_LENGTH) {
        normalizedNationalNumber = potentialNationalNumber;
        if (keepRawInput && carrierCode.length() > 0) {
          phoneNumber.setPreferredDomesticCarrierCode(carrierCode.toString());
        }
      }
    }
    int lengthOfNationalNumber = normalizedNationalNumber.length();
    if (lengthOfNationalNumber < MIN_LENGTH_FOR_NSN) {
      throw new NumberParseException(NumberParseException.ErrorType.TOO_SHORT_NSN,
                                     "The string supplied is too short to be a phone number.");
    }
    if (lengthOfNationalNumber > MAX_LENGTH_FOR_NSN) {
      throw new NumberParseException(NumberParseException.ErrorType.TOO_LONG,
                                     "The string supplied is too long to be a phone number.");
    }
    setItalianLeadingZerosForPhoneNumber(normalizedNationalNumber, phoneNumber);
    phoneNumber.setNationalNumber(Long.parseLong(normalizedNationalNumber.toString()));
  }
  */
  
  // 3321
  /// Converts numberToParse to a form that we can parse and write it to nationalNumber if it is
  /// written in RFC3966; otherwise extract a possible number out of it and write to nationalNumber.
  private func buildNationalNumberForParsing(numberToParse: String, nationalNumber: inout String) {
    if let indexOfPhoneContext = numberToParse.range(of: Self.rfc3966PhoneContext)?.lowerBound {
      let phoneContextStart = numberToParse.index(indexOfPhoneContext, offsetBy: Self.rfc3966PhoneContext.count)
      // If the phone context contains a phone number prefix, we need to capture it, whereas domains
      // will be ignored.
      if ..<numberToParse.endIndex ~= phoneContextStart && numberToParse[phoneContextStart] == Self.plusSign {
        // Additional parameters might follow the phone context. If so, we will remove them here
        // because the parameters after phone context are not important for parsing the
        // phone number.
        if let phoneContextEnd = numberToParse.range(of: ";", range: phoneContextStart..<numberToParse.endIndex)?.lowerBound {
          nationalNumber += numberToParse[phoneContextStart...phoneContextEnd]
        } else {
          nationalNumber += numberToParse[phoneContextStart...]
        }
      }

      // Now append everything between the "tel:" prefix and the phone-context. This should include
      // the national number, an optional extension or isdn-subaddress component. Note we also
      // handle the case when "tel:" is missing, as we have seen in some of the phone number inputs.
      // In that case, we append everything from the beginning.
      let indexOfNationalNumber: String.Index
      if let indexOfRfc3966Prefix = numberToParse.range(of: Self.rfc3966Prefix)?.lowerBound {
        indexOfNationalNumber = numberToParse.index(indexOfRfc3966Prefix, offsetBy: Self.rfc3966Prefix.count)
      } else {
        indexOfNationalNumber = numberToParse.startIndex
      }
      nationalNumber += numberToParse[indexOfNationalNumber...indexOfPhoneContext]
    } else {
      // Extract a possible number from the string passed in (this strips leading characters that
      // could not be the start of a phone number.)
      nationalNumber.append(extractPossibleNumber(numberToParse))
    }

    // Delete the isdn-subaddress and everything after it if it is present. Note extension won't
    // appear at the same time with isdn-subaddress according to paragraph 5.3 of the RFC3966 spec,
    if let indexOfIsdn = nationalNumber.range(of: Self.rfc3966ISDNSubaddress)?.lowerBound {
      nationalNumber.removeSubrange(indexOfIsdn..<nationalNumber.endIndex)
    }
    // If both phone context and isdn-subaddress are absent but other parameters are present, the
    // parameters are left in nationalNumber. This is because we are concerned about deleting
    // content from a potential number string when there is no strong evidence that the number is
    // actually written in RFC3966.
  }
  
  // 3371
  /// Returns a new phone number containing only the fields needed to uniquely identify a phone
  /// number, rather than any fields that capture the context in which the phone number was created.
  /// These fields correspond to those set in parse() rather than parseAndKeepRawInput().
  private static func copyCoreFieldsOnly(phoneNumberIn: PhoneNumber) -> PhoneNumber {
    return PhoneNumber(
      countryCode: phoneNumberIn.countryCode,
      nationalNumber: phoneNumberIn.nationalNumber,
      extension: phoneNumberIn.extension,
      italianLeadingZero: phoneNumberIn.italianLeadingZero,
      numberOfLeadingZeros: phoneNumberIn.numberOfLeadingZeros,
      rawInput: "",
      countryCodeSource: .unspecified,
      preferredDomesticCarrierCode: nil,
      type: .unknown
    )
  }
}

#if canImport(CoreTelephony)
import CoreTelephony

extension CTTelephonyNetworkInfo {
  
  // The returned value is lowercased.
  func isoCountryCode() -> String? {
    guard #available(iOS 12.0, *) else {
      return subscriberCellularProvider?.isoCountryCode
    }
    guard let serviceSubscriberCellularProviders = serviceSubscriberCellularProviders else {
      return nil
    }
    if #available(iOS 13.0, *), let dataServiceIdentifier = dataServiceIdentifier {
      if let isoCountryCode = serviceSubscriberCellularProviders[dataServiceIdentifier]?.isoCountryCode {
        return isoCountryCode
      }
    }
    for carrier in serviceSubscriberCellularProviders.values {
      if let isoCountryCode = carrier.isoCountryCode {
        return isoCountryCode
      }
    }
    return nil
  }
}
#endif

extension PhoneNumberUtil {
  
  public static func defaultRegionCode() -> String {
    #if canImport(CoreTelephony)
    let networkInfo = CTTelephonyNetworkInfo()
    if let isoCountryCode = networkInfo.isoCountryCode() {
      return isoCountryCode.uppercased()
    }
    #endif
    return Locale.current.regionCode ?? PhoneNumberConstants.defaultRegionCode
  }
}
