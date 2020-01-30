import Foundation
import SWXMLHash
@testable import Legatus

struct RandomUserApiVersion: XMLDeserializable {
    let value: String?

    init?(xmlIndexer: XMLIndexer) {
        self.value = xmlIndexer.element?.text
    }
}
