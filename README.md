# Legatus 🏇

## Intro 🎬

The basic idea of *Legatus* is that we want some network abstraction layer that
sufficiently encapsulates actually calling Alamofire directly.

Also, it would be cool to have network layer, that will compatible with ***SwiftUI*** out-of-the-box 📦, isn't it?🧐

Luckily, *Legatus* was implemented with `Combine` framework and have couple of fancy methods, that will allow you to `assign(to:on:)` your response models right to `@Published` properties. Neat!🤩

### Some awesome features of Legatus🌟:

- SOLID design (e.g.: `APIClient` don't stores and configures requests, each request is encapsulated in separate entity).
- Easy retrying of requests.
- Elegant and flexible canceling of requests.
- ***SwiftUI*** compatiblity out-of-the-box.
- Support JSON and XML reponse formats.

*Legatus* is inspired by [Moya](https://github.com/Moya/Moya).

## Project Status 🤖

I consider it's ready for production use.<br/>
Any contributions (pull requests, questions, propositions) are always welcome!😃


## Requirements 📝 
- Swift 5.1+
- macOS 10.15+
- iOS 13+
- tvOS 13+
- watchOS 5+


## Installation 📦 

- #### Swift Package Manager

You can use Xcode 11 SPM GUI: *File -> Swift Packages -> Add Package Dependency -> Pick master branch*.

Or add the following to your `Package.swift` file:

```swift
.package(url: "https://github.com/artemkalinovsky/Legatus.git", .branch("master"))
```

and then specify `"Legatus"` as a dependency of the Target in which you wish to use Legatus.
Here's an example `PackageDescription`:

```swift
// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "MyPackage",
    products: [
        .library(
            name: "MyPackage",
            targets: ["MyPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/artemkalinovsky/Legatus.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "MyPackage",
            dependencies: ["Legatus"])
    ]
)
```

## Basic Usage 🧑‍💻

Let's suppose we want to fetch list of users from JSON and response is look like this:
```json
{ 
   "results":[ 
      { 
         "name":{ 
            "first":"brad",
            "last":"gibson"
         },
         "email":"brad.gibson@example.com"
      }
   ]
}
```

- #### Setup

1. Create `APIClient`:
```swift
    let apiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
```

2. Create response model:
```swift
import Foundation
import JASON
import Legatus

final class User: JSONDeserializable {
    let firstName: String?
    let lastName: String?
    let email: String?

    init?(json: JSON) {
        guard let firstName = json["name"]["first"].string,
            let lastName = json["name"]["last"].string,
            let email = json["email"].string else {
                return nil
        }

        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}
```

3. Create request with endpoint path and desired reponse deserializer:
```swift
import Foundation
import Legatus

final class UsersApiRequest: DeserializeableRequest {

    var path: String {
        return "users"
    }
    
    var deserializer: ResponseDeserializer<[User]> {
        return JSONDeserializer<User>.objectsArrayDeserializer(keyPath: "results")
    }

}
```

- #### Perfrom created request
```swift
    apiClient.executeRequest(request: UsersApiRequest()) { result in }
```

Voilà!🧑‍🎨

## Advanced Usage 🤓💻

- #### Working with CoreData models.
To deserialize your response right to CoreData `NSManagedObject`, just call designated initializer firstly:
```swift
@objc(CoreDataObject)
public class CoreDataObject: NSManagedObject, JSONDeserializable {

    public required init?(json: JSON) {
        super.init(entity: /*provide NSEntityDescription*/, insertInto: /*provide NSManagedObjectContext*/)
        stringProperty = json.stringValue
    }

}
```

- #### Working with [Realm](https://github.com/realm/realm-cocoa) models.
To deserialize your response right to Realm `Object` subclass:
```swift
import Foundation
import RealmSwift
import JASON
import Legatus

final class RealmObject: Object, JSONDeserializable {

    @objc dynamic var name = ""

    convenience required init?(json: JSON) {
        self.init()
        name = json["name"].stringValue
    }

    required init() {
        super.init()
    }
}
```

- #### Using keypath chaing in response deserializer
```json
{ 
   "user":{ 
      "name":{ 
         "first":"brad",
         "last":"gibson"
      }
   }
}
```
```swift
import Foundation
import JASON
import Legatus

final class UserName: JSONDeserializable {
    let firstName: String?
    let lastName: String?

    init?(json: JSON) {
        self.firstName = json["first"].string
        self.lastName = json["last"].string
    }
}
```
```swift
import Foundation
import Legatus

final class UserNameApiRequest: DeserializeableRequest {
    
    var deserializer: ResponseDeserializer<UserName> {
        return JSONDeserializer<UserName>.singleObjectDeserializer(keyPath: "user", "name")
    }

}
```
Same functionality available for `XMLDeserializer` too.

- #### Retrying requests
If you want to retry previously failed request, just provide count of desiried retry times:
```swift
    apiClient.executeRequest(request: UsersApiRequest(), retries: 3) { result in }
```

- #### Request cancelation
To cancel certaint request, you have to store it's cancelation token and call `cancel()` method.
```swift
    let cancelationToken = apiClient.executeRequest(request: UsersApiRequest()) { result in }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            cancelationToken?.cancel()
    }
```

Also, you can cancel all active requests:
```swift
    apiClient.cancelAllRequests()
```

## Combine Extension 🚜

While working with SwiftUI, where most of UI updates based on *Combine* mechanisms under the hood, it's very convenient to get
`Publisher` as request result for future transformations and assigns:
```swift
    @Published var users = [User]()
    var subscriptions = Set<AnyCancellable>()

    apiClient
         .requestPublisher(request: UsersApiRequest())
         .catch { _ in return Just([User]())}
         .assign(to: \.users, on: self)
         .store(in: &subscriptions)
```

## Credits 👏

- [Moya](https://github.com/Moya/Moya)
- [Combine Community](https://github.com/CombineCommunity)
- @delba for [JASON](https://github.com/delba/JASON)
- @drmohundro for [SWXMLHash](https://github.com/drmohundro/SWXMLHash)


## License 📄

Legatus is released under an MIT license. See [LICENCE](https://github.com/artemkalinovsky/Legatus/blob/master/LICENSE) for more information.
