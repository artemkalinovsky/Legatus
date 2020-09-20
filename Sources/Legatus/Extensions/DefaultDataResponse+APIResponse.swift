import Foundation
import Alamofire

extension DefaultDataResponse: APIResponse {
    public var responseData: Data? {
        data
    }

    public var httpUrlResponse: HTTPURLResponse? {
        response
    }
}
