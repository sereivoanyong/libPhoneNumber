//
//  File.swift
//
//  Created by Sereivoan Yong on 12/10/20.
//

import Foundation

/// Implementation of the matcher API using the regular expressions in the `PhoneNumberDesc`
/// proto message to match numbers.
final public class RegexBasedMatcher: MatcherAPI {
  
  public init() {
  }
  
  private let regexCache = RegexCache()
  
  public func matchNationalNumber(_ number: String, numberDesc: PhoneNumberDesc?, allowPrefixMatch: Bool) -> Bool {
    // We don't want to consider it a prefix match when matching non-empty input against an empty
    // pattern.
    guard let nationalNumberPattern = numberDesc?.nationalNumberPattern, !nationalNumberPattern.isEmpty else {
      return false
    }
    return Self.match(number, regex: try! regexCache.regex(pattern: nationalNumberPattern), allowPrefixMatch: allowPrefixMatch)
  }
  
  private static func match(_ number: String, regex: NSRegularExpression, allowPrefixMatch: Bool) -> Bool {
    if regex.firstMatch(in: number, options: .anchored) == nil {
      return false
    } else {
      return regex.firstMatch(in: number) != nil ? true : allowPrefixMatch
    }
  }
}
