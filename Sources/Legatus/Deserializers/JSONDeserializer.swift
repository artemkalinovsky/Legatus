import Foundation
import Combine
import JASON

public protocol JSONDeserializable {
    init?(json: JSON)
}

public enum JSONDeserializerError: Error {
    case jsonDeserializableInitFailed(String)
}

open class JSONDeserializer<T>: ResponseDeserializer<T> {

    typealias Transform = ((Data) throws -> T)

    let transform: Transform

    init(transform: @escaping Transform) {
        self.transform = transform
    }

    convenience override init() {
        self.init { jsonObject -> T in
            if let object = jsonObject as? T {
                return object
            }
            throw JSONDeserializerError.jsonDeserializableInitFailed("Wrong result type: \(jsonObject.self). Expected \(T.self)")
        }
    }

    public override func deserialize(data: Data) -> Future<T, Error> {
        return Future { [weak self] promise in
            guard let self = self else { return }
            do {
                let object = try self.transform(data)
                promise(.success(object))
            } catch {
                promise(.failure(error))
            }
        }
    }
}

public extension JSONDeserializer where T: JSONDeserializable {

    class func singleObjectDeserializer(keyPath path: String...) -> JSONDeserializer<T> {
        return JSONDeserializer { jsonDataObject in
            let json = JSON(jsonDataObject)

            guard let deserializedObject = T(json: json[path].json) else {
                throw JSONDeserializerError.jsonDeserializableInitFailed("Failed to create \(T.self) object form path \(path).")
            }
            return deserializedObject
        }
    }

    class func objectsArrayDeserializer(keyPath path: String...) -> JSONDeserializer<[T]> {
        return JSONDeserializer<[T]>(transform: { jsonDataObject in
            let json = JSON(jsonDataObject)

            guard let jsonArray = json[path].jsonArray else {
                throw JSONDeserializerError.jsonDeserializableInitFailed("Can't cast object at \(path) to array.")
            }

            let deserializedObjects = jsonArray.map { T(json: $0) }

            if deserializedObjects.contains(where: { $0 == nil }) {
                throw JSONDeserializerError.jsonDeserializableInitFailed("Failed to create array of \(T.self) objects.")
            }

            return deserializedObjects.compactMap { $0 }
        })
    }
}
