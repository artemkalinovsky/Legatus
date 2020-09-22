import Foundation
@testable import Legatus

final class HttpBinGetRequest: DeserializeableRequest {

    var path: String {
        "get"
    }

    var deserializer: ResponseDeserializer<HttpBinGetResponse> {
        JSONDeserializer<HttpBinGetResponse>.singleObjectDeserializer()
    }

}
