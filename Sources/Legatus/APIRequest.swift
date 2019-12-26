import Foundation
import Alamofire

public typealias Method = Alamofire.HTTPMethod
public typealias Cleaner = (() -> Void)?

public protocol APIRequest {
    var fullPath: String? { get }
    var path: String { get }
    var parameters: [String: Any]? { get }
    var method: Method { get }
    var scopes: [String]? { get }
    var headers: [String: String] { get }
    var anonymous: Bool { get }
    var encoding: ParameterEncoding { get }
    var multipartFormData: [String: URL]? { get }
}

public protocol SerializeableAPIRequest: APIRequest {

    associatedtype ResponseType
    var serializer: ResponseDeserializer<ResponseType> { get }

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

    var scopes: [String]? {
        return nil
    }

    var anonymous: Bool {
        return false
    }

    var encoding: ParameterEncoding {
        return method == .get ? URLEncoding.default : JSONEncoding.default
    }

    var multipartFormData: [String: URL]? {
        return nil
    }

}

