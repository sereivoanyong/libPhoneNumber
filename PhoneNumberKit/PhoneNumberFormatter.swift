//
//  PhoneNumberFormatter.swift
//  PhoneNumberKit
//
//  Created by Jean-Daniel.
//  Copyright © 2019 Xenonium. All rights reserved.
//

import Foundation

open class PhoneNumberFormatter: Foundation.Formatter {
    public let phoneNumberKit: PhoneNumberKit

    private let partialFormatter: PartialFormatter

    // We declare all properties as @objc, so we can configure them though IB (using custom property)
    @objc public dynamic var generatesPhoneNumber: Bool = false

    /// Override region to set a custom region. Automatically uses the default region code.
    @objc public dynamic var defaultRegion: String {
        get { return partialFormatter.defaultRegion }
        set { partialFormatter.defaultRegion = newValue }
    }

    @objc public dynamic var withPrefix: Bool {
        get { return partialFormatter.withPrefix }
        set { partialFormatter.withPrefix = newValue }
    }

    @objc public dynamic var currentRegion: String {
        return partialFormatter.currentRegion
    }

    // MARK: Lifecycle

    public init(phoneNumberKit: PhoneNumberKit = PhoneNumberKit(), defaultRegion: String = PhoneNumberKit.defaultRegionCode(), withPrefix: Bool = true) {
        self.phoneNumberKit = phoneNumberKit
        self.partialFormatter = PartialFormatter(phoneNumberKit: phoneNumberKit, defaultRegion: defaultRegion, withPrefix: withPrefix)
        super.init()
    }

    public required init?(coder: NSCoder) {
        phoneNumberKit = PhoneNumberKit()
        partialFormatter = PartialFormatter(phoneNumberKit: phoneNumberKit, defaultRegion: PhoneNumberKit.defaultRegionCode(), withPrefix: true)
        super.init(coder: coder)
    }

    open func partialString(from string: String) -> String {
        return partialFormatter.formatPartial(string)
    }

    open func string(from phoneNumber: PhoneNumber) -> String {
        return phoneNumberKit.format(phoneNumber, toType: withPrefix ? .international : .national)
    }

    open func phoneNumber(from string: String) -> PhoneNumber? {
        return try? phoneNumberKit.parse(string, regionCode: currentRegion)
    }
}

// MARK: -

// MARK: NSFormatter implementation

extension PhoneNumberFormatter {
    open override func string(for object: Any?) -> String? {
        if let phoneNumber = object as? PhoneNumber {
            return string(from: phoneNumber)
        }
        if let string = object as? String {
            return partialString(from: string)
        }
        return nil
    }

    open override func getObjectValue(_ object: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        if generatesPhoneNumber {
            do {
                object?.pointee = try phoneNumberKit.parse(string) as AnyObject?
                return true
            } catch {
                errorDescription?.pointee = error.localizedDescription as NSString
                return false
            }
        } else {
            object?.pointee = string as NSString
            return true
        }
    }

    // MARK: Phone number formatting

    /**
     *  To keep the cursor position, we find the character immediately after the cursor and count the number of times it repeats in the remaining string as this will remain constant in every kind of editing.
     */
    private struct CursorPosition {
        let numberAfterCursor: unichar
        let repetitionCountFromEnd: Int
    }

    private func extractCursorPosition(string: NSString, selectedRange: NSRange) -> CursorPosition? {
        var repetitionCountFromEnd = 0

        // The selection range is based on NSString representation
        var cursorEnd = selectedRange.location + selectedRange.length

        guard cursorEnd < string.length else {
            // Cursor at end of string
            return nil
        }

        // Get the character after the cursor
        var char: unichar
        repeat {
            char = string.character(at: cursorEnd) // should work even if char is start of compound sequence
            cursorEnd += 1
            // We consider only digit as other characters may be inserted by the formatter (especially spaces)
        } while !char.isDigit() && cursorEnd < string.length

        guard cursorEnd < string.length else {
            // Cursor at end of string
            return nil
        }

        // Look for the next valid number after the cursor, when found return a CursorPosition struct
        for i in cursorEnd..<string.length {
            if string.character(at: i) == char {
                repetitionCountFromEnd += 1
            }
        }
        return CursorPosition(numberAfterCursor: char, repetitionCountFromEnd: repetitionCountFromEnd)
    }

    private enum Action {
        case insert
        case replace
        case delete
    }

    private func action(for origString: NSString, range: NSRange, proposedString: NSString, proposedRange: NSRange) -> Action {
        // If origin range length > 0, this is a delete or replace action
        if range.length == 0 {
            return .insert
        }

        // If proposed length = orig length - orig range length -> this is delete action
        if origString.length - range.length == proposedString.length {
            return .delete
        }
        // If proposed length > orig length - orig range length -> this is replace action
        return .replace
    }

    open override func isPartialStringValid(
        _ partialString: AutoreleasingUnsafeMutablePointer<NSString>,
        proposedSelectedRange: NSRangePointer?,
        originalString: String,
        originalSelectedRange: NSRange,
        errorDescription: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        guard let proposedSelectedRange = proposedSelectedRange else {
            // I guess this is an annotation issue. I can't see a valid case where the pointer can be null
            return true
        }

        // We want to allow space deletion or insertion
        let originalString = originalString as NSString
        let action = self.action(for: originalString, range: originalSelectedRange, proposedString: partialString.pointee, proposedRange: proposedSelectedRange.pointee)
        if action == .delete && originalString.isWhitespace(in: originalSelectedRange) {
            // Deleting white space
            return true
        }

        // Also allow to add white space ?
        if action == .insert || action == .replace {
            // Determine the inserted text range. This is the range starting at orig selection index and with length = ∆length
            let length = partialString.pointee.length - originalString.length + originalSelectedRange.length
            if partialString.pointee.isWhitespace(in: NSRange(location: originalSelectedRange.location, length: length)) {
                return true
            }
        }

        let text = partialString.pointee
        let formattedNationalNumber = partialFormatter.formatPartial(text as String) as NSString
        guard formattedNationalNumber != text else {
            // No change, no need to update the text
            return true
        }

        // Fix selection

        // The selection range is based on NSString representation
        if let cursor = extractCursorPosition(string: partialString.pointee, selectedRange: proposedSelectedRange.pointee) {
            var remaining = cursor.repetitionCountFromEnd
            for i in stride(from: formattedNationalNumber.length - 1, through: 0, by: -1) {
                if formattedNationalNumber.character(at: i) == cursor.numberAfterCursor {
                    if remaining > 0 {
                        remaining -= 1
                    } else {
                        // We are done
                        proposedSelectedRange.pointee = NSRange(location: i, length: 0)
                        break
                    }
                }
            }
        } else {
            // assume the pointer is at end of string
            proposedSelectedRange.pointee = NSRange(location: formattedNationalNumber.length, length: 0)
        }

        partialString.pointee = formattedNationalNumber as NSString
        return false
    }
}

private extension NSString {
    final func isWhitespace(in range: NSRange) -> Bool {
        return rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.inverted, options: [.literal], range: range).location == NSNotFound
    }
}

private extension unichar {
    func isDigit() -> Bool {
        return self >= 0x30 && self <= 0x39 // '0' < '9'
    }
}
