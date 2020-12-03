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

        static func == (lhs: RegexCache.Key, rhs: RegexCache.Key) -> Bool {
          return lhs.pattern == rhs.pattern
        }

        func hash(into hasher: inout Hasher) {
          hasher.combine(pattern)
        }
    }

    private let queue = DispatchQueue(label: "com.phonenumberkit.regexpool", attributes: .concurrent)
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

    func matchesAtStart(_ pattern: String, string: String) -> Bool {
        if let matches = try? matchesByRegex(pattern: pattern, string: string) {
            for match in matches {
                if match.range.location == 0 {
                    return true
                }
            }
        }
        return false
    }

    func stringPositionByRegex(_ pattern: String, string: String) -> Int {
        if let match = try? matchesByRegex(pattern: pattern, string: string).first {
            return match.range.location
        }
        return -1
    }

    func matchesEntirely(_ pattern: String?, string: String) -> Bool {
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

    func matchedStringByRegex(_ pattern: String, string: String) -> [String] {
        var matchedStrings: [String] = []
        if let matches = try? matchesByRegex(pattern: pattern, string: string) {
            for match in matches {
                let processedString = string.substring(with: match.range)
                matchedStrings.append(processedString)
            }
        }
        return matchedStrings
    }

    // MARK: String and replace

    func replaceStringByRegex(_ pattern: String, string: String) -> String {
        var replacementResult = string
        if let regex = try? self.regex(pattern: pattern) {
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

    func replaceStringByRegex(_ pattern: String, string: String, template: String) -> String {
        var replacementResult = string
        if let regex = try? self.regex(pattern: pattern) {
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

    func replaceFirstStringByRegex(_ pattern: String, string: String, templateString: String) -> String {
        do {
            let regex = try self.regex(pattern: pattern)
            let range = regex.rangeOfFirstMatch(in: string, options: [], range: NSRange(location: 0, length: string.utf16.count))
            if range.length > 0 {
                return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: templateString)
            }
            return string
        } catch {
            return String()
        }
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

    func testStringLengthAgainstPattern(_ pattern: String, string: String) -> Bool {
        return matchesEntirely(pattern, string: string)
    }
}

// MARK: Extensions

extension String {
    @inlinable func substring(with range: NSRange) -> String {
        return (self as NSString).substring(with: range)
    }
}
