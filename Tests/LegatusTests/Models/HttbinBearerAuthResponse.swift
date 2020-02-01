import Foundation
import JASON
@testable import Legatus

struct HttbinBearerAuthResponse: JSONDeserializable {
    let isAuthenticated: Bool
    let token: String

    init?(json: JSON) {
        self.isAuthenticated = json["authenticated"].boolValue
        self.token = json["token"].stringValue
    }
}
