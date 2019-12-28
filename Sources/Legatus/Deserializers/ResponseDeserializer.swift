import Foundation
import BoltsSwift

open class ResponseDeserializer<T> {
    public func deserialize(_ data: Data, headers: [String: Any]? = nil) -> Task<T> {
        fatalError("Not Implemented")
    }
}

open class EmptyDeserializer: ResponseDeserializer<Bool> {
    public override func deserialize(_ data: Data, headers: [String: Any]? = nil) -> Task<Bool> {
        return Task(true)
    }
}
