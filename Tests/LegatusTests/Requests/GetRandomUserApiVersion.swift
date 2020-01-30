import Foundation
@testable import Legatus

final class GetRandomUserApiVersionRequest: DeserializeableRequest {

    var parameters: [String : Any]? {
        return ["format": "xml"]
    }
    
    var deserializer: ResponseDeserializer<RandomUserApiVersion> {
        return XMLDeserializer<RandomUserApiVersion>.singleObjectDeserializer(keyPath: "user", "info", "version")
    }

}
