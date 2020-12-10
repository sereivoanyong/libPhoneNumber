//
//  Constants.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

// MARK: Public Enums

/**
 Enumeration for parsing error types

 - InvalidCountryCode: A country code could not be found or the one found was invalid
 - NotANumber: The string provided is not a number
 - TooLong: The string provided is too long to be a valid number
 - TooShort: The string provided is too short to be a valid number
 */
public enum PhoneNumberError: Error {
    case invalidCountryCode
    case notANumber
    case unknownType
    case tooLong
    case tooShort
}

extension PhoneNumberError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidCountryCode: return NSLocalizedString("The country code is invalid.", comment: "")
        case .notANumber: return NSLocalizedString("The number provided is invalid.", comment: "")
        case .unknownType: return NSLocalizedString("Phone number type is unknown.", comment: "")
        case .tooLong: return NSLocalizedString("The number provided is too long.", comment: "")
        case .tooShort: return NSLocalizedString("The number provided is too short.", comment: "")
        }
    }
}

/// `international` and `national` formats are consistent with the definition in ITU-T Recommendation
/// E.123. However we follow local conventions such as using '-' instead of whitespace as
/// separators. For example, the number of the Google Switzerland office will be written as
/// "+41 44 668 1800" in `international` format, and as "044 668 1800" in `national` format. `e164`
/// format is as per `international` format but with no formatting applied, e.g. "+41446681800".
/// `rfc3966` is as per `international` format, but with all spaces and other separating symbols
/// replaced with a hyphen, and with any phone number extension appended with ";ext=". It also
/// will have a prefix of "tel:" added, e.g. "tel:+41-44-668-1800".
///
/// Note: If you are considering storing the number in a neutral format, you are highly advised to
/// use the `PhoneNumber` class.
public enum PhoneNumberFormat {
  
  case e164 // +41446681800
  
  case international // +41 44 668 1800
  
  case national // 044 668 1800
  
  case rfc3966 // tel:+41-44-668-1800
}

/// Type of phone numbers.
public enum PhoneNumberType {
  
  case fixedLine
  
  case mobile
  
  /// In some regions (e.g. the USA), it is impossible to distinguish between `fixedLine` and
  /// `mobile` numbers by looking at the phone number itself.
  case fixedLineOrMobile
  
  /// Freephone lines
  case tollFree
  
  case premiumRate
  
  /// The cost of this call is shared between the caller and the recipient, and is hence typically
  /// less than `premiumRate` calls. See http://en.wikipedia.org/wiki/Shared_Cost_Service for
  /// more information.
  case sharedCost
  
  /// Voice over IP numbers. This includes TSoIP (Telephony Service over IP).
  case voip
  
  /// A personal number is associated with a particular person, and may be routed to either a
  /// `mobile` or `fixedLine` number. Some more information can be found here:
  /// http://en.wikipedia.org/wiki/Personal_Numbers
  case personalNumber
  
  case pager
  
  /// Used for "Universal Access Numbers" or "Company Numbers". They may be further routed to
  /// specific offices, but allow one number to be used for a company.
  case uan
  
  /// Used for "Voice Mail Access Numbers".
  case voicemail
  
  /// A phone number is of type `unknown` when it does not fit any of the known patterns for a
  /// specific region.
  case unknown
}

/// Types of phone number matches. See detailed description beside the `isNumberMatch()` method.
public enum MatchType {
  
  case notANumber
  case noMatch
  case shortNSNMatch
  case nsnMatch
  case exactMatch
}

/// Possible outcomes when testing if a `PhoneNumber` is possible.
public enum ValidationResult {
  
  /// The number length matches that of valid numbers for this region.
  case isPossible
  
  /// The number length matches that of local numbers for this region only (i.e. numbers that may
  /// be able to be dialled within an area, but do not have all the information to be dialled from
  /// anywhere inside or outside the country).
  case isPossibleLocalOnly
  
  /// The number has an invalid country calling code.
  case invalidCountryCode
  
  /// The number is shorter than all valid numbers for this region.
  case tooShort
  
  /// The number is longer than the shortest valid numbers for this region, shorter than the
  /// longest valid numbers for this region, and does not itself have a number length that matches
  /// valid numbers for this region. This can also be returned in the case where
  /// isPossibleNumberForTypeWithReason was called, and there are no numbers of this type at all
  /// for this region.
  case invalidLength
  
  /// The number is longer than all valid numbers for this region.
  case tooLong
}

public enum PhoneNumberPossibleLengthType {
  
  case national
  case localOnly
}

// MARK: Constants

struct PhoneNumberConstants {
    static let defaultRegionCode = "US"
    static let defaultExtnPrefix = " ext. "
    static let longPhoneNumber = "999999999999999"
    static let nonBreakingSpace = "\u{00a0}"
    static let plusChars = "+＋"
    static let pausesAndWaitsChars = ",;"
    static let operatorChars = "*#"
    static let validDigitsString = "0-9０-９٠-٩۰-۹"
    static let digitPlaceholder = "\u{2008}"
    static let separatorBeforeNationalNumber = " "
}

struct PhoneNumberPatterns {
    // MARK: Patterns

    static let firstGroupPattern = "(\\$\\d)"
    static let fgPattern = "\\$FG"
    static let npPattern = "\\$NP"

    static let allNormalizationMappings = ["0":"0", "1":"1", "2":"2", "3":"3", "4":"4", "5":"5", "6":"6", "7":"7", "8":"8", "9":"9", "٠":"0", "١":"1", "٢":"2", "٣":"3", "٤":"4", "٥":"5", "٦":"6", "٧":"7", "٨":"8", "٩":"9", "۰":"0", "۱":"1", "۲":"2", "۳":"3", "۴":"4", "۵":"5", "۶":"6", "۷":"7", "۸":"8", "۹":"9", "*":"*", "#":"#", ",":",", ";":";"]
    static let capturingDigitPattern = "([0-9０-９٠-٩۰-۹])"

    static let extnPattern = "(?:;ext=([0-9０-９٠-٩۰-۹]{1,7})|[  \\t,]*(?:e?xt(?:ensi(?:ó?|ó))?n?|ｅ?ｘｔｎ?|[,xｘX#＃~～;]|int|anexo|ｉｎｔ)[:\\.．]?[  \\t,-]*([0-9０-９٠-٩۰-۹]{1,7})#?|[- ]+([0-9０-９٠-٩۰-۹]{1,5})#)$"

    static let iddPattern = "^(?:\\+|%@)"

    static let formatPattern = "^(?:%@)$"

    static let characterClassPattern = "\\[([^\\[\\]])*\\]"

    static let standaloneDigitPattern = "\\d(?=[^,}][^,}])"

    static let nationalPrefixParsingPattern = "^(?:%@)"

    static let prefixSeparatorPattern = "[- ]"

    static let eligibleAsYouTypePattern = "^[-x‐-―−ー－-／ ­​⁠　()（）［］.\\[\\]/~⁓∼～]*(\\$\\d[-x‐-―−ー－-／ ­​⁠　()（）［］.\\[\\]/~⁓∼～]*)+$"

    static let leadingPlusCharsPattern = "^[+＋]+"

    static let secondNumberStartPattern = "[\\\\\\/] *x"

    static let unwantedEndPattern = "[^0-9０-９٠-٩۰-۹A-Za-z#]+$"

    static let validStartPattern = "[+＋0-9０-９٠-٩۰-۹]"

    static let validPhoneNumberPattern = "^[0-9０-９٠-٩۰-۹]{2}$|^[+＋]*(?:[-x\u{2010}-\u{2015}\u{2212}\u{30FC}\u{FF0D}-\u{FF0F} \u{00A0}\u{00AD}\u{200B}\u{2060}\u{3000}()\u{FF08}\u{FF09}\u{FF3B}\u{FF3D}.\\[\\]/~\u{2053}\u{223C}\u{FF5E}*]*[0-9\u{FF10}-\u{FF19}\u{0660}-\u{0669}\u{06F0}-\u{06F9}]){3,}[-x\u{2010}-\u{2015}\u{2212}\u{30FC}\u{FF0D}-\u{FF0F} \u{00A0}\u{00AD}\u{200B}\u{2060}\u{3000}()\u{FF08}\u{FF09}\u{FF3B}\u{FF3D}.\\[\\]/~\u{2053}\u{223C}\u{FF5E}*A-Za-z0-9\u{FF10}-\u{FF19}\u{0660}-\u{0669}\u{06F0}-\u{06F9}]*(?:(?:;ext=([0-9０-９٠-٩۰-۹]{1,7})|[  \\t,]*(?:e?xt(?:ensi(?:ó?|ó))?n?|ｅ?ｘｔｎ?|[,xｘX#＃~～;]|int|anexo|ｉｎｔ)[:\\.．]?[  \\t,-]*([0-9０-９٠-٩۰-۹]{1,7})#?|[- ]+([0-9０-９٠-٩۰-۹]{1,5})#)?$)?[,;]*$"
}