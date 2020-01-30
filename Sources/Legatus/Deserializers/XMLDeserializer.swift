import Foundation
import Combine
import SWXMLHash

public protocol XMLDeserializable {
    init?(xmlIndexer: XMLIndexer, elementKey: String?)
}

public enum XMLDeserializerError: Error {
    case jsonDeserializableInitFailed(String)
}

open class XMLDeserializer<T>: ResponseDeserializer<T> {

    typealias Transform = ((Data) throws -> T)

    let transform: Transform

    init(transform: @escaping Transform) {
        self.transform = transform
    }

    convenience override init() {
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

    class func singleObjectDeserializer(keyPath: String? = nil) -> XMLDeserializer<T> {
        return XMLDeserializer { xmlDataObject in
            let xml = SWXMLHash.lazy(xmlDataObject)

            guard let deserializedObject = T(xmlIndexer: xml, elementKey: keyPath) else {
                throw XMLDeserializerError.jsonDeserializableInitFailed("Failed to create \(T.self) object.")
            }
            return deserializedObject
        }
    }

    class func objectsArrayDeserializer(keyPath: String? = nil) -> XMLDeserializer<[T]> {
        return XMLDeserializer<[T]>(transform: { xmlDataObject in
            let xml = SWXMLHash.lazy(xmlDataObject)

            let xmlArray = keyPath == nil ? xml.all : xml[keyPath!].all

            if xmlArray.isEmpty {
                return []
            }

            let deserializedObjects = xmlArray.map { T(xmlIndexer: $0, elementKey: keyPath) }

            if deserializedObjects.contains(where: { $0 == nil }) {
                throw XMLDeserializerError.jsonDeserializableInitFailed("Failed to create array of \(T.self) objects.")
            }

            return deserializedObjects.compactMap { $0 }
        })
    }
}
