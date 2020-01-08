import Foundation
import Alamofire

public typealias Method = Alamofire.HTTPMethod

public protocol APIRequest {
    var fullPath: String? { get }
    var path: String { get }
    var parameters: [String: Any]? { get }
    var method: Method { get }
    var encoding: ParameterEncoding { get }
    var multipartFormData: [String: URL]? { get }
    var errorKeyPath: String? { get }
    func headers() throws -> [String: String]
}

public protocol DeserializeableRequest: APIRequest {

    associatedtype ResponseType
    var deserializer: ResponseDeserializer<ResponseType> { get }

}

public enum AuthRequestError: Error {
    case accessTokenIsNil
}

public protocol AuthRequest: APIRequest {

    var accessToken: String? { get set }
    var accessTokenPrefix: String { get }

}

public extension APIRequest where Self: AuthRequest {

     var accessTokenPrefix: String {
        return "Bearer"
    }

    func headers() throws -> [String: String] {
        guard let accessToken = accessToken else {
            throw AuthRequestError.accessTokenIsNil
        }
        return [
            "Authorization": "\(accessTokenPrefix) \(accessToken)",
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

    func headers() throws -> [String: String] {
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

