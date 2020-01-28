import Foundation
import JASON
@testable import Legatus

struct HttpBinGetResponse: JSONDeserializable {
    let urlString: String?

    init?(json: JSON) {
        self.urlString = json["url"].string
    }
}
