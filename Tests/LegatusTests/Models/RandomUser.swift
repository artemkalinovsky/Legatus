import Foundation
import Legatus
import JASON

final class RandomUser: JSONDeserializable {
    let firstName: String?
    let lastName: String?
    let email: String?

    init?(json: JSON) {
        self.firstName = json["name"]["first"].string
        self.lastName = json["name"]["last"].string
        self.email = json["email"].string
    }
}
