import Foundation
import Alamofire

extension DataResponse: APIResponse {
    public var responseData: Data? {
        return data
    }

    public var httpUrlResponse: HTTPURLResponse? {
        return response
    }
}
