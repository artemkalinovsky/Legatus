import Foundation
import SWXMLHash
@testable import Legatus

struct HttpBinXmlSlideshow: XMLDeserializable {
    struct HttpBinXmlSlide: XMLDeserializable {
        let title: String?
        let items: [String]

        init?(xmlIndexer: XMLIndexer, elementKey: String?) {
            self.title = xmlIndexer["title"].element?.text
            self.items = xmlIndexer["item"].all.compactMap { $0.element?.text }
        }
    }

    let title: String?
    let author: String?
    let slides: [HttpBinXmlSlide]

    init?(xmlIndexer: XMLIndexer, elementKey: String?) {
        self.title = elementKey == nil ? xmlIndexer.element?.attribute(by: "title")?.text : xmlIndexer[elementKey!].element?.attribute(by: "title")?.text

        self.author = elementKey == nil ? xmlIndexer.element?.attribute(by: "author")?.text : xmlIndexer[elementKey!].element?.attribute(by: "author")?.text

        let slidesXml = elementKey == nil ? xmlIndexer["slide"].all : xmlIndexer["slideshow"]["slide"].all
        self.slides = slidesXml.compactMap { HttpBinXmlSlide(xmlIndexer: $0, elementKey: nil) }
    }
}
