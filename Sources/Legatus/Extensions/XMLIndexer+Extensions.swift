import Foundation
import SWXMLHash

extension XMLIndexer {

    internal subscript(indexes: [String]) -> XMLIndexer {
        var xmlIndexer = self
        indexes.forEach { xmlIndexer = xmlIndexer[$0] }
        return xmlIndexer
    }

}
