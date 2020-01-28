import Foundation

public protocol APIResponse {
    var responseData: Data? { get }
    var httpUrlResponse: HTTPURLResponse? { get }
}
