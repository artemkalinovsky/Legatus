import Foundation
import Alamofire

extension DataResponse: APIResponse {
    public var responseData: Data? {
        data
    }

    public var httpUrlResponse: HTTPURLResponse? {
        response
    }
}
