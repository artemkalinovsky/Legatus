import Foundation
import JASON

public enum APIErrorCode: Int {
    case serverError = -1009
    case noInternetConnection = -1008
    case requestTimedOut = -1001
    case cancelled = -999
    case backgroundLoadFailed = -997
    case internalServerError = 500
    case serviceTemporarilyUnavailable = 503
    case badRequest = 400
    case forbidden = 403
    case notFound = 404
    case authenticationFailed = 401
    case invalidResponse = 3106
    case unknown = 1090

    var message: String {
        switch self {
        case .notFound:
            return "Request not found."
        case .serverError, .requestTimedOut:
            return "Please check internet connection."
        case .noInternetConnection:
            return "There seems to be a problem with you Internet connection. Please check it and try again."
        case .badRequest:
            return "Bad request."
        case .forbidden:
            return "You have posted inappropriate content, and your account has been blocked. For more info, contact support."
        case .authenticationFailed:
            return "Authorization failed."
        case .serviceTemporarilyUnavailable, .internalServerError:
            return "Service temporarily unavailable."
        case .invalidResponse:
            return "Invalid response."
        default:
            return "Unknown error \(rawValue)."
        }
    }

    init(code: Int?) {
        if let code = code, let error = APIErrorCode(rawValue: code) {
            self = error
        } else {
            self = .unknown
        }
    }

    var isOfflineError: Bool {
        return self == .serverError || self == .requestTimedOut || self == .backgroundLoadFailed
    }
}

open class ResponseError: Error, JSONDeserializable {
    var errorCode: APIErrorCode
    var message: String?

    public required init?(json: JSON) {
        return nil
    }

    required public init?(decodingRepresentation representation: [String: Any]) {
        if let errors = representation["errors"] as? [String] {
            self.errorCode = APIErrorCode.invalidResponse
            let fullMessage = errors.first ?? ""
            let index = fullMessage.index(fullMessage.startIndex, offsetBy: min(fullMessage.count, 200))
            self.message = String(fullMessage[..<index])
        } else {
            return nil
        }
    }

    init?(errorCode: Int, message: String? = nil) {
        if let error = APIErrorCode(rawValue: errorCode) {
            self.errorCode = error
            self.message = message ?? self.errorCode.message
        } else if errorCode != 201 && errorCode != 200 {
            self.errorCode = .unknown
            self.message = "Error statusCode = \(errorCode)."
        } else {
            return nil
        }
    }

    init(errorCode: APIErrorCode, message: String? = nil) {
        self.errorCode = errorCode
        self.message = message ?? errorCode.message
    }

    class func resourceInvalidError() -> ResponseError {
        return ResponseError(errorCode: .invalidResponse)
    }

    convenience init?(error: Error?) {
        if let rError = error as? ResponseError {
          self.init(errorCode: rError.errorCode, message: rError.message)
        } else if let error = error {
            self.init(errorCode: APIErrorCode(code: error._code), message: error.localizedDescription)
        } else {
            return nil
        }
    }

}
