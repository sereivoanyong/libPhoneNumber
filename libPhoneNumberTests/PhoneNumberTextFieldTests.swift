//
//  PhoneNumberTextFieldTests.swift
//
//  Created by Sereivoan Yong on 12/3/20.
//

#if canImport(UIKit)
@testable import libPhoneNumber
import UIKit
import XCTest

class PhoneNumberTextFieldTests: XCTestCase {

    func testWorksWithPhoneNumberUtilInstance() {
        let util = PhoneNumberUtil()
        let tf = PhoneNumberTextField(util: util)
        tf.text = "4125551212"
        XCTAssertEqual(tf.text, "(412) 555-1212")
    }

    func testWorksWithFrameAndPhoneNumberUtilInstance() {
        let util = PhoneNumberUtil()
        let frame = CGRect(x: 10.0, y: 20.0, width: 400.0, height: 250.0)
        let tf = PhoneNumberTextField(frame: frame, util: util)
        XCTAssertEqual(tf.frame, frame)
        tf.text = "4125551212"
        XCTAssertEqual(tf.text, "(412) 555-1212")
    }

	func testPhoneNumberProperty() {
		let util = PhoneNumberUtil()
		let tf = PhoneNumberTextField(util: util)
		tf.text = "4125551212"
		XCTAssertNotNil(tf.phoneNumber)
		tf.text = ""
		XCTAssertNil(tf.phoneNumber)
	}
}
#endif
