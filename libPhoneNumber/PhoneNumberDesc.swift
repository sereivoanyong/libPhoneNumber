//
//  PhoneNumberDesc.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

public struct PhoneNumberDesc: Decodable {
  
  public let exampleNumber: String?
  public let nationalNumberPattern: String?
  public let possibleNumberPattern: String?
  public let possibleLengths: PhoneNumberPossibleLengths?
}

public struct PhoneNumberPossibleLengths: Decodable {
  
  public let national: String?
  public let localOnly: String?
}
