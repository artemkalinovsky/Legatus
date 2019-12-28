import Foundation
import Combine

open class ResponseDeserializer<T> {
    public func deserialize(_ data: Data, headers: [String: Any]? = nil) -> Future<T, Error> {
        fatalError("Not Implemented")
    }
}

open class EmptyDeserializer: ResponseDeserializer<Bool> {
    public override func deserialize(_ data: Data, headers: [String: Any]? = nil) -> Future<Bool, Error> {
        return Future { promise in
            promise(.success(true))
        }
    }
}
