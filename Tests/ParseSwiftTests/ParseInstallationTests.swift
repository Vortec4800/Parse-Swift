//
//  ParseInstallationTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 9/7/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseInstallationTests: XCTestCase { // swiftlint:disable:this type_body_length

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

    struct Installation: ParseInstallation {
        var installationId: String?
        var deviceType: String?
        var deviceToken: String?
        var badge: Int?
        var timeZone: String?
        var channels: [String]?
        var appName: String?
        var appIdentifier: String?
        var appVersion: String?
        var parseVersion: String?
        var localeIdentifier: String?
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var customKey: String?
    }

    let testInstallationObjectId = "yarr"

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
        userLogin()
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

    func testNewInstallationIdentifierIsLowercase() {
        guard let installationIdFromContainer
            = Installation.currentContainer.installationId else {
            XCTFail("Should have retreived installationId from container")
            return
        }

        XCTAssertEqual(installationIdFromContainer, installationIdFromContainer.lowercased())

        guard let installationIdFromCurrent = Installation.current?.installationId else {
            XCTFail("Should have retreived installationId from container")
            return
        }

        XCTAssertEqual(installationIdFromCurrent, installationIdFromCurrent.lowercased())
        XCTAssertEqual(installationIdFromContainer, installationIdFromCurrent)
    }

    func testDeviceTokenAsString() throws {
        let data = Data([0, 1, 127, 128, 255])
        XCTAssertEqual(data.hexEncodedString(), "00017f80ff")
        XCTAssertEqual(data.hexEncodedString(options: .upperCase), "00017F80FF")
    }

    func testInstallationMutableValuesCanBeChangedInMemory() {
        guard let originalInstallation = Installation.current else {
            XCTFail("All of these Installation values should have unwraped")
            return
        }

        Installation.current?.customKey = "Changed"
        Installation.current?.setDeviceToken(Data([0, 1, 127, 128, 255]))
        XCTAssertNotEqual(originalInstallation.customKey, Installation.current?.customKey)
        XCTAssertNotEqual(originalInstallation.deviceToken, Installation.current?.customKey)
    }

    #if !os(Linux) && !os(Android)
    func testInstallationImmutableFieldsCannotBeChangedInMemory() {
        guard let originalInstallation = Installation.current,
            let originalInstallationId = originalInstallation.installationId,
            let originalDeviceType = originalInstallation.deviceType,
            let originalTimeZone = originalInstallation.timeZone,
            let originalAppName = originalInstallation.appName,
            let originalAppIdentifier = originalInstallation.appIdentifier,
            let originalAppVersion = originalInstallation.appVersion,
            let originalParseVersion = originalInstallation.parseVersion,
            let originalLocaleIdentifier = originalInstallation.localeIdentifier
            else {
                XCTFail("All of these Installation values should have unwraped")
            return
        }

        Installation.current?.installationId = "changed"
        Installation.current?.deviceType = "changed"
        Installation.current?.badge = 500
        Installation.current?.timeZone = "changed"
        Installation.current?.appName = "changed"
        Installation.current?.appIdentifier = "changed"
        Installation.current?.appVersion = "changed"
        Installation.current?.parseVersion = "changed"
        Installation.current?.localeIdentifier = "changed"

        XCTAssertEqual(originalInstallationId, Installation.current?.installationId)
        XCTAssertEqual(originalDeviceType, Installation.current?.deviceType)
        XCTAssertEqual(500, Installation.current?.badge)
        XCTAssertEqual(originalTimeZone, Installation.current?.timeZone)
        XCTAssertEqual(originalAppName, Installation.current?.appName)
        XCTAssertEqual(originalAppIdentifier, Installation.current?.appIdentifier)
        XCTAssertEqual(originalAppVersion, Installation.current?.appVersion)
        XCTAssertEqual(originalParseVersion, Installation.current?.parseVersion)
        XCTAssertEqual(originalLocaleIdentifier, Installation.current?.localeIdentifier)
    }

    func testInstallationCustomValuesSavedToKeychain() {
        let customField = "Changed"
        Installation.current?.customKey = customField
        Installation.saveCurrentContainerToKeychain()
        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            return
        }
        XCTAssertEqual(keychainInstallation.currentInstallation?.customKey, customField)
    }

    // swiftlint:disable:next function_body_length
    func testInstallationImmutableFieldsCannotBeChangedInKeychain() {
        guard let originalInstallation = Installation.current,
            let originalInstallationId = originalInstallation.installationId,
            let originalDeviceType = originalInstallation.deviceType,
            let originalTimeZone = originalInstallation.timeZone,
            let originalAppName = originalInstallation.appName,
            let originalAppIdentifier = originalInstallation.appIdentifier,
            let originalAppVersion = originalInstallation.appVersion,
            let originalParseVersion = originalInstallation.parseVersion,
            let originalLocaleIdentifier = originalInstallation.localeIdentifier
            else {
                XCTFail("All of these Installation values should have unwraped")
            return
        }

        Installation.current?.installationId = "changed"
        Installation.current?.deviceType = "changed"
        Installation.current?.badge = 500
        Installation.current?.timeZone = "changed"
        Installation.current?.appName = "changed"
        Installation.current?.appIdentifier = "changed"
        Installation.current?.appVersion = "changed"
        Installation.current?.parseVersion = "changed"
        Installation.current?.localeIdentifier = "changed"

        Installation.saveCurrentContainerToKeychain()

        guard let keychainInstallation: CurrentInstallationContainer<Installation>
            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertEqual(originalInstallationId, keychainInstallation.currentInstallation?.installationId)
        XCTAssertEqual(originalDeviceType, keychainInstallation.currentInstallation?.deviceType)
        XCTAssertEqual(500, keychainInstallation.currentInstallation?.badge)
        XCTAssertEqual(originalTimeZone, keychainInstallation.currentInstallation?.timeZone)
        XCTAssertEqual(originalAppName, keychainInstallation.currentInstallation?.appName)
        XCTAssertEqual(originalAppIdentifier, keychainInstallation.currentInstallation?.appIdentifier)
        XCTAssertEqual(originalAppVersion, keychainInstallation.currentInstallation?.appVersion)
        XCTAssertEqual(originalParseVersion, keychainInstallation.currentInstallation?.parseVersion)
        XCTAssertEqual(originalLocaleIdentifier, keychainInstallation.currentInstallation?.localeIdentifier)
    }
    #endif

    func testUpdate() {
        var installation = Installation()
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil
        installation.installationId = "hello"

        var installationOnServer = installation
        installationOnServer.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let saved = try installation.save()
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
            guard let savedUpdatedAt = saved.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            guard let serverUpdatedAt = installationOnServer.updatedAt else {
                XCTFail("Should unwrap dates")
                return
            }
            XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSaveCurrentInstallation() throws {
        guard var installation = Installation.current else {
            XCTFail("Should unwrap")
            return
        }
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let saved = try Installation.current!.save()
            guard let newCurrentInstallation = Installation.current else {
                XCTFail("Should have a new current installation")
                return
            }
            XCTAssertTrue(saved.hasSameInstallationId(as: newCurrentInstallation))
            XCTAssertTrue(saved.hasSameObjectId(as: newCurrentInstallation))
            XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
            XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
            XCTAssertNil(saved.ACL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func updateAsync(installation: Installation, installationOnServer: Installation, callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update installation1")
        installation.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                guard let originalUpdatedAt = installation.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                XCTAssertTrue(saved.hasSameObjectId(as: installation))
                XCTAssertTrue(saved.hasSameInstallationId(as: installation))
                XCTAssertGreaterThan(savedUpdatedAt, originalUpdatedAt)
                XCTAssertNil(saved.ACL)
                expectation1.fulfill()

            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testUpdateAsyncMainQueue() {
        var installation = Installation()
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil
        installation.installationId = "hello"

        var installationOnServer = installation
        installationOnServer.updatedAt = Date()
        let encoded: Data!
        do {
            let encodedOriginal = try ParseCoding.jsonEncoder().encode(installation)
            //Get dates in correct format from ParseDecoding strategy
            installation = try installation.getDecoder().decode(Installation.self, from: encodedOriginal)

            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        self.updateAsync(installation: installation, installationOnServer: installationOnServer, callbackQueue: .main)
    }

    // swiftlint:disable:next function_body_length
    func saveCurrentAsync(installation: Installation,
                          installationOnServer: Installation,
                          callbackQueue: DispatchQueue) {

        let expectation1 = XCTestExpectation(description: "Update installation1")
        installation.save(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let saved):
                guard let currentInstallation = Installation.current else {
                    XCTFail("Should have current")
                    expectation1.fulfill()
                    return
                }
                XCTAssertTrue(saved.hasSameObjectId(as: currentInstallation))
                XCTAssertTrue(saved.hasSameInstallationId(as: currentInstallation))
                XCTAssertTrue(saved.hasSameObjectId(as: installationOnServer))
                XCTAssertTrue(saved.hasSameInstallationId(as: installationOnServer))
                guard let savedUpdatedAt = saved.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                guard let serverUpdatedAt = installationOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    expectation1.fulfill()
                    return
                }
                XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                XCTAssertNil(saved.ACL)
                XCTAssertNil(currentInstallation.ACL)
                expectation1.fulfill()

            case .failure(let error):
                XCTFail(error.localizedDescription)
                expectation1.fulfill()
            }
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveCurrentAsyncMainQueue() {
        guard var installation = Installation.current else {
            XCTFail("Should unwrap")
            return
        }
        installation.objectId = testInstallationObjectId
        installation.createdAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.updatedAt = Calendar.current.date(byAdding: .init(day: -1), to: Date())
        installation.ACL = nil

        var installationOnServer = installation

        let encoded: Data!
        do {
            let encodedOriginal = try ParseCoding.jsonEncoder().encode(installation)
            //Get dates in correct format from ParseDecoding strategy
            installation = try installation.getDecoder().decode(Installation.self, from: encodedOriginal)

            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        self.saveCurrentAsync(installation: installation,
                                installationOnServer: installationOnServer,
                                callbackQueue: .main)
    }

    func testFetchCommand() {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId
        do {
            let command = try installation.fetchCommand(include: nil)
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertNil(command.params)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let installation2 = Installation()
        XCTAssertThrowsError(try installation2.fetchCommand(include: nil))
    }

    func testFetchIncludeCommand() {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId
        let includeExpected = ["include": "[\"yolo\", \"test\"]"]
        do {
            let command = try installation.fetchCommand(include: ["yolo", "test"])
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
            XCTAssertEqual(command.method, API.Method.GET)
            XCTAssertEqual(command.params, includeExpected)
            XCTAssertNil(command.body)

            // swiftlint:disable:next line_length
            guard let urlExpected = URL(string: "http://localhost:1337/1/installations/yarr?include=%5B%22yolo%22,%20%22test%22%5D") else {
                XCTFail("Should have unwrapped")
                return
            }
            let request = command.prepareURLRequest(options: [])
            switch request {
            case .success(let url):
                XCTAssertEqual(url.url, urlExpected)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        let installation2 = Installation()
        XCTAssertThrowsError(try installation2.fetchCommand(include: nil))
    }

    func testFetchUpdatedCurrentInstallation() throws { // swiftlint:disable:this function_body_length
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current,
            let savedObjectId = installation.objectId else {
                XCTFail("Should unwrap")
                return
        }
        XCTAssertEqual(savedObjectId, self.testInstallationObjectId)

        var installationOnServer = installation
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let fetched = try installation.fetch()
            guard let currentInstallation = Installation.current else {
                XCTFail("Should have current installation")
                return
            }
            XCTAssertTrue(fetched.hasSameObjectId(as: currentInstallation))
            XCTAssertTrue(fetched.hasSameInstallationId(as: currentInstallation))
            XCTAssertTrue(fetched.hasSameObjectId(as: installationOnServer))
            XCTAssertTrue(fetched.hasSameInstallationId(as: installationOnServer))
            guard let fetchedCreatedAt = fetched.createdAt,
                let fetchedUpdatedAt = fetched.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            guard let originalCreatedAt = installationOnServer.createdAt,
                let originalUpdatedAt = installation.updatedAt,
                let serverUpdatedAt = installationOnServer.updatedAt else {
                    XCTFail("Should unwrap dates")
                    return
            }
            XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
            XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
            XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
            XCTAssertEqual(Installation.current?.customKey, installationOnServer.customKey)

            //Should be updated in memory
            guard let updatedCurrentDate = Installation.current?.updatedAt else {
                XCTFail("Should unwrap current date")
                return
            }
            XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

            //Should be updated in Keychain
            #if !os(Linux) && !os(Android)
            guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                    XCTFail("Should get object from Keychain")
                return
            }
            XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
            #endif
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFetchUpdatedCurrentInstallationAsync() throws { // swiftlint:disable:this function_body_length
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Update installation1")

        guard let installation = Installation.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }

        var installationOnServer = installation
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installationOnServer.customKey = "newValue"

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        installation.fetch(options: [], callbackQueue: .main) { result in

            switch result {
            case .success(let fetched):
                guard let currentInstallation = Installation.current else {
                    XCTFail("Should have current installation")
                    return
                }
                XCTAssertTrue(fetched.hasSameObjectId(as: currentInstallation))
                XCTAssertTrue(fetched.hasSameInstallationId(as: currentInstallation))
                XCTAssertTrue(fetched.hasSameObjectId(as: installationOnServer))
                XCTAssertTrue(fetched.hasSameInstallationId(as: installationOnServer))
                guard let fetchedCreatedAt = fetched.createdAt,
                    let fetchedUpdatedAt = fetched.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                guard let originalCreatedAt = installationOnServer.createdAt,
                    let originalUpdatedAt = installation.updatedAt,
                    let serverUpdatedAt = installationOnServer.updatedAt else {
                        XCTFail("Should unwrap dates")
                        expectation1.fulfill()
                        return
                }
                XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                XCTAssertGreaterThan(fetchedUpdatedAt, originalUpdatedAt)
                XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                XCTAssertEqual(Installation.current?.customKey, installationOnServer.customKey)

                //Should be updated in memory
                guard let updatedCurrentDate = Installation.current?.updatedAt else {
                    XCTFail("Should unwrap current date")
                    expectation1.fulfill()
                    return
                }
                XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                #if !os(Linux) && !os(Android)
                //Should be updated in Keychain
                guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                    = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                    let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                        XCTFail("Should get object from Keychain")
                        expectation1.fulfill()
                    return
                }
                XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                #endif
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testDeleteCommand() {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId
        do {
            let command = try installation.deleteCommand()
            XCTAssertNotNil(command)
            XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
            XCTAssertEqual(command.method, API.Method.DELETE)
            XCTAssertNil(command.body)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let installation2 = Installation()
        XCTAssertThrowsError(try installation2.deleteCommand())
    }

    func testDeleteCurrent() throws {
        try testSaveCurrentInstallation()

        guard let installation = Installation.current else {
            XCTFail("Should unwrap dates")
            return
        }

        do {
            try installation.delete(options: [])
            if let newInstallation = Installation.current {
                XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            try installation.delete(options: [.useMasterKey])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteCurrentAsyncMainQueue() throws {
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Delete installation1")
        guard let installation = Installation.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }

        var installationOnServer = installation
        installationOnServer.updatedAt = installation.updatedAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try installationOnServer.getEncoder().encode(installationOnServer, skipKeys: .none)
            //Get dates in correct format from ParseDecoding strategy
            installationOnServer = try installationOnServer.getDecoder().decode(Installation.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        installation.delete { result in
            if case let .failure(error) = result {
                XCTFail(error.localizedDescription)
            }
            if let newInstallation = Installation.current {
                XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    // swiftlint:disable:next function_body_length
    func testFetchAllCurrent() throws {
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard var installation = Installation.current else {
            XCTFail("Should unwrap dates")
            return
        }

        installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installation.customKey = "newValue"
        let installationOnServer = QueryResponse<Installation>(results: [installation], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
            installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let fetched = try [installation].fetchAll()
            fetched.forEach {
                switch $0 {
                case .success(let fetched):
                    guard let currentInstallation = Installation.current else {
                        XCTFail("Should have current installation")
                        return
                    }
                    XCTAssertTrue(fetched.hasSameObjectId(as: currentInstallation))
                    XCTAssertTrue(fetched.hasSameInstallationId(as: currentInstallation))
                    guard let fetchedCreatedAt = fetched.createdAt,
                        let fetchedUpdatedAt = fetched.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = installation.createdAt,
                        let originalUpdatedAt = installation.updatedAt,
                        let serverUpdatedAt = installation.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                    XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = Installation.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                    #if !os(Linux) && !os(Android)
                    //Should be updated in Keychain
                    guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                        let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                            XCTFail("Should get object from Keychain")
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                    #endif
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func testFetchAllAsyncMainQueueCurrent() throws {
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Fetch installation1")
        guard var installation = Installation.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            return
        }

        installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installation.customKey = "newValue"
        let installationOnServer = QueryResponse<Installation>(results: [installation], count: 1)

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
            installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        [installation].fetchAll { results in
            switch results {

            case .success(let fetched):
                fetched.forEach {
                    switch $0 {
                    case .success(let fetched):
                        guard let currentInstallation = Installation.current else {
                            XCTFail("Should have current installation")
                            return
                        }
                        XCTAssertTrue(fetched.hasSameObjectId(as: currentInstallation))
                        XCTAssertTrue(fetched.hasSameInstallationId(as: currentInstallation))
                        guard let fetchedCreatedAt = fetched.createdAt,
                            let fetchedUpdatedAt = fetched.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        guard let originalCreatedAt = installation.createdAt,
                            let originalUpdatedAt = installation.updatedAt,
                            let serverUpdatedAt = installation.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        XCTAssertEqual(fetchedCreatedAt, originalCreatedAt)
                        XCTAssertEqual(fetchedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(fetchedUpdatedAt, serverUpdatedAt)
                        XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                        //Should be updated in memory
                        guard let updatedCurrentDate = Installation.current?.updatedAt else {
                            XCTFail("Should unwrap current date")
                            expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                        #if !os(Linux) && !os(Android)
                        //Should be updated in Keychain
                        guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                            let keychainUpdatedCurrentDate = keychainInstallation
                                .currentInstallation?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                        #endif
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 20.0)
    }

    func testSaveCommand() throws {
        let installation = Installation()
        let command = try installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    func testUpdateCommand() throws {
        var installation = Installation()
        let objectId = "yarr"
        installation.objectId = objectId

        let command = try installation.saveCommand()
        XCTAssertNotNil(command)
        XCTAssertEqual(command.path.urlComponent, "/installations/\(objectId)")
        XCTAssertEqual(command.method, API.Method.PUT)
        XCTAssertNil(command.params)
        XCTAssertNotNil(command.body)
    }

    // swiftlint:disable:next function_body_length
    func testSaveAllCurrent() throws {
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard var installation = Installation.current else {
            XCTFail("Should unwrap dates")
            return
        }

        var installation2 = installation
        installation2.objectId = "old"
        installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installation.customKey = "newValue"

        let installationOnServer = [BatchResponseItem<Installation>(success: installation,
                                                                    error: nil),
                                    BatchResponseItem<Installation>(success: installation2,
                                                                    error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
            installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let saved = try [installation].saveAll()
            saved.forEach {
                switch $0 {
                case .success(let saved):
                    guard let currentInstallation = Installation.current else {
                        XCTFail("Should have current installation")
                        return
                    }
                    XCTAssertTrue(saved.hasSameObjectId(as: currentInstallation))
                    XCTAssertTrue(saved.hasSameInstallationId(as: currentInstallation))
                    XCTAssertTrue(saved.hasSameObjectId(as: installation))
                    XCTAssertTrue(saved.hasSameInstallationId(as: installation))
                    guard let savedCreatedAt = saved.createdAt,
                        let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = installation.createdAt,
                        let originalUpdatedAt = installation.updatedAt,
                        let serverUpdatedAt = installation.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                    XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = Installation.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                    #if !os(Linux) && !os(Android)
                    //Should be updated in Keychain
                    guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                        let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                            XCTFail("Should get object from Keychain")
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                    #endif
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let saved2 = try [installation].saveAll(transaction: true)
            saved2.forEach {
                switch $0 {
                case .success(let saved):
                    guard let currentInstallation = Installation.current else {
                        XCTFail("Should have current installation")
                        return
                    }
                    XCTAssertTrue(saved.hasSameObjectId(as: currentInstallation))
                    XCTAssertTrue(saved.hasSameInstallationId(as: currentInstallation))
                    guard let savedCreatedAt = saved.createdAt,
                        let savedUpdatedAt = saved.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    guard let originalCreatedAt = installation.createdAt,
                        let originalUpdatedAt = installation.updatedAt,
                        let serverUpdatedAt = installation.updatedAt else {
                            XCTFail("Should unwrap dates")
                            return
                    }
                    XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                    XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                    XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                    XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                    //Should be updated in memory
                    guard let updatedCurrentDate = Installation.current?.updatedAt else {
                        XCTFail("Should unwrap current date")
                        return
                    }
                    XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)

                    #if !os(Linux) && !os(Android)
                    //Should be updated in Keychain
                    guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                        = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                        let keychainUpdatedCurrentDate = keychainInstallation.currentInstallation?.updatedAt else {
                            XCTFail("Should get object from Keychain")
                        return
                    }
                    XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                    #endif
                case .failure(let error):
                    XCTFail("Should have fetched: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // swiftlint:disable:next function_body_length
    func testSaveAllAsyncMainQueueCurrent() throws {
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Fetch installation1")
        let expectation2 = XCTestExpectation(description: "Fetch installation2")
        guard var installation = Installation.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            expectation2.fulfill()
            return
        }

        var installation2 = installation
        installation2.objectId = "old"
        installation.updatedAt = installation.updatedAt?.addingTimeInterval(+300)
        installation.customKey = "newValue"
        let installationOnServer = [BatchResponseItem<Installation>(success: installation,
                                                                    error: nil),
                                    BatchResponseItem<Installation>(success: installation2,
                                                                    error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
            //Get dates in correct format from ParseDecoding strategy
            let encoded1 = try ParseCoding.jsonEncoder().encode(installation)
            installation = try installation.getDecoder().decode(Installation.self, from: encoded1)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            expectation2.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        [installation].saveAll { results in
            switch results {

            case .success(let saved):
                saved.forEach {
                    switch $0 {
                    case .success(let saved):
                        guard let currentInstallation = Installation.current else {
                            XCTFail("Should have current installation")
                            return
                        }
                        XCTAssertTrue(saved.hasSameObjectId(as: currentInstallation))
                        XCTAssertTrue(saved.hasSameInstallationId(as: currentInstallation))
                        XCTAssertTrue(saved.hasSameObjectId(as: installation))
                        XCTAssertTrue(saved.hasSameInstallationId(as: installation))
                        guard let savedCreatedAt = saved.createdAt,
                            let savedUpdatedAt = saved.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        guard let originalCreatedAt = installation.createdAt,
                            let originalUpdatedAt = installation.updatedAt,
                            let serverUpdatedAt = installation.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation1.fulfill()
                                return
                        }
                        XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                        XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                        XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                        //Should be updated in memory
                        guard let updatedCurrentDate = Installation.current?.updatedAt else {
                            XCTFail("Should unwrap current date")
                            expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)
                        #if !os(Linux) && !os(Android)
                        //Should be updated in Keychain
                        guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                            let keychainUpdatedCurrentDate = keychainInstallation
                                .currentInstallation?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation1.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                        #endif
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            expectation1.fulfill()
        }

        [installation].saveAll(transaction: true) { results in
            switch results {

            case .success(let saved):
                saved.forEach {
                    switch $0 {
                    case .success(let saved):
                        guard let currentInstallation = Installation.current else {
                            XCTFail("Should have current installation")
                            return
                        }
                        XCTAssertTrue(saved.hasSameObjectId(as: currentInstallation))
                        XCTAssertTrue(saved.hasSameInstallationId(as: currentInstallation))
                        guard let savedCreatedAt = saved.createdAt,
                            let savedUpdatedAt = saved.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                        }
                        guard let originalCreatedAt = installation.createdAt,
                            let originalUpdatedAt = installation.updatedAt,
                            let serverUpdatedAt = installation.updatedAt else {
                                XCTFail("Should unwrap dates")
                                expectation2.fulfill()
                                return
                        }
                        XCTAssertEqual(savedCreatedAt, originalCreatedAt)
                        XCTAssertEqual(savedUpdatedAt, originalUpdatedAt)
                        XCTAssertEqual(savedUpdatedAt, serverUpdatedAt)
                        XCTAssertEqual(Installation.current?.customKey, installation.customKey)

                        //Should be updated in memory
                        guard let updatedCurrentDate = Installation.current?.updatedAt else {
                            XCTFail("Should unwrap current date")
                            expectation2.fulfill()
                            return
                        }
                        XCTAssertEqual(updatedCurrentDate, serverUpdatedAt)
                        #if !os(Linux) && !os(Android)
                        //Should be updated in Keychain
                        guard let keychainInstallation: CurrentInstallationContainer<BaseParseInstallation>
                            = try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation),
                            let keychainUpdatedCurrentDate = keychainInstallation
                                .currentInstallation?.updatedAt else {
                                XCTFail("Should get object from Keychain")
                                expectation2.fulfill()
                            return
                        }
                        XCTAssertEqual(keychainUpdatedCurrentDate, serverUpdatedAt)
                        #endif
                    case .failure(let error):
                        XCTFail("Should have fetched: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have fetched: \(error.localizedDescription)")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testDeleteAllCurrent() throws {
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        guard let installation = Installation.current else {
            XCTFail("Should unwrap dates")
            return
        }

        let installationOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        do {
            let deleted = try [installation].deleteAll()
            deleted.forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
                if let newInstallation = Installation.current {
                    XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let deleted = try [installation].deleteAll(transaction: true)
            deleted.forEach {
                if case let .failure(error) = $0 {
                    XCTFail("Should have deleted: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDeleteAllAsyncMainQueueCurrent() throws {
        try testSaveCurrentInstallation()
        MockURLProtocol.removeAll()

        let expectation1 = XCTestExpectation(description: "Delete installation1")
        let expectation2 = XCTestExpectation(description: "Delete installation2")

        guard let installation = Installation.current else {
            XCTFail("Should unwrap")
            expectation1.fulfill()
            expectation2.fulfill()
            return
        }

        let installationOnServer = [BatchResponseItem<NoBody>(success: NoBody(), error: nil)]

        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(installationOnServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            expectation1.fulfill()
            expectation2.fulfill()
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        [installation].deleteAll { results in
            switch results {

            case .success(let deleted):
                deleted.forEach {
                    if case let .failure(error) = $0 {
                        XCTFail("Should have deleted: \(error.localizedDescription)")
                    }
                    if let newInstallation = Installation.current {
                        XCTAssertFalse(installation.hasSameInstallationId(as: newInstallation))
                    }
                }
            case .failure(let error):
                XCTFail("Should have deleted: \(error.localizedDescription)")
            }
            expectation1.fulfill()
        }

        [installation].deleteAll(transaction: true) { results in
            switch results {

            case .success(let deleted):
                deleted.forEach {
                    if case let .failure(error) = $0 {
                        XCTFail("Should have deleted: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                XCTFail("Should have deleted: \(error.localizedDescription)")
            }
            expectation2.fulfill()
        }
        wait(for: [expectation1, expectation2], timeout: 20.0)
    }
}
// swiftlint:disable:this file_length
