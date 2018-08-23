//
//  WebUntisTests.swift
//  WebUntisTests
//
//  Created by Nils Bergmann on 22.08.18.
//  Copyright © 2018 Nils Bergmann. All rights reserved.
//

import XCTest
import Promises
@testable import WebUntis

class WebUntisTests: XCTestCase {
    
    private var server = "";
    private var username = "";
    private var password = "";
    private var school = "";
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let testBundle = Bundle(for: type(of: self));
        guard let file = testBundle.path(forResource: "credentials", ofType: "plist"), let configuration = NSDictionary(contentsOfFile: file) as? [String: Any] else {
            print("Please save credentials in credentials.plist.");
            return;
        }
        guard let username = configuration["username"] as? String, let password = configuration["password"] as? String, let server = configuration["server"] as? String, let school = configuration["school"] as? String else {
            print("You forgot something.");
            return;
        }
        self.server = server;
        self.username = username;
        self.password = password;
        self.school = school;
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testErrorShouldWork() {
        let unauthorizedError = getWebUntisErrorBy(type: .UNAUTHORIZED, userInfo: nil) as Error;
        XCTAssertNotNil(unauthorizedError);
        XCTAssertFalse(unauthorizedError.isWebUntisError(type: WebUntisError.UNKNOWN));
        XCTAssert(unauthorizedError.isWebUntisError(type: WebUntisError.UNAUTHORIZED));
    }
    
    func testSetCredentials() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let expectation = XCTestExpectation(description: "Login to WebUntis");
        WebUntis.default.setCredentials(server: self.server, username: self.username, password: self.password, school: self.school).then{ result in
            XCTAssert(result);
            expectation.fulfill();
        }.catch { error in
            print(error);
            XCTAssertTrue(false);
            expectation.fulfill();
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testCredentialsFail() {
        let expectation = XCTestExpectation(description: "Login to WebUntis should fail");
        WebUntis.default.setCredentials(server: self.server, username: self.username + "_this_should_fail", password: self.password, school: self.school).then{ result in
            XCTAssertFalse(true, "Then should not be called. This login request should fail.");
            expectation.fulfill();
        }.catch { error in
            XCTAssert(error.isWebUntisError(type: WebUntisError.UNAUTHORIZED), "The error should be UNAUTHORIZED")
            expectation.fulfill();
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testStatus() {
        let expectation = XCTestExpectation(description: "Fetch getStatusData");
        WebUntis.default.setCredentials(server: self.server, username: self.username, password: self.password, school: self.school).then{ result in
            if result {
                WebUntis.default.doJSONRPC(method: .STATUS).then { response in
                    print(response);
                    XCTAssertNotNil(response);
                    expectation.fulfill();
                }.catch { error in
                    print(error);
                    XCTAssertTrue(false);
                    expectation.fulfill();
                }
            } else {
                XCTAssert(result);
                expectation.fulfill();
            }
        }.catch { error in
            print(error);
            XCTAssertTrue(false);
            expectation.fulfill();
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
