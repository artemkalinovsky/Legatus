import Foundation
import Alamofire

public typealias Method = Alamofire.HTTPMethod

public protocol APIRequest {
    var fullPath: String? { get }
    var path: String { get }
    var parameters: [String: Any]? { get }
    var method: Method { get }
    var headers: [String: String] { get }
    var encoding: ParameterEncoding { get }
    var multipartFormData: [String: URL]? { get }
    var errorKeyPath: String? { get }
}

public protocol DeserializeableRequest: APIRequest {

    associatedtype ResponseType
    var deserializer: ResponseDeserializer<ResponseType> { get }

}

public protocol AuthRequest {

    var accessToken: String? { get set }

}

public extension APIRequest where Self: AuthRequest {

    // TODO: Convert to throwable method
    var headers: [String: String] {
        return [
            "Authorization": "Token token=" + (accessToken ?? ""),
            "accept-language": Locale.current.identifier
        ]
    }

}

public extension APIRequest {
    var fullPath: String? {
        return nil
    }

    var path: String {
        return ""
    }

    var method: Method {
        return .get
    }

    var parameters: [String: Any]? {
        return nil
    }

    var headers: [String: String] {
        return [:]
    }

    var encoding: ParameterEncoding {
        return method == .get ? URLEncoding.default : JSONEncoding.default
    }

    var multipartFormData: [String: URL]? {
        return nil
    }

    var errorKeyPath: String? {
        return nil
    }
}

