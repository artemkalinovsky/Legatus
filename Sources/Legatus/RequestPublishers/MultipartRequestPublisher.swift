import Foundation
import Combine
import Alamofire

public struct MultipartRequestPublisher: Publisher {
    public typealias Output = DataResponse<Data>
    public typealias Failure = Error

    private let apiClient: APIClient
    private let apiRequest: APIRequest
    private var uploadProgressObserver: ((Progress) -> Void)? = nil

    init(apiClient: APIClient, apiRequest: APIRequest, uploadProgressObserver: ((Progress) -> Void)? = nil) {
        self.apiClient = apiClient
        self.apiRequest = apiRequest
        self.uploadProgressObserver = uploadProgressObserver
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        let multipartRequestSubsription = MultipartRequestSubscription(subscriber: subscriber,
                                                                       apiClient: apiClient,
                                                                       apiRequest: apiRequest,
                                                                       uploadProgressObserver: uploadProgressObserver)

        subscriber.receive(subscription: multipartRequestSubsription)
    }

}
