import Foundation

struct Postcode: Decodable {
    let postcode: String

    enum CodingKeys: String, CodingKey {
        case postcode
    }
}
