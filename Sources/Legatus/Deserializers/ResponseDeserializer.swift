import Foundation
import Combine

open class ResponseDeserializer<T> {
    public func deserialize(data: Data) -> Future<T, Error> {
        fatalError("Not Implemented")
    }
}

open class EmptyDeserializer: ResponseDeserializer<Void> {
    public override func deserialize(data: Data) -> Future<Void, Error> {
        return Future { promise in
            promise(.success(()))
        }
    }
}

open class RawDataDeserializer: ResponseDeserializer<Data> {
    public override func deserialize(data: Data) -> Future<Data, Error> {
        return Future { promise in
            promise(.success(data))
        }
    }
}
