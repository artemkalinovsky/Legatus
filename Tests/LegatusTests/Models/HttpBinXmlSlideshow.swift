import Foundation
import SWXMLHash
@testable import Legatus

struct HttpBinXmlSlideshow: XMLDeserializable {
    struct HttpBinXmlSlide: XMLDeserializable {
        let title: String?
        let items: [String]

        init?(xmlIndexer: XMLIndexer) {
            self.title = xmlIndexer["title"].element?.text
            self.items = xmlIndexer["item"].all.compactMap { $0.element?.text }
        }
    }

    let title: String?
    let author: String?
    let slides: [HttpBinXmlSlide]

    init?(xmlIndexer: XMLIndexer) {
        self.title = xmlIndexer["slideshow"].element?.attribute(by: "title")?.text
        self.author = xmlIndexer["slideshow"].element?.attribute(by: "author")?.text
        self.slides = xmlIndexer["slideshow"]["slide"].all.compactMap { HttpBinXmlSlide(xmlIndexer: $0) }
    }
}
