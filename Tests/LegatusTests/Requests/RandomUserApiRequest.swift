import Foundation
@testable import Legatus

final class RandomUserApiRequest: DeserializeableRequest {

    var parameters: [String: Any]? {
        guard let results = results else {
            return nil
        }
        return ["results": results]
    }

    var deserializer: ResponseDeserializer<[RandomUser]> {
        JSONDeserializer<RandomUser>.collectionDeserializer(keyPath: "results")
    }

    private let results: Int?

    init(results: Int? = nil) {
        self.results = results
    }

}
