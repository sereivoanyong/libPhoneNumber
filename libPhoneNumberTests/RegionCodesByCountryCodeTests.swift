//
//  RegionCodesByCountryCodeTests.swift
//
//  Created by Sereivoan Yong on 12/4/20.
//

@testable import libPhoneNumber
import XCTest

class RegionCodesByCountryCodeTests: XCTestCase {
  
  let util = PhoneNumberUtil()
  
  func testMetadataManager() {
    var managerRegionCodes = Set(util.metadataManager.metadataByRegionCode.keys)
    managerRegionCodes.remove(PhoneNumberUtil.regionCodeForNonGeoEntity)
    let bb = Set(util.metadataManager.metadatasByCountryCode.values.flatMap { $0 }.map { $0.regionCode })
    print(bb)
    XCTAssertEqual(util.supportedRegionCodes, managerRegionCodes)
  }
  
  func testRegionCodes() {
    let localeRegionCodeArray = Locale.isoRegionCodes
    let localeRegionCodeSet = Set<String>(localeRegionCodeArray)
    XCTAssertEqual(localeRegionCodeArray.count, localeRegionCodeSet.count)
    
    let regionCodeArray = RegionCodesByCountryCode.regionCodesByCountryCode().values.flatMap { $0 }
    var regionCodeSet = Set<String>(regionCodeArray)
    regionCodeSet.remove(PhoneNumberUtil.regionCodeForNonGeoEntity)
    XCTAssertTrue(regionCodeSet.isSubset(of: localeRegionCodeSet))
  }
  
  func testMetadata() {
    let regionCodeArray = RegionCodesByCountryCode.regionCodesByCountryCode().values.flatMap { $0 }
    var regionCodeSet = Set<String>(regionCodeArray)
    regionCodeSet.remove(PhoneNumberUtil.regionCodeForNonGeoEntity)
    for regionCode in regionCodeSet {
      XCTAssertNotNil(util.metadata(forRegionCode: regionCode))
    }
  }
}
