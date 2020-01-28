import Foundation
import Combine
import Alamofire

public struct DataRequestPublisher: Publisher {
    public typealias Output = APIResponse
    public typealias Failure = Error

    private let apiClient: APIClient?
    private let apiRequest: APIRequest

    init(apiClient: APIClient?, apiRequest: APIRequest) {
        self.apiClient = apiClient
        self.apiRequest = apiRequest
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        guard let apiClient = apiClient else { return }
        let dataRequestSubscription = DataRequestSubscription(subscriber: subscriber,
                                                              apiClient: apiClient,
                                                              apiRequest: apiRequest)

        subscriber.receive(subscription: dataRequestSubscription)
    }

}
