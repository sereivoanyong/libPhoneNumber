//
//  PhoneNumberParseError.swift
//
//  Created by Sereivoan Yong on 12/8/20.
//

import Foundation

// A.k.a `NumberParseException`

public enum PhoneNumberParseError: Error {
  
  /// The country code supplied did not belong to a supported country or non-geographical entity.
  case invalidCountryCode
  
  /// This generally indicates the string passed in had less than 3 digits in it. More
  /// specifically, the number failed to match the regular expression `validPhoneNumber` in
  /// `PhoneNumberUtil`.
  case notANumber(String)
  
  /// This indicates the string started with an international dialing prefix, but after this was
  /// stripped from the number, had less digits than any valid phone number (including country
  /// code) could have.
  case tooShortAfterIDD
  
  /// This indicates the string, after any country code has been stripped, had less digits than any
  /// valid phone number could have.
  case tooShortNSN
  
  /// This indicates the string had more digits than any valid phone number could have.
  case tooLong(String)
}
