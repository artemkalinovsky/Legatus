import Foundation
@testable import Legatus

final class HttpBinBearerAuthRequest: AuthRequest, DeserializeableRequest {

    var accessToken: String?

    var path: String {
        return "bearer"
    }

    var deserializer: ResponseDeserializer<HttbinBearerAuthResponse> {
        return JSONDeserializer<HttbinBearerAuthResponse>.singleObjectDeserializer()
    }
}
