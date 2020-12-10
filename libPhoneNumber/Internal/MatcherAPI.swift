//
//  MatcherApi.swift
//
//  Created by Sereivoan Yong on 12/10/20.
//

import Foundation

/// Internal phonenumber matching API used to isolate the underlying implementation of the
/// matcher and allow different implementations to be swapped in easily.
public protocol MatcherAPI: AnyObject {
  
  /// Returns whether the given national number (a string containing only decimal digits) matches
  /// the national number pattern defined in the given `PhoneNumberDesc` message.
  func matchNationalNumber(_ number: String, numberDesc: PhoneNumberDesc?, allowPrefixMatch: Bool) -> Bool
}
