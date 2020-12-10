//
//  RegexCache.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

final class RegexCache {

    final private class Key: Hashable {

        let pattern: String

        init(pattern: String) {
          self.pattern = pattern
        }

        static func == (lhs: Key, rhs: Key) -> Bool {
          return lhs.pattern == rhs.pattern
        }

        func hash(into hasher: inout Hasher) {
          hasher.combine(pattern)
        }
    }

    private let queue = DispatchQueue(label: "com.libphonenumber.regexcache.pool", attributes: .concurrent)
    private let cache = NSCache<Key, NSRegularExpression>()

    let spaceCharacterSet = CharacterSet(charactersIn: PhoneNumberConstants.nonBreakingSpace).union(.whitespacesAndNewlines)

    // MARK: Regular expression

    func regex(pattern: String) throws -> NSRegularExpression {
      try queue.sync {
        let key = Key(pattern: pattern)
        if let cachedObject = cache.object(forKey: key) {
          return cachedObject
        }
        
        let regularExpression = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        cache.setObject(regularExpression, forKey: key)
        return regularExpression
      }
    }

    func matchesByRegex(pattern: String, string: String) throws -> [NSTextCheckingResult] {
      return try regex(pattern: pattern).matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
    }

    func phoneDataDetectorMatch(_ string: String) throws -> NSTextCheckingResult {
        let fallBackMatches = try matchesByRegex(pattern: PhoneNumberPatterns.validPhoneNumberPattern, string: string)
        if let firstMatch = fallBackMatches.first {
            return firstMatch
        } else {
            throw PhoneNumberError.notANumber
        }
    }

    // MARK: Match helpers

    func matchesAtStartByRegex(pattern: String, string: String) -> Bool {
        if let matches = try? matchesByRegex(pattern: pattern, string: string) {
            for match in matches {
                if match.range.location == 0 {
                    return true
                }
            }
        }
        return false
    }

    func stringPositionByRegex(pattern: String, string: String) -> Int {
        if let match = try? matchesByRegex(pattern: pattern, string: string).first {
            return match.range.location
        }
        return -1
    }

    func matchesEntirelyByRegex(pattern: String?, string: String) -> Bool {
        guard var pattern = pattern else {
            return false
        }
        pattern = "^(\(pattern))$"
        do {
            let matches = try matchesByRegex(pattern: pattern, string: string)
            return matches.count > 0
        } catch {
            return false
        }
    }

    func matchedStringByRegex(pattern: String, string: String) -> [String] {
        var matchedStrings: [String] = []
        if let matches = try? matchesByRegex(pattern: pattern, string: string) {
            for match in matches {
                let processedString = string[match.range]
                matchedStrings.append(processedString)
            }
        }
        return matchedStrings
    }

    // MARK: String and replace

    func replaceStringByRegex(pattern: String, string: String) -> String {
        var replacementResult = string
        if let regex = try? regex(pattern: pattern) {
            let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
            if matches.count == 1 {
                let range = regex.rangeOfFirstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
                if range.length > 0 {
                    replacementResult = regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
                }
                return replacementResult
            } else if matches.count > 1 {
                replacementResult = regex.stringByReplacingMatches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count), withTemplate: "")
            }
        }
        return replacementResult
    }

    func replaceStringByRegex(pattern: String, string: String, template: String) -> String {
        var replacementResult = string
        if let regex = try? regex(pattern: pattern) {
            let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
            if matches.count == 1 {
                let range = regex.rangeOfFirstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
                if range.length > 0 {
                    replacementResult = regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
                }
                return replacementResult
            } else if matches.count > 1 {
                replacementResult = regex.stringByReplacingMatches(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count), withTemplate: template)
            }
        }
        return replacementResult
    }

    func replaceFirstStringByRegex(pattern: String, string: String, template: String) -> String {
        if let regex = try? regex(pattern: pattern) {
            let range = regex.rangeOfFirstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
            if range.length > 0 {
                return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
            }
            return string
        }
        return string
    }

    func stringByReplacingOccurrences(_ string: String, map: [String: String], keepUnmapped: Bool = false) -> String {
        var targetString = String()
        for i in 0..<string.count {
            let oneChar = string[string.index(string.startIndex, offsetBy: i)]
            let keyString = String(oneChar).uppercased()
            if let mappedValue = map[keyString] {
                targetString.append(mappedValue)
            } else if keepUnmapped {
                targetString.append(keyString)
            }
        }
        return targetString
    }

    // MARK: Validations

    func hasValue(_ value: String?) -> Bool {
        if let value = value {
            return !value.trimmingCharacters(in: spaceCharacterSet).isEmpty
        }
        return false
    }

    func testStringLengthAgainstPattern(pattern: String, string: String) -> Bool {
        return matchesEntirelyByRegex(pattern: pattern, string: string)
    }
}
