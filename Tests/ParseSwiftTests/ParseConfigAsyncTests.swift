//
//  ParseConfigAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if swift(>=5.5) && canImport(_Concurrency) && !os(Linux) && !os(Android)
import Foundation
import XCTest
@testable import ParseSwift

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
class ParseConfigAsyncTests: XCTestCase { // swiftlint:disable:this type_body_length
    struct Config: ParseConfig {
        var welcomeMessage: String?
        var winningNumber: Int?
    }

    struct User: ParseUser {

        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by User
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String
        var updatedAt: Date?
        var ACL: ParseACL?

        // provided by User
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?

        init() {
            let date = Date()
            self.createdAt = date
            self.updatedAt = date
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.email = "hello@parse.com"
        }
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              masterKey: "masterKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func userLogin() {
        let loginResponse = LoginSignupResponse()
        let loginUserName = "hello10"
        let loginPassword = "world"

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        do {
            _ = try User.login(username: loginUserName, password: loginPassword)
            MockURLProtocol.removeAll()
        } catch {
            XCTFail("Should login")
        }
    }

    @MainActor
    func testFetch() async throws {

        userLogin()
        let config = Config()

        var configOnServer = config
        configOnServer.welcomeMessage = "Hello"
        let serverResponse = ConfigFetchResponse(params: configOnServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let fetched = try await config.fetch()
        XCTAssertEqual(fetched.welcomeMessage, configOnServer.welcomeMessage)
        XCTAssertEqual(Config.current?.welcomeMessage, configOnServer.welcomeMessage)

        #if !os(Linux) && !os(Android)
        //Should be updated in Keychain
        guard let keychainConfig: CurrentConfigContainer<Config>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, configOnServer.welcomeMessage)
        #endif
    }

    @MainActor
    func testSave() async throws {

        userLogin()
        var config = Config()
        config.welcomeMessage = "Hello"

        let serverResponse = ConfigUpdateResponse(result: true)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let saved = try await config.save()
        XCTAssertTrue(saved)
        XCTAssertEqual(Config.current?.welcomeMessage, config.welcomeMessage)

        #if !os(Linux) && !os(Android)
        //Should be updated in Keychain
        guard let keychainConfig: CurrentConfigContainer<Config>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
                XCTFail("Should get object from Keychain")
            return
        }
        XCTAssertEqual(keychainConfig.currentConfig?.welcomeMessage, config.welcomeMessage)
        #endif
    }
}
#endif
