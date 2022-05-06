![swift workflow](https://github.com/artemkalinovsky/Legatus/actions/workflows/swift.yml/badge.svg) 

# Legatus 🏇

A legatus (anglicised as legate) was a high-ranking Roman military officer in the Roman Army, equivalent to a modern high-ranking general officer. Initially used to delegate power, the term became formalised under Augustus as the officer in command of a legion.
Legatus was also a term for an ambassador of the Roman Republic who was appointed by the senate for a mission (legatio) to a foreign nation, as well as for ambassadors who came to Rome from other countries.

## Intro 🎬

The basic idea of *Legatus* is that we want some network abstraction layer that
sufficiently encapsulates actually calling Alamofire directly.

Also, it would be cool to have network layer, that will compatible with ***SwiftUI*** out-of-the-box 📦, isn't it?🧐

Luckily, *Legatus* was implemented with `Combine` framework and have couple of fancy methods, that will allow you to `assign(to:on:)` your response models right to `@Published` properties. Neat!🤩

### Some awesome features of Legatus🌟:

* SOLID design (e.g.: `APIClient` don't stores and configures requests, each request is encapsulated in separate entity).
* Easy retrying of requests.
* Elegant and flexible canceling of requests.
* Reachability tracking.
* Support JSON and XML response formats.
* ***Combine*** extension.
* ***Swift Concurrency*** support.

*Legatus* is inspired by [Moya](https://github.com/Moya/Moya).

## Project Status 🤖

I consider it's ready for production use.<br/>
Any contributions (pull requests, questions, propositions) are always welcome!😃

## Requirements 📝 

* Swift 5.6+
* macOS 12+
* iOS 15+
* tvOS 15+
* watchOS 8+

## Installation 📦 

* #### Swift Package Manager

You can use Xcode SPM GUI: *File -> Swift Packages -> Add Package Dependency -> Pick 2.0.1 release (or main branch)*.

Or add the following to your `Package.swift` file:

``` swift
.package(url: "https://github.com/artemkalinovsky/Legatus.git", .upToNextMajor(from: "2.0.1"))
```

and then specify `"Legatus"` as a dependency of the Target in which you wish to use Legatus.
Here's an example `PackageDescription` :

``` swift
// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "MyPackage",
    products: [
        .library(
            name: "MyPackage",
            targets: ["MyPackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/artemkalinovsky/Legatus.git", .upToNextMajor(from: "2.0.1"))
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

``` json
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

* #### Setup

1. Create `APIClient` :

``` swift
    let apiClient = APIClient(baseURL: URL(string: "https://webservice.com/api/")!)
```

2. Create response model:

``` swift
import Foundation
import Legatus

final class User: Decodable {
    let firstName: String?
    let lastName: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case name
        case email
    }

    enum NameKeys: String, CodingKey {
        case firstName = "first"
        case lastName = "last"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        email = try values.decodeIfPresent(String.self, forKey: .email)

        let name = try values.nestedContainer(keyedBy: NameKeys.self, forKey: .name)
        firstName = try name.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try name.decodeIfPresent(String.self, forKey: .lastName)
    }
}
```

3. Create request with endpoint path and desired reponse deserializer:

``` swift
import Foundation
import Legatus

final class UsersApiRequest: DeserializeableRequest {

    var path: String {
        "users"
    }
    
    var deserializer: ResponseDeserializer<[User]> {
        JSONDeserializer<User>.collectionDeserializer(keyPath: "results")
    }

}
```

* #### Perfrom created request

``` swift
    apiClient.executeRequest(request: UsersApiRequest()) { result in }
```

Voilà!🧑‍🎨

## Advanced Usage 🤓💻

* #### Working with CoreData models.

To deserialize your response right to CoreData `NSManagedObject` , just call designated initializer firstly:

``` swift
import Foundation
import CoreData
import Legatus

@objc(CoreDataObject)
public class CoreDataObject: NSManagedObject, Decodable {

    required convenience public init(from decoder: Decoder) throws {
        self.init(context: NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType))

        //TODO: implement decoding
    }

}
```

* #### Working with [Realm](https://github.com/realm/realm-cocoa) models.

To deserialize your response right to Realm `Object` subclass:

``` swift
import Foundation
import RealmSwift
import Legatus

final class RealmObject: Object, Decodable {

    @objc dynamic var name = ""

    required init() {
        super.init()
    }

    convenience init(from decoder: Decoder) throws {
        self.init()

        //TODO: implement decoding
    }
}
```

Same functionality available for `XMLDeserializer` too.

* #### Retrying requests

If you want to retry previously failed request, just provide count of desiried retry times:

``` swift
    apiClient.executeRequest(request: UsersApiRequest(), retries: 3) { result in }
```

* #### Request cancelation

To cancel certain request, you have to store it's cancelation token and call `cancel()` method.

``` swift
    let cancelationToken = apiClient.executeRequest(request: UsersApiRequest()) { result in }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
            cancelationToken.cancel()
    }
```

Also, you can cancel all active requests:

``` swift
    apiClient.cancelAllRequests()
```

## Combine Extension 🚜

While working with SwiftUI, where most of UI updates based on *Combine* mechanisms under the hood, it's very convenient to get
`Publisher` as request result for future transformations and assigns:

``` swift
    @Published var users = [User]()
    var subscriptions = Set<AnyCancellable>()

    apiClient
         .responsePublisher(request: UsersApiRequest())
         .catch { _ in return Just([User]())}
         .assign(to: \.users, on: self)
         .store(in: &subscriptions)
```

## Swift Concurrency Extension 🚦
``` swift
    let httpBinApiClient = APIClient(baseURL: URL(string: "https://httpbin.org/")!)
    do {
        let httpBinGetResponse = try await httpBinApiClient.executeRequest(request: HttpBinGetRequest())
    } catch {
        // handle error
    }
```

## Apps using Legatus 📱

- [PinPlace](https://apps.apple.com/ua/app/pinplace/id1571349149)

## Credits 👏

* [Moya](https://github.com/Moya/Moya)
* [Combine Community](https://github.com/CombineCommunity)
* @0111b for [JSONDecoder-Keypath](https://github.com/0111b/JSONDecoder-Keypath)
* @drmohundro for [SWXMLHash](https://github.com/drmohundro/SWXMLHash)

## License 📄

Legatus is released under an MIT license. See [LICENCE](https://github.com/artemkalinovsky/Legatus/blob/master/LICENSE) for more information.
