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
        "Bearer"
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
