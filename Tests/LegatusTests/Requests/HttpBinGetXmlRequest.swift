import Foundation
@testable import Legatus

final class HttpBinGetXmlRequest: DeserializeableRequest {

    var path: String {
        return "xml"
    }

    var deserializer: ResponseDeserializer<[HttpBinXmlSlide]> {
        return XMLDeserializer<HttpBinXmlSlide>.objectsArrayDeserializer(keyPath: "slide")
    }

}
