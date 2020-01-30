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
        guard let slideShowKey = elementKey, slideShowKey == "slideshow" else { return nil }
        self.title = xmlIndexer[slideShowKey].element?.attribute(by: "title")?.text
        self.author = xmlIndexer[slideShowKey].element?.attribute(by: "author")?.text
        self.slides = xmlIndexer[slideShowKey]["slide"].all
            .compactMap { HttpBinXmlSlide(xmlIndexer: $0, elementKey: nil) }
    }
}
