import Foundation
import Legatus
import JASON

final class BrokenRandomUser: JSONDeserializable {
    let firstName: String
    let lastName: String
    let email: String

    init?(json: JSON) {
        guard let firstName = json["firstName"].string,
            let lastName = json["lastName"].string,
            let email = json["email"].string else {
                return nil
        }

        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
}
