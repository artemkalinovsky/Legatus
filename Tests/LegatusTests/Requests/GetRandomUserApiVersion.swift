import Foundation
@testable import Legatus

final class GetRandomUserApiVersionRequest: DeserializeableRequest {

    var parameters: [String: Any]? {
        ["format": "xml"]
    }

    var deserializer: ResponseDeserializer<RandomUserApiVersion> {
        XMLDeserializer<RandomUserApiVersion>.singleObjectDeserializer(keyPath: "user", "info", "version")
    }

}
