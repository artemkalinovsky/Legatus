import Foundation
import Alamofire

public extension APIRequest {
    var fullPath: String? {
        nil
    }

    var path: String {
        ""
    }

    var method: Method {
        .get
    }

    var parameters: [String: Any]? {
        nil
    }

    func headers() throws -> [String: String] {
        [:]
    }

    var encoding: ParameterEncoding {
        method == .get ? URLEncoding.default : JSONEncoding.default
    }

    var multipartFormData: [String: URL]? {
        nil
    }

    func configureHeaders() -> Swift.Result<[String: String], Error> {
        var headers = [String: String]()
        do {
            headers = try self.headers()
        } catch {
            return .failure(error)
        }
        return .success(headers)
    }

    func configurePath(baseUrl: URL) -> String {
        var requestPath = baseUrl.appendingPathComponent(self.path).absoluteString
        if let fullPath = self.fullPath, !fullPath.isEmpty {
            requestPath = fullPath
        }
        return requestPath
    }
}
