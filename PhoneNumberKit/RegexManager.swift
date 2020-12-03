//
//  RegexManager.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 04/10/2015.
//  Copyright © 2020 Roy Marmelstein. All rights reserved.
//

import Foundation

final class RegexManager {

    private let queue = DispatchQueue(label: "com.phonenumberkit.regexpool", attributes: .concurrent)
    private let cache = NSCache<NSString, NSRegularExpression>()

    let spaceCharacterSet: CharacterSet = {
        var characterSet = CharacterSet(charactersIn: "\u{00a0}")
        characterSet.formUnion(.whitespacesAndNewlines)
        return characterSet
    }()

    // MARK: Regular expression

    func regex(pattern: String) throws -> NSRegularExpression {
      try queue.sync {
        let key = pattern as NSString
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
        do {
            let matches = try matchesByRegex(pattern: pattern, string: string)
            for match in matches {
                if match.range.location == 0 {
                    return true
                }
            }
        } catch {}
        return false
    }

    func stringPositionByRegex(_ pattern: String, string: String) -> Int {
        do {
            let matches = try matchesByRegex(pattern: pattern, string: string)
            if let match = matches.first {
                return match.range.location
            }
            return -1
        } catch {
            return -1
        }
    }

    func matchesExist(_ pattern: String?, string: String) -> Bool {
        guard let pattern = pattern else {
            return false
        }
        do {
            let matches = try matchesByRegex(pattern: pattern, string: string)
            return matches.count > 0
        } catch {
            return false
        }
    }

    func matchesEntirely(_ pattern: String?, string: String) -> Bool {
        guard var pattern = pattern else {
            return false
        }
        pattern = "^(\(pattern))$"
        return self.matchesExist(pattern, string: string)
    }

    func matchedStringByRegex(_ pattern: String, string: String) throws -> [String] {
        do {
            let matches = try matchesByRegex(pattern: pattern, string: string)
            var matchedStrings = [String]()
            for match in matches {
                let processedString = string.substring(with: match.range)
                matchedStrings.append(processedString)
            }
            return matchedStrings
        } catch {}
        return []
    }

    // MARK: String and replace

    func replaceStringByRegex(_ pattern: String, string: String) -> String {
        do {
            var replacementResult = string
            let regex = try self.regex(pattern: pattern)
            let matches = regex.matches(in: string)
            if matches.count == 1 {
                let range = regex.rangeOfFirstMatch(in: string)
                if range != nil {
                    replacementResult = regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
                }
                return replacementResult
            } else if matches.count > 1 {
                replacementResult = regex.stringByReplacingMatches(in: string, withTemplate: "")
            }
            return replacementResult
        } catch {
            return string
        }
    }

    func replaceStringByRegex(_ pattern: String, string: String, template: String) -> String {
        do {
            var replacementResult = string
            let regex = try self.regex(pattern: pattern)
            let matches = regex.matches(in: string)
            if matches.count == 1 {
                let range = regex.rangeOfFirstMatch(in: string)
                if range != nil {
                    replacementResult = regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: template)
                }
                return replacementResult
            } else if matches.count > 1 {
                replacementResult = regex.stringByReplacingMatches(in: string, withTemplate: template)
            }
            return replacementResult
        } catch {
            return string
        }
    }

    func replaceFirstStringByRegex(_ pattern: String, string: String, templateString: String) -> String {
        do {
            let regex = try self.regex(pattern: pattern)
            let range = regex.rangeOfFirstMatch(in: string)
            if range != nil {
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
        if let valueString = value {
            if valueString.trimmingCharacters(in: spaceCharacterSet).count == 0 {
                return false
            }
            return true
        } else {
            return false
        }
    }

    func testStringLengthAgainstPattern(_ pattern: String, string: String) -> Bool {
        if self.matchesEntirely(pattern, string: string) {
            return true
        } else {
            return false
        }
    }
}

// MARK: Extensions

extension String {
    func substring(with range: NSRange) -> String {
        let nsString = self as NSString
        return nsString.substring(with: range)
    }
}
