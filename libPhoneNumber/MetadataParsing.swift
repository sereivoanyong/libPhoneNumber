//
//  MetadataParsing.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

// MARK: - Parsing helpers

extension KeyedDecodingContainer {
  
    /// Decodes a string to a boolean. Returns false if empty.
    ///
    /// - Parameter key: Coding key to decode
    func decodeStringBoolIfPresent(forKey key: Key) throws -> Bool? {
        if let string = try decodeIfPresent(String.self, forKey: key) {
            switch string {
            case "true":  return true
            case "false": return false
            default:      return nil
            }
        }
        return nil
    }

    /// Decodes either a single object or an array into an array. Returns an empty array if empty.
    ///
    /// - Parameter key: Coding key to decode
    func decodeArrayOrObject<T: Decodable>(forKey key: Key) -> [T] {
        if let array = try? decode([T].self, forKey: key) {
            return array
        }
        if let object = try? decode(T.self, forKey: key) {
            return [object]
        }
        return []
    }
}
