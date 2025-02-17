//
//  ParseQueryTests.swift
//  ParseSwiftTests
//
//  Created by Corey Baker on 7/26/20.
//  Copyright © 2020 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseQueryTests: XCTestCase { // swiftlint:disable:this type_body_length

    struct GameScore: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        //: Your own properties
        var score: Int

        //: a custom initializer
        init() {
            self.score = 5
        }
        init(score: Int) {
            self.score = score
        }
    }

    struct GameScoreBroken: ParseObject {
        //: Those are required for Object
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?

        var score: Int? //Left as non-optional to throw error on pointer
    }

    struct AnyResultResponse<U: Codable>: Codable {
        let result: U
    }

    struct AnyResultsResponse<U: Codable>: Codable {
        let results: [U]
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

    // MARK: Initialization
    func testConstructors() {
        let query = Query<GameScore>()
        XCTAssertEqual(query.className, GameScore.className)
        XCTAssertEqual(query.`where`.constraints.values.count, 0)

        let query2 = GameScore.query()
        XCTAssertEqual(query2.className, GameScore.className)
        XCTAssertEqual(query2.className, query.className)
        XCTAssertEqual(query2.`where`.constraints.values.count, 0)

        let query3 = GameScore.query("score" > 100, "createdAt" > Date())
        XCTAssertEqual(query3.className, GameScore.className)
        XCTAssertEqual(query3.className, query.className)
        XCTAssertEqual(query3.`where`.constraints.values.count, 2)

        let query4 = GameScore.query(["score" > 100, "createdAt" > Date()])
        XCTAssertEqual(query4.className, GameScore.className)
        XCTAssertEqual(query4.className, query.className)
        XCTAssertEqual(query4.`where`.constraints.values.count, 2)
    }

    func testCompareQueries() {

        let query1 = GameScore.query("score" > 100, "createdAt" > Date())
        let query2 = GameScore.query([containsString(key: "hello",
                                                     substring: "world"),
                                      "score" > 100,
                                      "createdAt" > Date()])
        let query3 = GameScore.query([containsString(key: "hello",
                                                     substring: "world"),
                                      "score" > 101,
                                      "createdAt" > Date()])
        XCTAssertEqual(query1, query1)
        XCTAssertEqual(query2, query2)
        XCTAssertNotEqual(query1, query2)
        XCTAssertNotEqual(query2, query3)
    }

    func testEndPoints() {
        let query = Query<GameScore>()
        let userQuery = Query<BaseParseUser>()
        let installationQuery = Query<BaseParseInstallation>()
        XCTAssertEqual(query.endpoint.urlComponent, "/classes/GameScore")
        XCTAssertEqual(userQuery.endpoint.urlComponent, "/users")
        XCTAssertEqual(installationQuery.endpoint.urlComponent, "/installations")
    }

    func testStaticProperties() {
        XCTAssertEqual(Query<GameScore>.className, GameScore.className)
    }

    func testSkip() {
        let query = GameScore.query()
        XCTAssertEqual(query.skip, 0)
        let query2 = GameScore.query().skip(1)
        XCTAssertEqual(query2.skip, 1)
    }

    func testLimit() {
        var query = GameScore.query()
        XCTAssertEqual(query.limit, 100)
        query = query.limit(10)
        XCTAssertEqual(query.limit, 10)
    }

    func testOrder() {
        let query = GameScore.query()
        XCTAssertNil(query.order)
        let query2 = GameScore.query().order([.ascending("yolo")])
        XCTAssertNotNil(query2.order)
    }

    func testReadPreferences() {
        let query = GameScore.query()
        XCTAssertNil(query.readPreference)
        XCTAssertNil(query.includeReadPreference)
        XCTAssertNil(query.subqueryReadPreference)
        let query2 = GameScore.query().readPreference("PRIMARY",
                                                includeReadPreference: "SECONDARY",
                                                subqueryReadPreference: "SECONDARY_PREFERRED")
        XCTAssertNotNil(query2.readPreference)
        XCTAssertNotNil(query2.includeReadPreference)
        XCTAssertNotNil(query2.subqueryReadPreference)
    }

    func testIncludeKeys() {
        let query = GameScore.query()
        XCTAssertNil(query.include)
        var query2 = GameScore.query().include(["yolo"])
        XCTAssertEqual(query2.include?.count, 1)
        XCTAssertEqual(query2.include?.first, "yolo")
        query2 = query2.include(["hello", "wow"])
        XCTAssertEqual(query2.include?.count, 3)
        XCTAssertEqual(query2.include, Set(["yolo", "hello", "wow"]))
    }

    func testIncludeKeysVariadic() {
        let query = GameScore.query()
        XCTAssertNil(query.include)
        var query2 = GameScore.query().include("yolo")
        XCTAssertEqual(query2.include?.count, 1)
        XCTAssertEqual(query2.include?.first, "yolo")
        query2 = query2.include("hello", "wow")
        XCTAssertEqual(query2.include?.count, 3)
        XCTAssertEqual(query2.include, Set(["yolo", "hello", "wow"]))
    }

    func testIncludeAllKeys() {
        let query = GameScore.query()
        XCTAssertNil(query.include)
        let query2 = GameScore.query().includeAll()
        XCTAssertEqual(query2.include?.count, 1)
        XCTAssertEqual(query2.include, ["*"])
    }

    func testExcludeKeys() throws {
        let query = GameScore.query()
        XCTAssertNil(query.excludeKeys)
        var query2 = GameScore.query().exclude(["yolo"])
        XCTAssertEqual(query2.excludeKeys, ["yolo"])
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["excludeKeys"],
            let decodedValues = decodedKeys.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["yolo"])

        query2 = query2.exclude(["hello", "wow"])
        XCTAssertEqual(query2.excludeKeys, ["yolo", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["excludeKeys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["yolo", "hello", "wow"]))
    }

    func testExcludeKeysVariadic() throws {
        let query = GameScore.query()
        XCTAssertNil(query.excludeKeys)
        var query2 = GameScore.query().exclude("yolo")
        XCTAssertEqual(query2.excludeKeys, ["yolo"])
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["excludeKeys"],
            let decodedValues = decodedKeys.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["yolo"])

        query2 = query2.exclude("hello", "wow")
        XCTAssertEqual(query2.excludeKeys, ["yolo", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["excludeKeys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["yolo", "hello", "wow"]))
    }

    func testSelectKeys() throws {
        let query = GameScore.query()
        XCTAssertNil(query.keys)

        var query2 = GameScore.query().select(["yolo"])
        XCTAssertEqual(query2.keys?.count, 1)
        XCTAssertEqual(query2.keys?.first, "yolo")
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["keys"],
            let decodedValues = decodedKeys.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["yolo"])

        query2 = query2.select(["hello", "wow"])
        XCTAssertEqual(query2.keys?.count, 3)
        XCTAssertEqual(query2.keys, ["yolo", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["keys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["yolo", "hello", "wow"]))
    }

    func testSelectKeysVariadic() throws {
        let query = GameScore.query()
        XCTAssertNil(query.keys)

        var query2 = GameScore.query().select("yolo")
        XCTAssertEqual(query2.keys?.count, 1)
        XCTAssertEqual(query2.keys?.first, "yolo")
        let encoded = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
        guard let decodedKeys = decodedDictionary["keys"],
            let decodedValues = decodedKeys.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(decodedValues, ["yolo"])

        query2 = query2.select("hello", "wow")
        XCTAssertEqual(query2.keys?.count, 3)
        XCTAssertEqual(query2.keys, ["yolo", "hello", "wow"])
        let encoded2 = try ParseCoding.jsonEncoder().encode(query2)
        let decodedDictionary2 = try JSONDecoder().decode([String: AnyCodable].self, from: encoded2)
        guard let decodedKeys2 = decodedDictionary2["keys"],
            let decodedValues2 = decodedKeys2.value as? [String] else {
            XCTFail("Should have casted")
            return
        }
        XCTAssertEqual(Set(decodedValues2), Set(["yolo", "hello", "wow"]))
    }

    func testAddingConstraints() {
        var query = GameScore.query()
        XCTAssertEqual(query.className, GameScore.className)
        XCTAssertEqual(query.className, query.className)
        XCTAssertEqual(query.`where`.constraints.values.count, 0)

        query = query.`where`("score" > 100, "createdAt" > Date())
        XCTAssertEqual(query.`where`.constraints.values.count, 2)
    }

    #if !os(Linux) && !os(Android)
    func testFindCommand() throws {
        let query = GameScore.query()
        let command = query.findCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"path\":\"\\/classes\\/GameScore\",\"method\":\"POST\",\"body\":{\"limit\":100,\"skip\":0,\"_method\":\"GET\",\"where\":{}}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testQueryEncoding() throws {
        let query = GameScore.query()
        let expected = "GameScore ({\"limit\":100,\"skip\":0,\"_method\":\"GET\",\"where\":{}})"
        XCTAssertEqual(query.debugDescription, expected)
        XCTAssertEqual(query.description, expected)
    }

    func testFindExplainCommand() throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<Query<ParseQueryTests.GameScore>,
                                             [GameScore]> = query.findExplainCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"path\":\"\\/classes\\/GameScore\",\"method\":\"POST\",\"body\":{\"limit\":100,\"skip\":0,\"explain\":true,\"_method\":\"GET\",\"where\":{}}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }
    #endif

    // MARK: Querying Parse Server
    func testFind() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {

            guard let score = try query.find(options: []).first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func testFindLimit() {
        let query = GameScore.query()
            .limit(0)
        do {
            let scores = try query.find(options: [])
            XCTAssert(scores.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    // MARK: Querying Parse Server
    func testFindEncoded() throws {

        let afterDate = Date().addingTimeInterval(-300)
        let query = GameScore.query("createdAt" > afterDate)
        let encodedJSON = try ParseCoding.jsonEncoder().encode(query)
        let decodedJSON = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedJSON)
        let encodedParse = try ParseCoding.jsonEncoder().encode(query)
        let decodedParse = try ParseCoding.jsonDecoder().decode([String: AnyCodable].self, from: encodedParse)

        guard let jsonSkipAny = decodedJSON["skip"],
              let jsonSkip = jsonSkipAny.value as? Int,
              let jsonMethodAny = decodedJSON["_method"],
              let jsonMethod = jsonMethodAny.value as? String,
              let jsonLimitAny = decodedJSON["limit"],
              let jsonLimit = jsonLimitAny.value as? Int,
              let jsonWhereAny = decodedJSON["where"],
              let jsonWhere = jsonWhereAny.value as? [String: [String: [String: String]]] else {
            XCTFail("Should have casted all")
            return
        }

        guard let parseSkipAny = decodedParse["skip"],
              let parseSkip = parseSkipAny.value as? Int,
              let parseMethodAny = decodedParse["_method"],
              let parseMethod = parseMethodAny.value as? String,
              let parseLimitAny = decodedParse["limit"],
              let parseLimit = parseLimitAny.value as? Int,
              let parseWhereAny = decodedParse["where"],
              let parseWhere = parseWhereAny.value as? [String: [String: [String: String]]] else {
            XCTFail("Should have casted all")
            return
        }

        XCTAssertEqual(jsonSkip, parseSkip, "Parse shoud always match JSON")
        XCTAssertEqual(jsonMethod, parseMethod, "Parse shoud always match JSON")
        XCTAssertEqual(jsonLimit, parseLimit, "Parse shoud always match JSON")
        XCTAssertEqual(jsonWhere, parseWhere, "Parse shoud always match JSON")
    }

    func findAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.find(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android)
    func testThreadSafeFindAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            findAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFindAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        findAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testFindLimitAsync() {
        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Count object1")
        query.find { results in
            switch results {

            case .success(let scores):
                XCTAssert(scores.isEmpty)
            case .failure(let error):
                XCTFail(error.description)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = AnyResultsResponse(results: [scoreOnServer])
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllAsyncErrorSkip() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = AnyResultsResponse(results: [scoreOnServer])
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        var query = GameScore.query()
        query.skip = 10
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { result in

            switch result {

            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("Cannot iterate"))
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllAsyncErrorOrder() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = AnyResultsResponse(results: [scoreOnServer])
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let query = GameScore.query()
            .order([.ascending("score")])
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { result in

            switch result {

            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("Cannot iterate"))
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllAsyncErrorLimit() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = AnyResultsResponse(results: [scoreOnServer])
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        var query = GameScore.query()
        query.limit = 10
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { result in

            switch result {

            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                XCTAssertTrue(error.message.contains("Cannot iterate"))
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testFindAllLimit() {
        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Count object1")
        query.findAll { results in
            switch results {

            case .success(let scores):
                XCTAssert(scores.isEmpty)
            case .failure(let error):
                XCTFail(error.description)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android)
    func testFirstCommand() throws {
        let query = GameScore.query()
        let command = query.firstCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"path\":\"\\/classes\\/GameScore\",\"method\":\"POST\",\"body\":{\"limit\":1,\"skip\":0,\"_method\":\"GET\",\"where\":{}}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testFirstExplainCommand() throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<Query<ParseQueryTests.GameScore>,
                                             GameScore> = query.firstExplainCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"path\":\"\\/classes\\/GameScore\",\"method\":\"POST\",\"body\":{\"limit\":1,\"skip\":0,\"explain\":true,\"_method\":\"GET\",\"where\":{}}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }
    #endif

    func testFirst() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {
            let score = try query.first(options: [])
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testFirstThrowDecodingError() {
        var scoreOnServer = GameScoreBroken()
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScoreBroken>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {
            _ = try query.first(options: [])
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should have casted as ParseError")
                return
            }
            #if !os(Linux) && !os(Android)
            // swiftlint:disable:next line_length
            XCTAssertEqual(error.message, "Invalid struct: No value associated with key CodingKeys(stringValue: \"score\", intValue: nil) (\"score\").")
            XCTAssertEqual(error.code, .unknownError)
            #endif
        }
        XCTAssertThrowsError(try query.first(options: []))
    }

    func testFirstNoObjectFound() {

        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {
            _ = try query.first(options: [])
            XCTFail("Should have thrown error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should have casted as ParseError")
                return
            }
            XCTAssertEqual(error.code, .objectNotFound)
        }

    }

    func testFirstLimit() {
        let query = GameScore.query()
            .limit(0)
        XCTAssertThrowsError(try query.first())
    }

    func firstAsyncNoObjectFound(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.first(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success:
                XCTFail("Should have failed")

            case .failure(let error):
                XCTAssertEqual(error.code, .objectNotFound)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func firstAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.first(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let score):
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android)
    func testThreadSafeFirstAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            firstAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFirstAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        firstAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    #if !os(Linux) && !os(Android)
    func testThreadSafeFirstAsyncNoObjectFound() {
        let scoreOnServer = GameScore(score: 10)
        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            firstAsyncNoObjectFound(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testFirstAsyncNoObjectFoundMainQueue() {
        let scoreOnServer = GameScore(score: 10)
        let results = QueryResponse<GameScore>(results: [GameScore](), count: 0)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        firstAsyncNoObjectFound(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testFirstAsyncLimit() {
        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Find object1")
        query.first { results in
            switch results {

            case .success:
                XCTFail("Should have thrown error.")
            case .failure(let error):
                XCTAssertEqual(error.code, .objectNotFound)

            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android)
    func testCountCommand() throws {
        let query = GameScore.query()
        let command = query.countCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"path\":\"\\/classes\\/GameScore\",\"method\":\"POST\",\"body\":{\"limit\":1,\"skip\":0,\"count\":true,\"_method\":\"GET\",\"where\":{}}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testCountExplainCommand() throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<Query<ParseQueryTests.GameScore>,
                                             [Int]> = query.countExplainCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"path\":\"\\/classes\\/GameScore\",\"method\":\"POST\",\"body\":{\"limit\":1,\"skip\":0,\"explain\":true,\"count\":true,\"_method\":\"GET\",\"where\":{}}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }
    #endif

    func testCount() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {

            let scoreCount = try query.count(options: [])
            XCTAssertEqual(scoreCount, 1)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }

    func testCountLimit() throws {
        let query = GameScore.query()
            .limit(0)
        let count = try query.count()
        XCTAssertEqual(count, 0)
    }

    func countAsync(scoreOnServer: GameScore, callbackQueue: DispatchQueue) {
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        query.count(options: [], callbackQueue: callbackQueue) { result in

            switch result {

            case .success(let scoreCount):
                XCTAssertEqual(scoreCount, 1)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android)
    func testThreadSafeCountAsync() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        DispatchQueue.concurrentPerform(iterations: 100) {_ in
            countAsync(scoreOnServer: scoreOnServer, callbackQueue: .global(qos: .background))
        }
    }
    #endif

    func testCountAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        countAsync(scoreOnServer: scoreOnServer, callbackQueue: .main)
    }

    func testCountAsyncLimit() throws {
        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Count object1")
        query.count { result in
            switch result {

            case .success(let count):
                XCTAssertEqual(count, 0)
            case .failure(let error):
                XCTFail(error.description)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    // MARK: Standard Conditions
    func testWhereKeyExists() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$exists": true]
        ]
        let constraint = exists(key: "yolo")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Bool],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: Bool] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotExist() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$exists": false]
        ]
        let constraint = doesNotExist(key: "yolo")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Bool],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: Bool] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyEqualTo() {
        let expected: [String: String] = [
            "yolo": "yarr"
        ]
        let query = GameScore.query("yolo" == "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decoded = try JSONDecoder().decode([String: String].self, from: encoded)

            XCTAssertEqual(expected, decoded)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyEqualToParseObjectError() throws {
        let compareObject = GameScore(score: 11)
        XCTAssertThrowsError(try GameScore.query("yolo" == compareObject))
    }

    #if !os(Linux) && !os(Android)
    func testWhereKeyEqualToParseObject() throws {
        var compareObject = GameScore(score: 11)
        compareObject.objectId = "hello"
        let query = try GameScore.query("yolo" == compareObject)
        // swiftlint:disable:next line_length
        let expected = "GameScore ({\"limit\":100,\"skip\":0,\"_method\":\"GET\",\"where\":{\"yolo\":{\"__type\":\"Pointer\",\"className\":\"GameScore\",\"objectId\":\"hello\"}}})"
        XCTAssertEqual(query.debugDescription, expected)
    }
    #endif

    func testWhereKeyNotEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$ne": "yarr"]
        ]
        let query = GameScore.query("yolo" != "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyLessThan() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$lt": "yarr"]
        ]
        let query = GameScore.query("yolo" < "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyLessThanOrEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$lte": "yarr"]
        ]
        let query = GameScore.query("yolo" <= "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyGreaterThan() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$gt": "yarr"]
        ]
        let query = GameScore.query("yolo" > "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyGreaterThanOrEqualTo() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$gte": "yarr"]
        ]
        let query = GameScore.query("yolo" >= "yarr")
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesText() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$text": ["$search": ["$term": "yarr"]]]
        ]
        let constraint = matchesText(key: "yolo", text: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [String: String]]],
                  let decodedValues = decodedDictionary.values.first?.value as?
                    [String: [String: [String: String]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesRegex() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "yarr"]
        ]
        let constraint = matchesRegex(key: "yolo", regex: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesRegexModifiers() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$regex": "yarr",
                "$options": "i"
            ]
        ]
        let constraint = matchesRegex(key: "yolo", regex: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyContainsString() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E"]
        ]
        let constraint = containsString(key: "yolo", substring: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyContainsStringModifier() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E",
                     "$options": "i"]
        ]
        let constraint = containsString(key: "yolo", substring: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasPrefix() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "^\\Qyarr\\E"]
        ]
        let constraint = hasPrefix(key: "yolo", prefix: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasPrefixModifier() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "^\\Qyarr\\E",
                     "$options": "i"]
        ]
        let constraint = hasPrefix(key: "yolo", prefix: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasSuffix() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E$"]
        ]
        let constraint = hasSuffix(key: "yolo", suffix: "yarr")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyHasSuffixModifier() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$regex": "\\Qyarr\\E$",
                     "$options": "i"]
        ]
        let constraint = hasSuffix(key: "yolo", suffix: "yarr", modifiers: "i")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: String],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: String] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testOrQuery() {
        let expected: [String: AnyCodable] = [
            "$or": [
                ["score": ["$lte": 50]],
                ["score": ["$lte": 200]]
            ]
        ]
        let query1 = GameScore.query("score" <= 50)
        let query2 = GameScore.query("score" <= 200)
        let constraint = or(queries: [query1, query2])
        let query = Query<GameScore>(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [[String: [String: Int]]],
                  let decodedValues = decodedDictionary.values.first?.value as? [[String: [String: Int]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testNorQuery() {
        let expected: [String: AnyCodable] = [
            "$nor": [
                ["score": ["$lte": 50]],
                ["score": ["$lte": 200]]
            ]
        ]
        let query1 = GameScore.query("score" <= 50)
        let query2 = GameScore.query("score" <= 200)
        let constraint = nor(queries: [query1, query2])
        let query = Query<GameScore>(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [[String: [String: Int]]],
                  let decodedValues = decodedDictionary.values.first?.value as? [[String: [String: Int]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testAndQuery() {
        let expected: [String: AnyCodable] = [
            "$and": [
                ["score": ["$lte": 50]],
                ["score": ["$lte": 200]]
            ]
        ]
        let query1 = GameScore.query("score" <= 50)
        let query2 = GameScore.query("score" <= 200)
        let constraint = and(queries: [query1, query2])
        let query = Query<GameScore>(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [[String: [String: Int]]],
                  let decodedValues = decodedDictionary.values.first?.value as? [[String: [String: Int]]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesKeyInQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$select": [
                    "query": ["where": ["test": ["$lte": "awk"]]],
                    "key": "yolo1"
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let constraint = matchesKeyInQuery(key: "yolo", queryKey: "yolo1", query: inQuery)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedSelect = expectedValues["$select"],
                  let expectedKeyValue = expectedSelect["key"] as? String,
                  let expectedKeyQuery = expectedSelect["query"] as? [String: Any],
                  let expectedKeyWhere = expectedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedSelect = decodedValues["$select"],
                  let decodedKeyValue = decodedSelect["key"] as? String,
                  let decodedKeyQuery = decodedSelect["query"] as? [String: Any],
                  let decodedKeyWhere = decodedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyValue, decodedKeyValue)
            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotMatchKeyInQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$dontSelect": [
                    "query": ["where": ["test": ["$lte": "awk"]]],
                    "key": "yolo1"
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let constraint = doesNotMatchKeyInQuery(key: "yolo", queryKey: "yolo1", query: inQuery)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedSelect = expectedValues["$dontSelect"],
                  let expectedKeyValue = expectedSelect["key"] as? String,
                  let expectedKeyQuery = expectedSelect["query"] as? [String: Any],
                  let expectedKeyWhere = expectedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedSelect = decodedValues["$dontSelect"],
                  let decodedKeyValue = decodedSelect["key"] as? String,
                  let decodedKeyQuery = decodedSelect["query"] as? [String: Any],
                  let decodedKeyWhere = decodedKeyQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyValue, decodedKeyValue)
            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyMatchesQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$inQuery": [
                    "where": ["test": ["$lte": "awk"]]
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let query = GameScore.query("yolo" == inQuery)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedInQuery = expectedValues["$inQuery"],
                  let expectedKeyWhere = expectedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedInQuery = decodedValues["$inQuery"],
                  let decodedKeyWhere = decodedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyDoesNotMatchQuery() {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$notInQuery": [
                    "where": ["test": ["$lte": "awk"]]
                ]
            ]
        ]
        let inQuery = GameScore.query("test" <= "awk")
        let query = GameScore.query("yolo" != inQuery)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedInQuery = expectedValues["$notInQuery"],
                  let expectedKeyWhere = expectedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedInQuery = decodedValues["$notInQuery"],
                  let decodedKeyWhere = decodedInQuery["where"] as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKeyWhere, decodedKeyWhere)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainedIn() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$in": ["yarr"]]
        ]
        let constraint = containedIn(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainedBy() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$containedBy": ["yarr"]]
        ]
        let constraint = containedBy(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereNotContainedIn() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nin": ["yarr"]]
        ]
        let constraint = notContainedIn(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereContainsAll() {
        let expected: [String: AnyCodable] = [
            "yolo": ["$all": ["yarr"]]
        ]
        let constraint = containsAll(key: "yolo", array: ["yarr"])
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String]],
                  let decodedValues = decodedDictionary.values.first?.value as? [String: [String]] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelated() throws {
        let expected: [String: AnyCodable] = [
            "$relatedTo": [
                "key": "yolo",
                "object": ["__type": "Pointer",
                           "className": "GameScore",
                           "objectId": "hello"]
            ]
        ]
        var object = GameScore(score: 50)
        object.objectId = "hello"
        let constraint = related(key: "yolo", object: try object.toPointer())
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedKey = expectedValues["key"] as? String,
                  let expectedObject = expectedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedKey = decodedValues["key"] as? String,
                  let decodedObject = decodedValues["object"] as? [String: String] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedKey, decodedKey)
            XCTAssertEqual(expectedObject, decodedObject)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyRelativeToTime() throws {
        let expected: [String: AnyCodable] = [
            "yolo": [
                "$gte": ["$relativeTime": "3 days ago"]
            ]
        ]
        var object = GameScore(score: 50)
        object.objectId = "hello"
        let constraint = relative("yolo" >= "3 days ago")
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected
                    .values
                    .first?.value as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary
                    .values
                    .first?.value as? [String: [String: String]] else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedValues, decodedValues)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // MARK: GeoPoint
    func testWhereKeyNearGeoPoint() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"]]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = near(key: "yolo", geoPoint: geoPoint)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: Any]],
                  let expectedLongitude = expectedValues["$nearSphere"]?["longitude"] as? Int,
                  let expectedLatitude = expectedValues["$nearSphere"]?["latitude"] as? Int,
                  let expectedType = expectedValues["$nearSphere"]?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: Any]],
                  let decodedLongitude = decodedValues["$nearSphere"]?["longitude"] as? Int,
                  let decodedLatitude = decodedValues["$nearSphere"]?["latitude"] as? Int,
                  let decodedType = decodedValues["$nearSphere"]?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    #if !os(Linux) && !os(Android)
    func testWhereKeyNearGeoPointWithinMiles() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$maxDistance": 1
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinMiles(key: "yolo", geoPoint: geoPoint, distance: 3958.8)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinMilesNotSorted() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$centerSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$geoWithin": 1
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinMiles(key: "yolo",
                                     geoPoint: geoPoint,
                                     distance: 3958.8,
                                     sorted: false)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$centerSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$centerSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinKilometers() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$maxDistance": 1
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinKilometers(key: "yolo", geoPoint: geoPoint, distance: 6371.0)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinKilometersNotSorted() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$centerSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$geoWithin": 1
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinKilometers(key: "yolo",
                                          geoPoint: geoPoint,
                                          distance: 6371.0,
                                          sorted: false)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$centerSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$centerSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinRadians() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$nearSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$maxDistance": 10
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinRadians(key: "yolo", geoPoint: geoPoint, distance: 10.0)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$nearSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$nearSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$maxDistance"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyNearGeoPointWithinRadiansNotSorted() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$centerSphere": ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                     "$geoWithin": 10
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = withinRadians(key: "yolo", geoPoint: geoPoint, distance: 10.0, sorted: false)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: Any],
                  let expectedNear = expectedValues["$centerSphere"] as? [String: Any],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String,
                  let expectedDistance = expectedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: Any],
                  let decodedNear = decodedValues["$centerSphere"] as? [String: Any],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String,
                  let decodedDistance = decodedValues["$geoWithin"] as? Int else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedDistance, decodedDistance)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }
    #endif

    // swiftlint:disable:next function_body_length
    func testWhereKeyNearGeoBox() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$within": ["$box": [
                                    ["latitude": 10, "longitude": 20, "__type": "GeoPoint"],
                                    ["latitude": 20, "longitude": 30, "__type": "GeoPoint"]]
                                ]
            ]
        ]
        let geoPoint1 = try ParseGeoPoint(latitude: 10, longitude: 20)
        let geoPoint2 = try ParseGeoPoint(latitude: 20, longitude: 30)
        let constraint = withinGeoBox(key: "yolo", fromSouthWest: geoPoint1, toNortheast: geoPoint2)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [[String: Any]]]],
                  let expectedBox = expectedValues["$within"]?["$box"],
                  let expectedLongitude = expectedBox.first?["longitude"] as? Int,
                  let expectedLatitude = expectedBox.first?["latitude"] as? Int,
                  let expectedType = expectedBox.first?["__type"] as? String,
                  let expectedLongitude2 = expectedBox.last?["longitude"] as? Int,
                  let expectedLatitude2 = expectedBox.last?["latitude"] as? Int,
                  let expectedType2 = expectedBox.last?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [[String: Any]]]],
                  let decodedBox = decodedValues["$within"]?["$box"],
                  let decodedLongitude = decodedBox.first?["longitude"] as? Int,
                  let decodedLatitude = decodedBox.first?["latitude"] as? Int,
                  let decodedType = decodedBox.first?["__type"] as? String,
                  let decodedLongitude2 = decodedBox.last?["longitude"] as? Int,
                  let decodedLatitude2 = decodedBox.last?["latitude"] as? Int,
                  let decodedType2 = decodedBox.last?["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)
            XCTAssertEqual(expectedLongitude2, decodedLongitude2)
            XCTAssertEqual(expectedLatitude2, decodedLatitude2)
            XCTAssertEqual(expectedType2, decodedType2)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // swiftlint:disable:next function_body_length
    func testWhereKeyWithinPolygonPoints() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$geoWithin": ["$polygon": [
                                        [10.1, 20.1],
                                        [20.1, 30.1],
                                        [30.1, 40.1]]
                                ]
            ]
        ]
        let geoPoint1 = try ParseGeoPoint(latitude: 10.1, longitude: 20.1)
        let geoPoint2 = try ParseGeoPoint(latitude: 20.1, longitude: 30.1)
        let geoPoint3 = try ParseGeoPoint(latitude: 30.1, longitude: 40.1)
        let polygon = [geoPoint1, geoPoint2, geoPoint3]
        let constraint = withinPolygon(key: "yolo", points: polygon)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [[Double]]]],
                  let expectedBox = expectedValues["$geoWithin"]?["$polygon"] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [[Double]]]],
                  let decodedBox = decodedValues["$geoWithin"]?["$polygon"] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedBox, decodedBox)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // swiftlint:disable:next function_body_length
    func testWhereKeyWithinPolygon() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$geoWithin": ["$polygon": [
                                        [10.1, 20.1],
                                        [20.1, 30.1],
                                        [30.1, 40.1]]
                                ]
            ]
        ]
        let geoPoint1 = try ParseGeoPoint(latitude: 10.1, longitude: 20.1)
        let geoPoint2 = try ParseGeoPoint(latitude: 20.1, longitude: 30.1)
        let geoPoint3 = try ParseGeoPoint(latitude: 30.1, longitude: 40.1)
        let polygon = try ParsePolygon(geoPoint1, geoPoint2, geoPoint3)
        let constraint = withinPolygon(key: "yolo", polygon: polygon)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [[Double]]]],
                  let expectedBox = expectedValues["$geoWithin"]?["$polygon"] else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [[Double]]]],
                  let decodedBox = decodedValues["$geoWithin"]?["$polygon"] else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertEqual(expectedBox, decodedBox)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    func testWhereKeyPolygonContains() throws {
        let expected: [String: AnyCodable] = [
            "yolo": ["$geoIntersects": ["$point":
                                    ["latitude": 10, "longitude": 20, "__type": "GeoPoint"]
                                ]
            ]
        ]
        let geoPoint = try ParseGeoPoint(latitude: 10, longitude: 20)
        let constraint = polygonContains(key: "yolo", point: geoPoint)
        let query = GameScore.query(constraint)
        let queryWhere = query.`where`

        do {
            let encoded = try ParseCoding.jsonEncoder().encode(queryWhere)
            let decodedDictionary = try JSONDecoder().decode([String: AnyCodable].self, from: encoded)
            XCTAssertEqual(expected.keys, decodedDictionary.keys)

            guard let expectedValues = expected.values.first?.value as? [String: [String: [String: Any]]],
                  let expectedNear = expectedValues["$geoIntersects"]?["$point"],
                  let expectedLongitude = expectedNear["longitude"] as? Int,
                  let expectedLatitude = expectedNear["latitude"] as? Int,
                  let expectedType = expectedNear["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            guard let decodedValues = decodedDictionary.values.first?.value as? [String: [String: [String: Any]]],
                  let decodedNear = decodedValues["$geoIntersects"]?["$point"],
                  let decodedLongitude = decodedNear["longitude"] as? Int,
                  let decodedLatitude = decodedNear["latitude"] as? Int,
                  let decodedType = decodedNear["__type"] as? String else {
                XCTFail("Should have casted")
                return
            }

            XCTAssertEqual(expectedLongitude, decodedLongitude)
            XCTAssertEqual(expectedLatitude, decodedLatitude)
            XCTAssertEqual(expectedType, decodedType)

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
    }

    // MARK: JSON Responses
    func testExplainFindSynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
        do {
            let queryResult: [[String: String]] = try query.findExplain()
            XCTAssertEqual(queryResult, json.results)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testExplainFindLimitSynchronous() {
        let query = GameScore.query()
            .limit(0)
        do {
            let queryResult: [[String: String]] = try query.findExplain()
            XCTAssertTrue(queryResult.isEmpty)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testExplainFindAsynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.findExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainFindLimitAsynchronous() {

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .limit(0)
        query.findExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertTrue(queryResult.isEmpty)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainFirstSynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
        do {
            let queryResult: [String: String] = try query.firstExplain()
            XCTAssertEqual(queryResult, json.results.first)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testExplainFirstLimitSynchronous() {
        let query = GameScore.query()
            .limit(0)
        do {
            let _: [[String: String]] = try query.firstExplain()
            XCTFail("Should have produced error")
        } catch {
            guard let error = error as? ParseError else {
                XCTFail("Should have casted as ParseError")
                return
            }
            XCTAssertEqual(error.code, .objectNotFound)
        }
    }

    func testExplainFirstAsynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.firstExplain(callbackQueue: .main) { (result: Result<[String: String], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results.first)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainFirstLimitAsynchronous() {

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .limit(0)
        query.firstExplain(callbackQueue: .main) { (result: Result<[String: String], ParseError>) in
            switch result {

            case .success:
                XCTFail("Should have produced error")
            case .failure(let error):
                XCTAssertEqual(error.code, .objectNotFound)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainCountSynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
        do {
            let queryResult: [[String: String]] = try query.countExplain()
            XCTAssertEqual(queryResult, json.results)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testExplainCountLimitSynchronous() {

        let query = GameScore.query()
            .limit(0)
        do {
            let queryResult: [[String: String]] = try query.countExplain()
            XCTAssertTrue(queryResult.isEmpty)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testExplainCountAsynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
        query.countExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testExplainCountLimitAsynchronous() {

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .limit(0)
        query.countExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertTrue(queryResult.isEmpty)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintFindSynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
            .hint("_id_")
        do {
            let queryResult: [[String: String]] = try query.findExplain()
            XCTAssertEqual(queryResult, json.results)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testHintFindAsynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .hint("_id_")
        query.findExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintFirstSynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
            .hint("_id_")
        do {
            let queryResult: [String: String] = try query.firstExplain()
            XCTAssertEqual(queryResult, json.results.first)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testHintFirstAsynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .hint("_id_")
        query.firstExplain(callbackQueue: .main) { (result: Result<[String: String], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results.first)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testHintCountSynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query()
            .hint("_id_")
        do {
            let queryResult: [[String: String]] = try query.countExplain()
            XCTAssertEqual(queryResult, json.results)
        } catch {
            XCTFail("Error: \(error)")
        }
    }

    func testHintCountAsynchronous() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let expectation = XCTestExpectation(description: "Fetch object")
        let query = GameScore.query()
            .hint("_id_")
        query.countExplain(callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in
            switch result {

            case .success(let queryResult):
                XCTAssertEqual(queryResult, json.results)
            case .failure(let error):
                XCTFail("Error: \(error)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    #if !os(Linux) && !os(Android)
    func testAggregateCommand() throws {
        var query = GameScore.query()
        let value = AnyEncodable("world")
        query.pipeline = [["hello": value]]
        let aggregate = query.aggregateCommand()
        // swiftlint:disable:next line_length
        let expected = "{\"path\":\"\\/aggregate\\/GameScore\",\"method\":\"POST\",\"body\":{\"pipeline\":[{\"hello\":\"\(value)\"}]}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(aggregate)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testAggregateExplainCommand() throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<AggregateBody<GameScore>,
                                             [String]> = query.aggregateExplainCommand()
        let expected = "{\"path\":\"\\/aggregate\\/GameScore\",\"method\":\"POST\",\"body\":{\"explain\":true}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testDistinctCommand() throws {
        let query = GameScore.query()
        let aggregate = query.distinctCommand(key: "hello")
        let expected = "{\"path\":\"\\/aggregate\\/GameScore\",\"method\":\"POST\",\"body\":{\"distinct\":\"hello\"}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(aggregate)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }

    func testDistinctExplainCommand() throws {
        let query = GameScore.query()
        let command: API.NonParseBodyCommand<DistinctBody<GameScore>,
                                             [String]> = query.distinctExplainCommand(key: "hello")
        // swiftlint:disable:next line_length
        let expected = "{\"path\":\"\\/aggregate\\/GameScore\",\"method\":\"POST\",\"body\":{\"explain\":true,\"distinct\":\"hello\"}}"
        let encoded = try ParseCoding.jsonEncoder()
            .encode(command)
        let decoded = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertEqual(decoded, expected)
    }
    #endif

    func testAggregate() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query()
        do {
            let pipeline = [["hello": "world"]]
            guard let score = try query.aggregate(pipeline).first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAggregateWithWhere() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query("score" > 9)
        do {
            let pipeline = [[String: String]]()
            guard let score = try query.aggregate(pipeline).first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAggregateLimit() {

        let query = GameScore.query()
            .limit(0)
        do {
            let pipeline = [["hello": "world"]]
            let scores = try query.aggregate(pipeline)
            XCTAssertTrue(scores.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAggregateExplainWithWhere() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query("score" > 9)
        do {
            let pipeline = [[String: String]]()
            guard let score: [String: String] = try query.aggregateExplain(pipeline).first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssertEqual(score, json.results.first)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAggregateExplainWithWhereLimit() {

        let query = GameScore.query("score" > 9)
            .limit(0)
        do {
            let pipeline = [[String: String]]()
            let scores: [[String: String]] = try query.aggregateExplain(pipeline)
            XCTAssertTrue(scores.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAggregateAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = Date()
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let query = GameScore.query()
        let expectation = XCTestExpectation(description: "Count object1")
        let pipeline = [[String: AnyEncodable]]()
        query.aggregate(pipeline, options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateWhereAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let query = GameScore.query("score" > 9)
        let expectation = XCTestExpectation(description: "Aggregate object1")
        let pipeline = [[String: AnyEncodable]]()
        query.aggregate(pipeline, options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateAsyncMainQueueLimit() {

        let query = GameScore.query()
            .limit(0)
        let expectation = XCTestExpectation(description: "Count object1")
        let pipeline = [[String: AnyEncodable]]()
        query.aggregate(pipeline, options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                XCTAssertTrue(found.isEmpty)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateExplainAsyncMainQueue() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let expectation = XCTestExpectation(description: "Aggregate object1")
        let pipeline = [[String: String]]()
        let query = GameScore.query("score" > 9)
        query.aggregateExplain(pipeline,
                               options: [],
                               callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(score, json.results.first)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testAggregateExplainAsyncMainQueueLimit() {

        let expectation = XCTestExpectation(description: "Aggregate object1")
        let pipeline = [[String: String]]()
        let query = GameScore.query("score" > 9)
            .limit(0)
        query.aggregateExplain(pipeline,
                               options: [],
                               callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in

            switch result {

            case .success(let found):
                XCTAssertTrue(found.isEmpty)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testDistinct() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }

        let query = GameScore.query("score" > 9)
        do {
            guard let score = try query.distinct("hello").first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssert(score.hasSameObjectId(as: scoreOnServer))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDistinctLimit() {

        let query = GameScore.query("score" > 9)
            .limit(0)
        do {
            let scores = try query.distinct("hello")
            XCTAssertTrue(scores.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDistinctExplain() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        let query = GameScore.query("score" > 9)
        do {
            guard let score: [String: String] = try query.distinctExplain("hello").first else {
                XCTFail("Should unwrap first object found")
                return
            }
            XCTAssertEqual(score, json.results.first)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDistinctExplainLimit() {

        let query = GameScore.query("score" > 9)
            .limit(0)
        do {
            let scores: [[String: String]] = try query.distinctExplain("hello")
            XCTAssertTrue(scores.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDistinctAsyncMainQueue() {
        var scoreOnServer = GameScore(score: 10)
        scoreOnServer.objectId = "yarr"
        scoreOnServer.createdAt = Date()
        scoreOnServer.updatedAt = scoreOnServer.createdAt
        scoreOnServer.ACL = nil

        let results = QueryResponse<GameScore>(results: [scoreOnServer], count: 1)
        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try ParseCoding.jsonEncoder().encode(results)
                return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
            } catch {
                return nil
            }
        }
        let query = GameScore.query("score" > 9)
        let expectation = XCTestExpectation(description: "Distinct object1")
        query.distinct("hello", options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssert(score.hasSameObjectId(as: scoreOnServer))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testDistinctAsyncMainQueueLimit() {
        let query = GameScore.query("score" > 9)
            .limit(0)
        let expectation = XCTestExpectation(description: "Distinct object1")
        query.distinct("hello", options: [], callbackQueue: .main) { result in

            switch result {

            case .success(let found):
                XCTAssertTrue(found.isEmpty)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testDistinctExplainAsyncMainQueue() {
        let json = AnyResultsResponse(results: [["yolo": "yarr"]])

        let encoded: Data!
        do {
            encoded = try JSONEncoder().encode(json)
        } catch {
            XCTFail("Should encode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }
        let expectation = XCTestExpectation(description: "Aggregate object1")
        let query = GameScore.query("score" > 9)
        query.distinctExplain("hello",
                              options: [],
                              callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in

            switch result {

            case .success(let found):
                guard let score = found.first else {
                    XCTFail("Should unwrap score count")
                    expectation.fulfill()
                    return
                }
                XCTAssertEqual(score, json.results.first)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }

    func testDistinctExplainAsyncMainQueueLimit() {
        let expectation = XCTestExpectation(description: "Aggregate object1")
        let query = GameScore.query("score" > 9)
            .limit(0)
        query.distinctExplain("hello",
                              options: [],
                              callbackQueue: .main) { (result: Result<[[String: String]], ParseError>) in

            switch result {

            case .success(let found):
                XCTAssertTrue(found.isEmpty)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 20.0)
    }
}
// swiftlint:disable:this file_length
