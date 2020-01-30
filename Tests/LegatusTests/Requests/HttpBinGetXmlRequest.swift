import Foundation
@testable import Legatus

final class HttpBinGetXmlRequest: DeserializeableRequest {

    var path: String {
        return "xml"
    }

    var deserializer: ResponseDeserializer<HttpBinXmlSlideshow> {
        return XMLDeserializer<HttpBinXmlSlideshow>.singleObjectDeserializer(keyPath: "slideshow")
    }

}
