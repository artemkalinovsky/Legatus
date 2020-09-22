import Foundation
@testable import Legatus

final class HttpBinGetXmlRequest: DeserializeableRequest {

    var path: String {
        "xml"
    }

    var deserializer: ResponseDeserializer<HttpBinXmlSlideshow> {
        XMLDeserializer<HttpBinXmlSlideshow>.singleObjectDeserializer()
    }

}
