//: [Previous](@previous)

//: For this page, make sure your build target is set to ParseSwift (macOS) and targeting
//: `My Mac` or whatever the name of your mac is. Also be sure your `Playground Settings`
//: in the `File Inspector` is `Platform = macOS`. This is because
//: Keychain in iOS Playgrounds behaves differently. Every page in Playgrounds should
//: be set to build for `macOS` unless specified.

import PlaygroundSupport
import Foundation
import ParseSwift

PlaygroundPage.current.needsIndefiniteExecution = true
initializeParse()

struct User: ParseUser {
    //: These are required for `ParseObject`.
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: These are required for `ParseUser`.
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    //: Your custom keys.
    var customKey: String?
    var score: GameScore?
    var targetScore: GameScore?
    var allScores: [GameScore]?

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
extension User {
    //: Custom init for signup.
    init(username: String, password: String, email: String) {
        self.username = username
        self.password = password
        self.email = email
    }
}

//: Create your own value typed `ParseObject`.
struct GameScore: ParseObject {
    //: Those are required for Object
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?

    //: Your own properties.
    var score: Int? = 0
}

//: It's recommended to place custom initializers in an extension
//: to preserve the convenience initializer.
extension GameScore {
    //: Custom initializer.
    init(score: Int) {
        self.score = score
    }

    init(objectId: String?) {
        self.objectId = objectId
    }
}

//: Logging out - synchronously
do {
    try User.logout()
    print("Successfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}

/*: Login - asynchronously - Performs work on background
    queue and returns to specified callbackQueue.
    If no callbackQueue is specified it returns to main queue.
*/
User.login(username: "hello", password: "world") { result in

    switch result {
    case .success(let user):

        guard let currentUser = User.current else {
            assertionFailure("Error: current user not stored locally")
            return
        }
        assert(currentUser.hasSameObjectId(as: user))
        print("Successfully logged in as user: \(user)")

    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

/*: Save your first `customKey` value to your `ParseUser`
    Asynchrounously - Performs work on background
    queue and returns to specified callbackQueue.
    If no callbackQueue is specified it returns to main queue.
    Using `emptyObject` allows you to only send the updated keys to the
    parse server as opposed to the whole object.
*/
var currentUser = User.current?.emptyObject
currentUser?.customKey = "myCustom"
currentUser?.score = GameScore(score: 12)
currentUser?.targetScore = GameScore(score: 100)
currentUser?.allScores = [GameScore(score: 5), GameScore(score: 8)]
currentUser?.save { result in

    switch result {
    case .success(let updatedUser):
        print("Successfully save custom fields of User to ParseServer: \(updatedUser)")
    case .failure(let error):
        print("Failed to update user: \(error)")
    }
}

//: Looking at the output of user from the previous login, it only has
//: a pointer to the `score` and `targetScore` fields. You can
//: fetch using `include` to get the score.
User.current?.fetch(includeKeys: ["score"]) { result in
    switch result {
    case .success:
        print("Successfully fetched user with score key: \(String(describing: User.current))")
    case .failure(let error):
        print("Error fetching score: \(error)")
    }
}

//: The `target` score is still missing. You can get all pointer fields at
//: once by including `["*"]`.
User.current?.fetch(includeKeys: ["*"]) { result in
    switch result {
    case .success:
        print("Successfully fetched user with all keys: \(String(describing: User.current))")
    case .failure(let error):
        print("Error fetching score: \(error)")
    }
}

//: Logging out - synchronously.
do {
    try User.logout()
    print("Successfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}

//: To add additional information when signing up a user,
//: you should create an instance of your user first.
var newUser = User(username: "parse", password: "aPassword*", email: "parse@parse.com")
//: Add any other additional information.
newUser.customKey = "mind"
newUser.signup { result in

    switch result {
    case .success(let user):

        guard let currentUser = User.current else {
            assertionFailure("Error: current user not stored locally")
            return
        }
        assert(currentUser.hasSameObjectId(as: user))
        print("Successfully signed up as user: \(user)")

    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

//: Logging out - synchronously.
do {
    try User.logout()
    print("Successfully logged out")
} catch let error {
    print("Error logging out: \(error)")
}

//: Verification Email - synchronously.
do {
    try User.verificationEmail(email: "hello@parse.org")
    print("Successfully requested verification email be sent")
} catch let error {
    print("Error requesting verification email be sent: \(error)")
}

//: Password Reset Request - synchronously.
do {
    try User.passwordReset(email: "hello@parse.org")
    print("Successfully requested password reset")
} catch let error {
    print("Error requesting password reset: \(error)")
}

//: Logging in anonymously.
User.anonymous.login { result in
    switch result {
    case .success:
        print("Successfully logged in \(String(describing: User.current))")
        print("Session token: \(String(describing: User.current?.sessionToken))")
    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

//: Convert the anonymous user to a real new user.
var currentUser2 = User.current?.emptyObject
currentUser2?.username = "bye"
currentUser2?.password = "world"
currentUser2?.signup { result in
    switch result {

    case .success(let user):
        print("Parse signup successful: \(user)")
        print("Session token: \(String(describing: User.current?.sessionToken))")
    case .failure(let error):
        print("Error logging in: \(error)")
    }
}

PlaygroundPage.current.finishExecution()
//: [Next](@next)
