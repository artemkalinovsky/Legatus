import Foundation
@testable import Legatus

final class HttpBinBearerAuthRequest: AuthRequest, DeserializeableRequest {

    var accessToken: String?

    var path: String {
        "bearer"
    }

    var deserializer: ResponseDeserializer<HttpBinBearerAuthResponse> {
        JSONDeserializer<HttpBinBearerAuthResponse>.singleObjectDeserializer()
    }
}
