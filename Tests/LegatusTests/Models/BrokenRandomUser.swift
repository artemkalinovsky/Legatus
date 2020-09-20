import Foundation

final class BrokenRandomUser: Decodable {
    let firstName: String?
    let lastName: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case name
        case email
    }

    enum NameKeys: String, CodingKey {
        case firstName
        case lastName
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        email = try values.decodeIfPresent(String.self, forKey: .email)

        let name = try values.nestedContainer(keyedBy: NameKeys.self, forKey: .name)
        firstName = try name.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try name.decodeIfPresent(String.self, forKey: .lastName)
    }
}
