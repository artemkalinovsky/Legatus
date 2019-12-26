import Foundation
import BoltsSwift

open class JSONDeserializer<T>: ResponseDeserializer<T> {

    typealias Transform = ((Any, [String: Any]?) throws -> T)

    let transform: Transform

    init(transform: @escaping Transform) {
        self.transform = transform
    }

    convenience override init() {
        self.init { jsonObject, _ -> T in
            if let object = jsonObject as? T {
                return object
            }

            throw ResponseError.resourceInvalidError()
        }
    }

    override func deserialize(_ data: Data, headers: [String: Any]? = nil) -> Task<T> {
        let source = TaskCompletionSource<(T)>()
        do {
            let object = try transform(data, headers)
            source.set(result: object)
        } catch {
            source.set(error: error)
        }
        return source.task
    }
}

public extension JSONDeserializer where T: JSONDecodable {

    class func singleObjectDeserializer(keyPath: String? = nil) -> JSONDeserializer<T> {

        return JSONDeserializer { jsonDataObject, _ in
            func map(_ object: [String: Any])throws -> T {
                if let directObject =  T(decodingRepresentation: object) {
                    return directObject
                } else {
                    throw ResponseError.resourceInvalidError()
                }
            }
            var jsonObject = jsonDataObject
            if let jsonData = jsonDataObject as? Data {
                jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
            }
            switch (jsonObject, keyPath) {
            case (let object as [String: AnyObject], let keyPath?):
                if let directObject = (object[keyPath] as? [String: AnyObject]) {
                    return try map(directObject)
                } else {
                    throw ResponseError.resourceInvalidError()
                }
            case (let object as [String: AnyObject], _):
                return try map(object)

            default:
                throw ResponseError.resourceInvalidError()

            }
        }
    }

    class func objectsArrayDeserializer(keyPath: String? = nil) -> JSONDeserializer<[T]> {
        return JSONDeserializer<[T]>(transform: { jsonDataObject, _ in
            func map(_ objects: [[String: AnyObject]]) throws -> [T] {
                return try objects.reduce([T](), { container, rawValue -> [T] in
                    if let value = T(decodingRepresentation: rawValue) {
                        return container + [value]
                    } else {
                        throw ResponseError.resourceInvalidError()
                    }
                })
            }

            var jsonObject = jsonDataObject
            if let jsonData = jsonDataObject as? Data {
                jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
            }
            switch (jsonObject, keyPath) {
            case (let object as [String: AnyObject], let keyPath?):
                if let objects = object[keyPath] as? [[String: AnyObject]] {
                    return try map(objects)
                } else {
                    throw ResponseError.resourceInvalidError()
                }

            case (let objects as [[String: AnyObject]], _):
                return try map(objects)

            default:
                throw ResponseError.resourceInvalidError()
            }
        })
    }
}
