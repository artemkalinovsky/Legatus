import Foundation

struct HttbinBearerAuthResponse: Decodable {
    let authenticated: Bool
    let token: String

    enum CodingKeys: String, CodingKey {
        case authenticated
        case token
    }
}
