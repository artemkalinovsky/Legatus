import Foundation
import Alamofire

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

    func configureHTTPHeaders() -> Swift.Result<HTTPHeaders, Error> {
        var headers = [String: String]()
        do {
            headers = try self.headers()
        } catch {
            return .failure(error)
        }
        return .success(.init(headers))
    }

    func configurePath(baseUrl: URL) -> String {
        var requestPath = baseUrl.appendingPathComponent(self.path).absoluteString
        if let fullPath = self.fullPath, !fullPath.isEmpty {
            requestPath = fullPath
        }
        return requestPath
    }
}
