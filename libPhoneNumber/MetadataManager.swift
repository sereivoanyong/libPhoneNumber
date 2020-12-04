//
//  MetadataManager.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

import Foundation

struct MetadataManager {
  
  let metadataByRegionCode: [String: PhoneMetadata]
  let metadataByCountryCode: [Int32: PhoneMetadata]
  let metadatasByCountryCode: [Int32: [PhoneMetadata]] // Will be deprecated
  
  init() {
    let metadatas = (try? Self.metadatasFromResource(name: "PhoneNumberMetadata", extension: "json")) ?? []
    var metadataByRegionCode: [String: PhoneMetadata] = [:]
    var metadataByCountryCode: [Int32: PhoneMetadata] = [:]
    var metadatasByCountryCode: [Int32: [PhoneMetadata]] = [:]
    for metadata in metadatas {
      metadataByRegionCode[metadata.regionCode] = metadata
      if metadata.mainCountryForCode || metadataByCountryCode[metadata.countryCode] == nil {
        metadataByCountryCode[metadata.countryCode] = metadata
      }
      // In the case of multiple countries sharing a calling code, such as the NANPA countries,
      // the one indicated with "isMainCountryForCode" in the metadata should be first.
      if metadata.mainCountryForCode {
        metadatasByCountryCode[metadata.countryCode, default: []].insert(metadata, at: 0)
      } else {
        metadatasByCountryCode[metadata.countryCode, default: []].append(metadata)
      }
    }
    self.metadataByRegionCode = metadataByRegionCode
    self.metadataByCountryCode = metadataByCountryCode
    self.metadatasByCountryCode = metadatasByCountryCode
  }
  
  func metadata(forRegionCode regionCode: String) -> PhoneMetadata? {
    return metadataByRegionCode[regionCode]
  }
  
  func metadataForNonGeographicalRegion(forCountryCode countryCode: Int32) -> PhoneMetadata? {
    return metadataByCountryCode[countryCode]
  }
  
  private static func metadatasFromResource(name: String, extension: String, bundle: Bundle = .module) throws -> [PhoneMetadata] {
    guard let url = bundle.url(forResource: name, withExtension: `extension`) else {
      throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "missing metadata: \(name).\(`extension`)"])
    }
    let metadataCollection = try loadMetadataCollection(from: url)
    if metadataCollection.metadatas.isEmpty {
      throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "empty metadata: \(name).\(`extension`)"])
    }
    return metadataCollection.metadatas
  }
  
  private static func loadMetadataCollection(from url: URL) throws -> PhoneMetadataCollection {
    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "cannot load metadata: \(error.localizedDescription)"])
    }
    let decoder = JSONDecoder()
    do {
      let metadataCollection = try decoder.decode(PhoneMetadataCollection.self, from: data)
      return metadataCollection
    } catch {
      throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "cannot decode metadata: \(error.localizedDescription)"])
    }
  }
}
