import Foundation
import Combine
import Alamofire

public final class MultipartResponseSubscription<S: Subscriber>: Subscription where S.Input == APIResponse, S.Failure == Error {
    private let apiClient: APIClient
    private let apiRequest: APIRequest
    private let requestInputMultipartData: [String: URL]
    private var uploadRequest: UploadRequest?
    private var uploadProgressObserver: ((Progress) -> Void)?
    private var isRequestInProgress = false
    private var subscriber: S?

    init(subscriber: S,
         apiClient: APIClient,
         apiRequest: APIRequest,
         requestInputMultipartData: [String: URL],
         uploadProgressObserver: ((Progress) -> Void)? = nil) {
        self.subscriber = subscriber
        self.apiClient = apiClient
        self.apiRequest = apiRequest
        self.requestInputMultipartData = requestInputMultipartData
        self.uploadProgressObserver = uploadProgressObserver
    }

    public func request(_ demand: Subscribers.Demand) {
        var headers = HTTPHeaders()
        switch apiRequest.configureHTTPHeaders() {
        case .success(let configuredHeaders):
            headers = configuredHeaders
        case .failure(let responseError):
            subscriber?.receive(completion: .failure(responseError))
        }

        isRequestInProgress = true
        uploadRequest = apiClient.session.upload(
            multipartFormData: { [weak self] multipartFormData in
                self?.requestInputMultipartData.forEach { multipartFormData.append($0.value, withName: $0.key) }
            },
            to: apiRequest.configurePath(baseUrl: apiClient.baseURL),
            method: apiRequest.method,
            headers: headers
        )
        .uploadProgress { [weak self] progress in
            self?.uploadProgressObserver?(progress)
        }
        .responseData { [weak self] dataResponse in
            self?.isRequestInProgress = false
            guard let error = dataResponse.error else {
                _ = self?.subscriber?.receive(dataResponse)
                self?.subscriber?.receive(completion: .finished)
                return
            }
            self?.subscriber?.receive(completion: .failure(error))
        }
    }

    public func cancel() {
        if isRequestInProgress {
            uploadRequest?.cancel()
        }
        uploadRequest = nil
        subscriber = nil
    }
}
