//
//  PhoneNumberUtilTests.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

@testable import libPhoneNumber
import XCTest

class PhoneNumberUtilTests: XCTestCase {

    let util = PhoneNumberUtil()

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMetadataMainCountryFetch() {
        let countryMetadata = util.metadataManager.metadataByCountryCode[1]
        XCTAssertEqual(countryMetadata?.regionCode, "US")
    }

    func testMetadataMainCountryFunction() {
        let countryName = util.regionCode(forCountryCode: 1)!
        XCTAssertEqual(countryName, "US")
        let invalidCountry = util.regionCode(forCountryCode: 992322)
        XCTAssertNil(invalidCountry)
    }

    // Invalid american number, GitHub issue #8 by j-pk
    func testInvalidNumberE() {
        do {
            let phoneNumber = try util.parse("202 00e 0000", regionCode: "US")
            print(util.format(phoneNumber, format: .e164))
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    // Valid indian number, GitHub issue #235
    func testValidNumber6() {
        do {
            let phoneNumber = try util.parse("6297062979", regionCode: "IN")
            print(util.format(phoneNumber, format: .e164))
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    // Bool checker, GitHub issue #325
    func testValidNumberBool() {
        XCTAssert(util.isValidPhoneNumber("6297062979", regionCode: "IN"))
        XCTAssertFalse(util.isValidPhoneNumber("202 00e 0000", regionCode: "US"))
    }

    // Invalid american number, GitHub issue #9 by lobodin
    func testAmbiguousFixedOrMobileNumber() {
        do {
            let phoneNumber = try util.parse("+16307792428", regionCode: "US")
            print(util.format(phoneNumber, format: .e164))
            let type = phoneNumber.type
            XCTAssertEqual(type, PhoneNumberType.fixedLineOrMobile)
        } catch {
            XCTFail()
        }
    }

    // Invalid UK number, GitHub pr by dulaccc
    func testInvalidGBNumbers() {
        do {
            // libphonenumber reports this number as invalid
            // and it's true, this is a French mobile number combined with the GB region
            let phoneNumber = try util.parse("+44629996885")
            print(util.format(phoneNumber, format: .e164))
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    // Invalid BE number, GitHub pr by dulaccc
    func testInvalidBENumbers() {
        do {
            // libphonenumber reports this number as invalid
            // and it's true, this is a French mobile number combined with the BE region
            let phoneNumber = try util.parse("+32910853865")
            print(util.format(phoneNumber, format: .e164))
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    // Invalid DZ number, GitHub pr by dulaccc
    func testInvalidDZNumbers() {
        do {
            // libphonenumber reports this number as invalid
            // and it's true, this is a French mobile number combined with the DZ region
            let phoneNumber = try util.parse("+21373344376")
            print(util.format(phoneNumber, format: .e164))
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    // Invalid CN number, GitHub pr by dulaccc
    func testInvalidCNNumbers() {
        do {
            // libphonenumber reports this number as invalid
            // and it's true, this is a French mobile number combined with the CN region
            let phoneNumber = try util.parse("+861500376135")
            print(util.format(phoneNumber, format: .e164))
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    // Invalid IT number, GitHub pr by dulaccc
    func testInvalidITNumbers() {
        do {
            // libphonenumber reports this number as invalid
            // and it's true, this is a French mobile number combined with the IT region
            let phoneNumber = try util.parse("+390762613915")
            print(util.format(phoneNumber, format: .e164))
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    // Invalid ES number, GitHub pr by dulaccc
    func testInvalidESNumbers() {
        do {
            // libphonenumber reports this number as invalid
            // and it's true, this is a French mobile number combined with the ES region
            let phoneNumber = try util.parse("+34312431110")
            print(util.format(phoneNumber, format: .e164))
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    // Italian number with a leading zero
    func testItalianLeadingZero() {
        let testNumber = "+39 0549555555"
        do {
            let phoneNumber = try util.parse(testNumber)
//            XCTAssertEqual(phoneNumber.toInternational(), testNumber)
            XCTAssertEqual(phoneNumber.countryCode, 39)
            XCTAssertEqual(phoneNumber.nationalNumber, 549555555)
            XCTAssertEqual(phoneNumber.italianLeadingZero, true)
        } catch {
            XCTFail()
        }
    }

    // French number with extension
    func testNumberWithExtension() {
        let testNumber = "+33-689-5-5555-5 ext. 84"
        do {
            let phoneNumber = try util.parse(testNumber)
            XCTAssertEqual(phoneNumber.countryCode, 33)
            XCTAssertEqual(phoneNumber.extension, "84")
            XCTAssertEqual(phoneNumber.nationalNumber, 689555555)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    // American number with short extension
    func testAlternativeNumberWithExtension() {
        let testNumber = "2129316760 x28"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "US", ignoreType: false)
            XCTAssertEqual(phoneNumber.countryCode, 1)
            XCTAssertEqual(phoneNumber.extension, "28")
            XCTAssertEqual(phoneNumber.nationalNumber, 2129316760)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    // French number with a plus
    func testValidNumberWithPlusNoWhiteSpace() {
        let testNumber = "+33689555555"
        do {
            let phoneNumber = try util.parse(testNumber)
            XCTAssertEqual(util.format(phoneNumber, format: .e164), testNumber)
            XCTAssertEqual(util.format(phoneNumber, format: .international, withPrefix: false), "6 89 55 55 55")
            XCTAssertEqual(phoneNumber.countryCode, 33)
            XCTAssertEqual(phoneNumber.nationalNumber, 689555555)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
            // XCTAssertEqual(phoneNumber.type, PhoneNumberType.mobile)
        } catch {
            XCTFail()
        }
    }

    // 'Noisy' Japanese number with a plus
    func testValidNumberWithPlusWhiteSpace() {
        let testNumber = "+81 601 55-5-5 5 5"
        do {
            let phoneNumber = try util.parse(testNumber)
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+81601555555")
            XCTAssertEqual(phoneNumber.countryCode, 81)
            XCTAssertEqual(phoneNumber.nationalNumber, 601555555)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    // English number with an American IDD (default region for testing enivronment)
    func testValidNumberWithAmericanIDDNoWhiteSpace() {
        let testNumber = "011447739555555"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "US")
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+447739555555")
            XCTAssertEqual(phoneNumber.countryCode, 44)
            XCTAssertEqual(phoneNumber.nationalNumber, 7739555555)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    // 'Noisy' Brazilian number with an American IDD (default region for testing enivronment)
    func testValidNumberWithAmericanIDDWhiteSpace() {
        let testNumber = "01155 11 9 6 555 55 55"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "US")
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+5511965555555")
            XCTAssertEqual(phoneNumber.countryCode, 55)
            XCTAssertEqual(phoneNumber.nationalNumber, 11965555555)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    //  American number with no prefix from an American phone (default region for testing enivronment)
    func testValidLocalNumberWithNoPrefixNoWhiteSpace() {
        let testNumber = "2015555555"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "US")
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+12015555555")
            XCTAssertEqual(phoneNumber.countryCode, 1)
            XCTAssertEqual(phoneNumber.nationalNumber, 2015555555)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    //  'Noisy' American number with no prefix from an American phone (default region for testing enivronment)
    func testValidLocalNumberWithNoPrefixWhiteSpace() {
        let testNumber = "500-2-55-555-5"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "US")
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+15002555555")
            XCTAssertEqual(phoneNumber.countryCode, 1)
            XCTAssertEqual(phoneNumber.nationalNumber, 5002555555)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }
    
    func testValidAENumberWithHinduArabicNumerals() {
        let testNumber = "+٩٧١٥٠٠٥٠٠٥٥٠"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "AE")
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+971500500550")
            XCTAssertEqual(phoneNumber.countryCode, 971)
            XCTAssertEqual(phoneNumber.nationalNumber, 500500550)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    func testValidAENumberWithMixedHinduArabicNumerals() {
        let testNumber = "+٩٧١5٠٠5٠٠55٠"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "AE")
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+971500500550")
            XCTAssertEqual(phoneNumber.countryCode, 971)
            XCTAssertEqual(phoneNumber.nationalNumber, 500500550)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    func testValidAENumberWithEasternArabicNumerals() {
        let testNumber = "+۹۷۱۵۰۰۵۰۰۵۵۰"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "AE")
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+971500500550")
            XCTAssertEqual(phoneNumber.countryCode, 971)
            XCTAssertEqual(phoneNumber.nationalNumber, 500500550)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    func testValidAENumberWithMixedEasternArabicNumerals() {
        let testNumber = "+۹۷۱5۰۰5۰۰55۰"
        do {
            let phoneNumber = try util.parse(testNumber, regionCode: "AE")
            XCTAssertEqual(util.format(phoneNumber, format: .e164), "+971500500550")
            XCTAssertEqual(phoneNumber.countryCode, 971)
            XCTAssertEqual(phoneNumber.nationalNumber, 500500550)
            XCTAssertEqual(phoneNumber.italianLeadingZero, false)
        } catch {
            XCTFail()
        }
    }

    //  Invalid number too short
    func testInvalidNumberTooShort() {
        let testNumber = "+44 32"
        do {
            let phoneNumber = try util.parse(testNumber)
            _ = util.format(phoneNumber, format: .e164)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    //  Invalid number too long
    func testInvalidNumberTooLong() {
        let testNumber = "+44 3243894723084732047023472"
        do {
            let phoneNumber = try util.parse(testNumber)
            _ = util.format(phoneNumber, format: .e164)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    //  Invalid number not a number, random string
    func testInvalidNumberNotANumber() {
        let testNumber = "ae4c08c6-be33-40ef-a417-e5166e307b5e"
        do {
            let phoneNumber = try util.parse(testNumber)
            _ = util.format(phoneNumber, format: .e164)
            XCTFail()
        } catch {
            XCTAssert(true)
        }
    }

    //  Invalid number invalid format
    func testInvalidNumberNotANumberInvalidFormat() {
        let testNumber = "+33(02)689555555"
        do {
            let phoneNumber = try util.parse(testNumber)
            _ = util.format(phoneNumber, format: .e164)
            XCTFail()
        } catch PhoneNumberError.notANumber {
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
    }

  //  Test that metadata initiates correctly by checking all countries
  func testAllRegionCodes() {
    let allRegionCodes = util.supportedRegionCodes
    XCTAssert(allRegionCodes.count > 0)
  }

    //  Test code for country function -  valid country
    func testCodeForCountryValid() {
        XCTAssertEqual(util.countryCode(forRegionCode: "FR"), 33)
    }

    //  Test code for country function - invalid country
    func testCodeForCountryInvalid() {
        XCTAssertEqual(util.countryCode(forRegionCode: "FOOBAR"), nil)
    }

    //  Test countries for code function
    func testCountriesForCodeValid() {
        XCTAssertEqual(util.regionCodes(forCountryCode: 1)?.count, 25)
    }

    //  Test countries for code function
    func testCountriesForCodeInvalid() {
        XCTAssertEqual(util.regionCodes(forCountryCode: 424242)?.count, nil)
    }

    //  Test region code for number function
    func testGetRegionCode() {
        guard let phoneNumber = try? util.parse("+39 3123456789") else {
            XCTFail()
            return
        }
        XCTAssertEqual(util.regionCode(for: phoneNumber), "IT")
    }
    
    // In the case of multiple
    // countries sharing a calling code, the one
    // indicated with "isMainCountryForCode" in the metadata should be first.
    func testGetRegionCodeForTollFreeFromUS() {
        guard let phoneNumber = try? util.parse("+1 888 579 4458") else {
            XCTFail()
            return
        }
        XCTAssertEqual(util.regionCode(for: phoneNumber), "US")
    }
}
