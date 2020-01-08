import Foundation
@testable import Legatus

final class TestAuthRequest: AuthRequest, DeserializeableRequest {

    var accessToken: String? = nil

    var deserializer: ResponseDeserializer<Bool> {
        return EmptyDeserializer()
    }
}
