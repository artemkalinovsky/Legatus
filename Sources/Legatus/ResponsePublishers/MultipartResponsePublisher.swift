import Foundation
import Combine
import Alamofire

public struct MultipartResponsePublisher: Publisher {
    public typealias Output = APIResponse
    public typealias Failure = Error

    private let apiClient: APIClient?
    private let apiRequest: APIRequest
    private let requestInputMultipartData: [String: URL]
    private var uploadProgressObserver: ((Progress) -> Void)?

    init(apiClient: APIClient?,
         apiRequest: APIRequest,
         requestInputMultipartData: [String: URL],
         uploadProgressObserver: ((Progress) -> Void)? = nil) {
        self.apiClient = apiClient
        self.apiRequest = apiRequest
        self.requestInputMultipartData = requestInputMultipartData
        self.uploadProgressObserver = uploadProgressObserver
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        guard let apiClient = apiClient else { return }

        let multipartRequestSubsription = MultipartResponseSubscription(
            subscriber: subscriber,
            apiClient: apiClient,
            apiRequest: apiRequest,
            requestInputMultipartData: requestInputMultipartData,
            uploadProgressObserver: uploadProgressObserver
        )

        subscriber.receive(subscription: multipartRequestSubsription)
    }

}
