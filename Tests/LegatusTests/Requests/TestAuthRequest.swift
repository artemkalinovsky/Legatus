import Foundation
@testable import Legatus

final class TestAuthRequest: AuthRequest, DeserializeableRequest {

    var accessToken: String?

    var deserializer: ResponseDeserializer<Void> {
        return EmptyDeserializer()
    }
}
