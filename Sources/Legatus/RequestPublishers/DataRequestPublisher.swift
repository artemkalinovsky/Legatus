import Foundation
import Combine
import Alamofire

public struct DataRequestPublisher: Publisher {
    public typealias Output = DefaultDataResponse
    public typealias Failure = Error

    private let apiClient: APIClient
    private let apiRequest: APIRequest

    init(apiClient: APIClient, apiRequest: APIRequest) {
        self.apiClient = apiClient
        self.apiRequest = apiRequest
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        let dataRequestSubscription = DataRequestSubscription(subscriber: subscriber,
                                                              apiClient: apiClient,
                                                              apiRequest: apiRequest)

        subscriber.receive(subscription: dataRequestSubscription)
    }

}
