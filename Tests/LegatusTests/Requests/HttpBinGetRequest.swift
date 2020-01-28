import Foundation
@testable import Legatus

final class HttpBinGetRequest: DeserializeableRequest {

    var path: String {
        return "get"
    }
    
    var deserializer: ResponseDeserializer<HttpBinGetResponse> {
        return JSONDeserializer<HttpBinGetResponse>.singleObjectDeserializer()
    }

}
