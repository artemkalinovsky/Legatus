import Combine
import Foundation

public enum JSONDeserializerError: Error {
    case jsonDeserializableInitFailed(String)
}

open class JSONDeserializer<T>: ResponseDeserializer<T> {
    convenience init() {
        self.init { jsonObject -> T in
            guard let object = jsonObject as? T else {
                throw JSONDeserializerError.jsonDeserializableInitFailed(
                    "Wrong result type: \(jsonObject.self). Expected \(T.self)"
                )
            }

            return object
        }
    }

    public override func deserialize(data: Data) -> Future<T, Error> {
        Future { [weak self] promise in
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

extension JSONDeserializer where T: Decodable {

    public class func singleObjectDeserializer(keyPath path: String...) -> JSONDeserializer<T> {
        JSONDeserializer { jsonDataObject in
            do {
                let jsonDecoder = JSONDecoder()

                return try path.isEmpty
                    ? jsonDecoder.decode(T.self, from: jsonDataObject)
                    : jsonDecoder.decode(T.self, from: jsonDataObject, keyPath: path.joined(separator: "."))
            } catch {
                throw JSONDeserializerError.jsonDeserializableInitFailed(
                    "Failed to create \(T.self) object form path \(path)."
                )
            }
        }
    }

    public class func collectionDeserializer(keyPath path: String...) -> JSONDeserializer<[T]> {
        JSONDeserializer<[T]> { jsonDataObject in
            do {
                let jsonDecoder = JSONDecoder()

                return try path.isEmpty
                    ? jsonDecoder.decode([T].self, from: jsonDataObject)
                    : jsonDecoder.decode([T].self, from: jsonDataObject, keyPath: path.joined(separator: "."))
            } catch {
                throw JSONDeserializerError.jsonDeserializableInitFailed(
                    "Failed to create array of \(T.self) objects."
                )
            }
        }
    }

}
