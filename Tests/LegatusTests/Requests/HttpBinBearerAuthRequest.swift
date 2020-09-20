import Foundation
@testable import Legatus

final class HttpBinBearerAuthRequest: AuthRequest, DeserializeableRequest {

    var accessToken: String?

    var path: String {
        return "bearer"
    }

    var deserializer: ResponseDeserializer<HttpBinBearerAuthResponse> {
        return JSONDeserializer<HttpBinBearerAuthResponse>.singleObjectDeserializer()
    }
}
