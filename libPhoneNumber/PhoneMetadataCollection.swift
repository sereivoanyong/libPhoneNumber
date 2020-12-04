//
//  PhoneMetadataCollection.swift
//
//  Created by Sereivoan Yong on 12/4/20.
//

import Foundation

struct PhoneMetadataCollection: Decodable {
  
  let territories: [PhoneMetadata]
  
  private enum CodingKeys: String, CodingKey {
    
    case phoneNumberMetadata
    case territories
    case territory
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let metadataObject = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .phoneNumberMetadata)
    let territoryObject = try metadataObject.nestedContainer(keyedBy: CodingKeys.self, forKey: .territories)
    territories = try territoryObject.decode([PhoneMetadata].self, forKey: .territory)
  }
}
