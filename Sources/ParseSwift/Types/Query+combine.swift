//
//  Query+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension Query {

    // MARK: Queryable - Combine

    /**
     Finds objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func findPublisher(options: API.Options = []) -> Future<[ResultType], ParseError> {
        Future { promise in
            self.find(options: options,
                      completion: promise)
        }
    }

    /**
     Query plan information for finding objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func findExplainPublisher<U: Decodable>(options: API.Options = []) -> Future<[U], ParseError> {
        Future { promise in
            self.findExplain(options: options,
                             completion: promise)
        }
    }

    /**
     Retrieves *asynchronously* a complete list of `ParseObject`'s  that satisfy this query
     and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the items to be batched.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: The items are processed in an unspecified order. The query may not have any sort
     order, and may not use limit or skip.
    */
    func findAllPublisher(batchLimit: Int? = nil,
                          options: API.Options = []) -> Future<[ResultType], ParseError> {
        Future { promise in
            self.findAll(batchLimit: batchLimit,
                         options: options,
                         completion: promise)
        }
    }

    /**
     Gets an object *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func firstPublisher(options: API.Options = []) -> Future<ResultType, ParseError> {
        Future { promise in
            self.first(options: options,
                       completion: promise)
        }
    }

    /**
     Query plan information for getting an object *asynchronously* and publishes when complete.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func firstExplainPublisher<U: Decodable>(options: API.Options = []) -> Future<U, ParseError> {
        Future { promise in
            self.firstExplain(options: options,
                              completion: promise)
        }
    }

    /**
     Count objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func countPublisher(options: API.Options = []) -> Future<Int, ParseError> {
        Future { promise in
            self.count(options: options,
                       completion: promise)
        }
    }

    /**
     Query plan information for counting objects *asynchronously* and publishes when complete.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter explain: Used to toggle the information on the query plan.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func countExplainPublisher<U: Decodable>(options: API.Options = []) -> Future<[U], ParseError> {
        Future { promise in
            self.countExplain(options: options,
                              completion: promise)
        }
    }

    /**
     Executes an aggregate query *asynchronously* and publishes when complete.
     - requires: `.useMasterKey` has to be available.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func aggregatePublisher(_ pipeline: [[String: Encodable]],
                            options: API.Options = []) -> Future<[ResultType], ParseError> {
        Future { promise in
            self.aggregate(pipeline,
                           options: options,
                           completion: promise)
        }
    }

    /**
     Query plan information for executing an aggregate query *asynchronously* and publishes when complete.
     - requires: `.useMasterKey` has to be available.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func aggregateExplainPublisher<U: Decodable>(_ pipeline: [[String: Encodable]],
                                                 options: API.Options = []) -> Future<[U], ParseError> {
        Future { promise in
            self.aggregateExplain(pipeline,
                           options: options,
                           completion: promise)
        }
    }

    /**
     Executes a distinct query *asynchronously* and publishes unique values when complete.
     - requires: `.useMasterKey` has to be available.
     - parameter key: A field to find distinct values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func distinctPublisher(_ key: String,
                           options: API.Options = []) -> Future<[ResultType], ParseError> {
        Future { promise in
            self.distinct(key,
                          options: options,
                          completion: promise)
        }
    }

    /**
     Query plan information for executing a distinct query *asynchronously* and publishes unique values when complete.
     - requires: `.useMasterKey` has to be available.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter key: A field to find distinct values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func distinctExplainPublisher<U: Decodable>(_ key: String,
                                                options: API.Options = []) -> Future<[U], ParseError> {
        Future { promise in
            self.distinctExplain(key,
                                 options: options,
                                 completion: promise)
        }
    }
}

#endif
