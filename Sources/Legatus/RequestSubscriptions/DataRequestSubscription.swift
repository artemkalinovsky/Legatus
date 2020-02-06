import Foundation
import Combine
import Alamofire

public final class DataRequestSubscription<S: Subscriber>: Subscription where S.Input == APIResponse, S.Failure == Error {
    private let apiClient: APIClient
    private let apiRequest: APIRequest
    private var dataRequest: DataRequest?
    private var isRequestInProgress = false
    private var subscriber: S?

    init(subscriber: S, apiClient: APIClient, apiRequest: APIRequest) {
        self.subscriber = subscriber
        self.apiClient = apiClient
        self.apiRequest = apiRequest
    }

    public func request(_ demand: Subscribers.Demand) {
        var headers = [String: String]()
        switch apiRequest.configureHeaders() {
        case .success(let configuredHeaders):
            headers = configuredHeaders
        case .failure(let responseError):
            subscriber?.receive(completion: .failure(responseError))
        }
        isRequestInProgress = true
        dataRequest = apiClient.manager.request(apiRequest.configurePath(baseUrl: apiClient.baseURL),
                                                method: apiRequest.method,
                                                parameters: apiRequest.parameters,
                                                encoding: apiRequest.encoding,
                                                headers: headers).response { [weak self] dataResponse in
                                                    self?.isRequestInProgress = false
                                                    guard let self = self else { return }
                                                    guard let error = dataResponse.error else {
                                                        _ = self.subscriber?.receive(dataResponse)
                                                        self.subscriber?.receive(completion: .finished)
                                                        return
                                                    }
                                                    self.subscriber?.receive(completion: .failure(error))
        }
    }

    public func cancel() {
        if isRequestInProgress {
            dataRequest?.cancel()
        }
        dataRequest = nil
        subscriber = nil
    }
}
