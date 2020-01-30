import Foundation
import JASON
@testable import Legatus

struct Postcode: JSONDeserializable {
    let value: String?

    init?(json: JSON) {
        self.value = json.string
    }
}
