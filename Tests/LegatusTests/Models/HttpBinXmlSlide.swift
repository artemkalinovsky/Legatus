import Foundation
import SWXMLHash
@testable import Legatus

struct HttpBinXmlSlide: XMLDeserializable {
    let title: String?
    let items: [String]

    init?(xmlIndexer: XMLIndexer) {
        self.title = xmlIndexer["title"].element?.text
        self.items = xmlIndexer["item"].all.compactMap { $0.element?.text }
    }
}
