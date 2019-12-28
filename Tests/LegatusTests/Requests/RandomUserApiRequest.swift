import Foundation
import Legatus

final class RandomUserApiRequest: DeserializeableRequest {

    var deserializer: ResponseDeserializer<[RandomUser]> {
        return JSONDeserializer<RandomUser>.objectsArrayDeserializer(keyPath: "results")
    }

}
