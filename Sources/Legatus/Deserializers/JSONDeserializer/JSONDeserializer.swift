import Foundation
import Combine

public enum JSONDeserializerError: Error {
    case jsonDeserializableInitFailed(String)
}

open class JSONDeserializer<T>: ResponseDeserializer<T> {
    convenience init() {
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

public extension JSONDeserializer where T: Decodable {

    class func singleObjectDeserializer(keyPath path: String...) -> JSONDeserializer<T> {
        return JSONDeserializer { jsonDataObject in
            do {
                if path.isEmpty {
                    return try JSONDecoder().decode(
                        T.self,
                        from: jsonDataObject
                    )
                } else {
                    return try JSONDecoder().decode(
                        T.self,
                        from: jsonDataObject,
                        keyPath: path.joined(separator: ".")
                    )
                }
            } catch {
                throw JSONDeserializerError.jsonDeserializableInitFailed(
                    "Failed to create \(T.self) object form path \(path)."
                )
            }
        }
    }

    class func collectionDeserializer(keyPath path: String...) -> JSONDeserializer<[T]> {
        return JSONDeserializer<[T]> { jsonDataObject in
            do {
                return try JSONDecoder().decode(
                    [T].self,
                    from: jsonDataObject,
                    keyPath: path.joined(separator: ".")
                )
            } catch {
                throw JSONDeserializerError.jsonDeserializableInitFailed(
                    "Failed to create array of \(T.self) objects."
                )
            }
        }
    }

}
