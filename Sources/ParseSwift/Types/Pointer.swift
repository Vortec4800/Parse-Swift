import Foundation
#if canImport(Combine)
import Combine
#endif

protocol ParsePointer: Encodable {

    var __type: String { get } // swiftlint:disable:this identifier_name

    var className: String { get }

    var objectId: String { get set }
}

extension ParsePointer {
    /**
     Determines if two objects have the same objectId.

     - parameter as: Object to compare.

     - returns: Returns a `true` if the other object has the same `objectId` or `false` if unsuccessful.
    */
    public func hasSameObjectId(as other: ParsePointer) -> Bool {
        return other.className == className && other.objectId == objectId
    }
}

private func getObjectId<T: ParseObject>(target: T) throws -> String {
    guard let objectId = target.objectId else {
        throw ParseError(code: .missingObjectId, message: "Cannot set a pointer to an unsaved object")
    }
    return objectId
}

private func getObjectId(target: Objectable) throws -> String {
    guard let objectId = target.objectId else {
        throw ParseError(code: .missingObjectId, message: "Cannot set a pointer to an unsaved object")
    }
    return objectId
}

/// A Pointer referencing a ParseObject.
public struct Pointer<T: ParseObject>: ParsePointer, Fetchable, Encodable, Hashable {

    internal let __type: String = "Pointer" // swiftlint:disable:this identifier_name

    /**
    The id of the object.
    */
    public var objectId: String

    /**
    The class name of the object.
    */
    public var className: String

    /**
     Create a Pointer type.
     - parameter target: Object to point to.
     */
    public init(_ target: T) throws {
        self.objectId = try getObjectId(target: target)
        self.className = target.className
    }

    /**
     Create a Pointer type.
     - parameter objectId: The id of the object.
     */
    public init(objectId: String) {
        self.className = T.className
        self.objectId = objectId
    }

    private enum CodingKeys: String, CodingKey {
        case __type, objectId, className // swiftlint:disable:this identifier_name
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        objectId = try values.decode(String.self, forKey: .objectId)
        className = try values.decode(String.self, forKey: .className)
    }
}

public extension Pointer {

    /**
     Fetches the `ParseObject` *synchronously* with the current data from the server and sets an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of `ParseError` type.
    */
    func fetch(includeKeys: [String]? = nil,
               options: API.Options = []) throws -> T {
        let path = API.Endpoint.object(className: className, objectId: objectId)
        return try API.NonParseBodyCommand<NoBody, T>(method: .GET,
                                      path: path) { (data) -> T in
                    try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }.execute(options: options)
    }

    /**
     Fetches the `ParseObject` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include. Use `["*"]` to include
     all keys.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    func fetch(includeKeys: [String]? = nil,
               options: API.Options = [],
               callbackQueue: DispatchQueue = .main,
               completion: @escaping (Result<T, ParseError>) -> Void) {
        let path = API.Endpoint.object(className: className, objectId: objectId)
        API.NonParseBodyCommand<NoBody, T>(method: .GET,
                                      path: path) { (data) -> T in
                    try ParseCoding.jsonDecoder().decode(T.self, from: data)
        }.executeAsync(options: options) { result in
            callbackQueue.async {
                completion(result)
            }
        }
    }

    #if canImport(Combine)
    /**
     Fetches the `ParseObject` *aynchronously* with the current data from the server and sets an error if one occurs.
     Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func fetchPublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<T, ParseError> {
        Future { promise in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: promise)
        }
    }
    #endif
}

// MARK: CustomDebugStringConvertible
extension Pointer: CustomDebugStringConvertible {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
            return "PointerType ()"
        }
        return "PointerType (\(descriptionString))"
    }
}

// MARK: CustomStringConvertible
extension Pointer: CustomStringConvertible {
    public var description: String {
        debugDescription
    }
}

internal struct PointerType: ParsePointer, Encodable {

    var __type: String = "Pointer" // swiftlint:disable:this identifier_name
    var objectId: String
    var className: String

    init(_ target: Objectable) throws {
        self.objectId = try getObjectId(target: target)
        self.className = target.className
    }
}
