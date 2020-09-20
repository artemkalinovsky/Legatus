import Foundation
import Combine
import SWXMLHash

public protocol XMLDeserializable {
    init?(xmlIndexer: XMLIndexer)
}

public enum XMLDeserializerError: Error {
    case jsonDeserializableInitFailed(String)
}

open class XMLDeserializer<T>: ResponseDeserializer<T> {
    convenience init() {
        self.init { xmlObject -> T in
            if let xmlObject = xmlObject as? T {
                return xmlObject
            }
            throw XMLDeserializerError.jsonDeserializableInitFailed("Wrong result type: \(xmlObject.self). Expected \(T.self)")
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

public extension XMLDeserializer where T: XMLDeserializable {

    class func singleObjectDeserializer(keyPath path: String...) -> XMLDeserializer<T> {
        return XMLDeserializer { xmlDataObject in
            let xml = SWXMLHash.lazy(xmlDataObject)
            guard let deserializedObject = T(xmlIndexer: xml[path]) else {
                throw XMLDeserializerError.jsonDeserializableInitFailed("Failed to create \(T.self) object.")
            }
            return deserializedObject
        }
    }

    class func objectsArrayDeserializer(keyPath path: String...) -> XMLDeserializer<[T]> {
        return XMLDeserializer<[T]>(transform: { xmlDataObject in
            let xml = SWXMLHash.lazy(xmlDataObject)

            let deserializedObjects = xml[path].all.map { T(xmlIndexer: $0) }

            if deserializedObjects.contains(where: { $0 == nil }) {
                throw XMLDeserializerError.jsonDeserializableInitFailed("Failed to create array of \(T.self) objects.")
            }

            return deserializedObjects.compactMap { $0 }
        })
    }
}
