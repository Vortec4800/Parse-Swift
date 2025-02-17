//: For this page, make sure your build target is set to ParseSwift (macOS) and targeting
//: `My Mac` or whatever the name of your mac is. Also be sure your `Playground Settings`
//: in the `File Inspector` is `Platform = macOS`. This is because
//: Keychain in iOS Playgrounds behaves differently. Every page in Playgrounds should
//: be set to build for `macOS` unless specified.

import PlaygroundSupport
import Foundation
import ParseSwift
PlaygroundPage.current.needsIndefiniteExecution = true

/*: start parse-server with
npm start -- --appId applicationId --clientKey clientKey --masterKey masterKey --mountPath /1
*/

//: In Xcode, make sure you are building the "ParseSwift (macOS)" framework.

initializeParse()

//: Get current SDK version
if let version = ParseVersion.current {
    print("Current Swift SDK version is \"\(version)\"")
}

//: Check the health of your Parse Server.
do {
    print("Server health is: \(try ParseHealth.check())")
} catch {
    print(error)
}

//: Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var score: Int = 0

    /*:
     It's recommended the developer adds the emptyObject computed property or similar.
     Gets an empty version of the respective object. This can be used when you only need to update a
     a subset of the fields of an object as oppose to updating every field of an object. Using an
     empty object and updating a subset of the fields reduces the amount of data sent between
     client and server when using `save` and `saveAll` to update objects.
    */
    var emptyObject: Self {
        var object = Self()
        object.objectId = objectId
        object.createdAt = createdAt
        return object
    }
}

//: It's recommended to place custom initializers in an extension
//: to preserve the convenience initializer.
extension GameScore {

    init(score: Int) {
        self.score = score
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

struct GameData: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var polygon: ParsePolygon?
    //: `ParseBytes` needs to be a part of the original schema
    //: or else you will need your masterKey to force an upgrade.
    var bytes: ParseBytes?
}

//: It's recommended to place custom initializers in an extension
//: to preserve the convenience initializer.
extension GameData {

    init (bytes: ParseBytes?, polygon: ParsePolygon) {
        self.bytes = bytes
        self.polygon = polygon
    }
}

//: Define initial GameScores.
let score = GameScore(score: 10)
let score2 = GameScore(score: 3)

/*: Save asynchronously (preferred way) - Performs work on background
    queue and returns to specified callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
score.save { result in
    switch result {
    case .success(let savedScore):
        assert(savedScore.objectId != nil)
        assert(savedScore.createdAt != nil)
        assert(savedScore.updatedAt != nil)
        assert(savedScore.ACL == nil)
        assert(savedScore.score == 10)

        /*: To modify, need to make it a var as the value type
            was initialized as immutable. Using `emptyObject`
            allows you to only send the updated keys to the
            parse server as opposed to the whole object.
        */
        var changedScore = savedScore.emptyObject
        changedScore.score = 200
        changedScore.save { result in
            switch result {
            case .success(var savedChangedScore):
                assert(savedChangedScore.score == 200)
                assert(savedScore.objectId == savedChangedScore.objectId)

                /*: Note that savedChangedScore is mutable since it's
                    a var after success.
                */
                savedChangedScore.score = 500

            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: This will store the second batch score to be used later.
var score2ForFetchedLater: GameScore?

//: Saving multiple GameScores at once.
[score, score2].saveAll { results in
    switch results {
    case .success(let otherResults):
        var index = 0
        otherResults.forEach { otherResult in
            switch otherResult {
            case .success(let savedScore):
                print("Saved \"\(savedScore.className)\" with score \(savedScore.score) successfully")
                if index == 1 {
                    score2ForFetchedLater = savedScore
                }
                index += 1
            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Saving multiple GameScores at once using a transaction.
//: Currently doesn't work on mongo
/*[score, score2].saveAll(transaction: true) { results in
    switch results {
    case .success(let otherResults):
        var index = 0
        otherResults.forEach { otherResult in
            switch otherResult {
            case .success(let savedScore):
                print("Saved \"\(savedScore.className)\" with score \(savedScore.score) successfully")
                if index == 1 {
                    score2ForFetchedLater = savedScore
                }
                index += 1
            case .failure(let error):
                assertionFailure("Error saving: \(error)")
            }
        }

    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}*/

//: Save synchronously (not preferred - all operations on main queue).
let savedScore: GameScore?
do {
    savedScore = try score.save()
} catch {
    savedScore = nil
    fatalError("Error saving: \(error)")
}

assert(savedScore != nil)
assert(savedScore?.objectId != nil)
assert(savedScore?.createdAt != nil)
assert(savedScore?.updatedAt != nil)
assert(savedScore?.score == 10)

/*:  To modify, need to make it a var as the value type
    was initialized as immutable. Using `emptyObject`
    allows you to only send the updated keys to the
    parse server as opposed to the whole object.
*/
guard var changedScore = savedScore?.emptyObject else {
    fatalError()
}
changedScore.score = 200

let savedChangedScore: GameScore?
do {
    savedChangedScore = try changedScore.save()
} catch {
    savedChangedScore = nil
    fatalError("Error saving: \(error)")
}

assert(savedChangedScore != nil)
assert(savedChangedScore!.score == 200)
assert(savedScore!.objectId == savedChangedScore!.objectId)

let otherResults: [(Result<GameScore, ParseError>)]?
do {
    otherResults = try [score, score2].saveAll()
} catch {
    otherResults = nil
    fatalError("Error saving: \(error)")
}
assert(otherResults != nil)

otherResults!.forEach { result in
    switch result {
    case .success(let savedScore):
        print("Saved \"\(savedScore.className)\" with score \(savedScore.score) successfully")
    case .failure(let error):
        assertionFailure("Error saving: \(error)")
    }
}

//: Now we will create another object and delete it.
let score3 = GameScore(score: 30)

//: Save the score and store it in "scoreToDelete".
var scoreToDelete: GameScore!
do {
    scoreToDelete = try score3.save()
    print("Successfully saved: \(scoreToDelete!)")
} catch {
    assertionFailure("Error deleting: \(error)")
}

//: Delete the score from parse-server synchronously.
do {
    try scoreToDelete.delete()
    print("Successfully deleted: \(scoreToDelete!)")
} catch {
    assertionFailure("Error deleting: \(error)")
}

//: Now we will fetch a ParseObject that has already been saved based on its' objectId.
let scoreToFetch = GameScore(objectId: savedScore?.objectId)

//: Asynchronously (preferred way) fetch this GameScore based on it's objectId alone.
scoreToFetch.fetch { result in
    switch result {
    case .success(let fetchedScore):
        print("Successfully fetched: \(fetchedScore)")
    case .failure(let error):
        assertionFailure("Error fetching: \(error)")
    }
}

//: Synchronously fetch this GameScore based on it's objectId alone.
do {
    let fetchedScore = try scoreToFetch.fetch()
    print("Successfully fetched: \(fetchedScore)")
} catch {
    assertionFailure("Error fetching: \(error)")
}

//: Now we will fetch `ParseObject`'s in batch that have already been saved based on its' objectId.
let score2ToFetch = GameScore(objectId: score2ForFetchedLater?.objectId)

//: Asynchronously (preferred way) fetch GameScores based on it's objectId alone.
[scoreToFetch, score2ToFetch].fetchAll { result in
    switch result {
    case .success(let fetchedScores):

        fetchedScores.forEach { result in
            switch result {
            case .success(let fetched):
                print("Successfully fetched: \(fetched)")
            case .failure(let error):
                print("Error fetching: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error fetching: \(error)")
    }
}

var fetchedScore: GameScore!

//: Synchronously fetchAll GameScore's based on it's objectId's alone.
do {
    let fetchedScores = try [scoreToFetch, score2ToFetch].fetchAll()
    fetchedScores.forEach { result in
        switch result {
        case .success(let fetched):
            fetchedScore = fetched
            print("Successfully fetched: \(fetched)")
        case .failure(let error):
            print("Error fetching: \(error)")
        }
    }
} catch {
    assertionFailure("Error fetching: \(error)")
}

//: Asynchronously (preferred way) deleteAll GameScores based on it's objectId alone.
[scoreToFetch, score2ToFetch].deleteAll { result in
    switch result {
    case .success(let deletedScores):
        deletedScores.forEach { result in
            switch result {
            case .success:
                print("Successfully deleted score")
            case .failure(let error):
                print("Error deleting: \(error)")
            }
        }
    case .failure(let error):
        assertionFailure("Error deleting: \(error)")
    }
}

//: Synchronously deleteAll GameScore's based on it's objectId's alone.
//: Commented out because the async above deletes the items already.
/* do {
    let fetchedScores = try [scoreToFetch, score2ToFetch].deleteAll()
    fetchedScores.forEach { result in
        switch result {
        case .success(let fetched):
            print("Successfully deleted: \(fetched)")
        case .failure(let error):
            print("Error deleted: \(error)")
        }
    }
} catch {
    assertionFailure("Error deleting: \(error)")
}*/

//: How to add `ParseBytes` and `ParsePolygon` to objects.
let points = [
    try ParseGeoPoint(latitude: 0, longitude: 0),
    try ParseGeoPoint(latitude: 0, longitude: 1),
    try ParseGeoPoint(latitude: 1, longitude: 1),
    try ParseGeoPoint(latitude: 1, longitude: 0),
    try ParseGeoPoint(latitude: 0, longitude: 0)
]

do {
    let polygon = try ParsePolygon(points)
    let bytes = ParseBytes(data: "hello world".data(using: .utf8)!)
    var gameData = GameData(bytes: bytes, polygon: polygon)
    gameData = try gameData.save()
    print("Successfully saved: \(gameData)")
} catch {
    print("Error saving: \(error.localizedDescription)")
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
