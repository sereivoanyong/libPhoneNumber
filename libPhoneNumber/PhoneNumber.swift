//
//  PhoneNumber.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

public struct PhoneNumber: Hashable {
  
  public enum CountryCodeSource: Int {
    
    case fromNumberWithPlusSign = 1
    case fromNumberWithIDD = 5
    case fromNumberWithoutPlusSign = 10
    case fromDefaultCountry = 20
    case unspecified = 0
  }
  
  public let countryCode: Int32
  public let nationalNumber: UInt64
  public let `extension`: String?
  public let italianLeadingZero: Bool
  public let numberOfLeadingZeros: Int
  public let rawInput: String
  public let countryCodeSource: CountryCodeSource
  public let preferredDomesticCarrierCode: String?
  
  public let type: PhoneNumberType
}

public extension PhoneNumber {
    /**
     Adjust national number for display by adding leading zero if needed. Used for basic formatting functions.
     - Returns: A string representing the adjusted national number.
     */
    func adjustedNationalNumber() -> String {
        if italianLeadingZero {
            return "0" + String(nationalNumber)
        } else {
            return String(nationalNumber)
        }
    }
}
