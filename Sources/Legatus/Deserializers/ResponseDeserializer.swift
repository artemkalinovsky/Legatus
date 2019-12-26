import Foundation
import BoltsSwift

public protocol JSONDecodable {

    init?(decodingRepresentation representation: [String: Any])
}

open class ResponseDeserializer<T> {
    func deserialize(_ data: Data, headers: [String: Any]? = nil) -> Task<T> {
        fatalError("Not Implemented")
    }
}

open class EmptyDeserializer: ResponseDeserializer<Bool> {
    override func deserialize(_ data: Data, headers: [String: Any]? = nil) -> Task<Bool> {
        return Task(true)
    }
}
