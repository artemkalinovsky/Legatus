import Foundation
import JASON
@testable import Legatus

struct Postcode: JSONDeserializable {

    let postcode: String?

    init?(json: JSON) {
        self.postcode = json.string
    }

}
