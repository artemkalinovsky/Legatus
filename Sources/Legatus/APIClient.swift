import Foundation
import Combine
import Alamofire

public enum APIClientError: Error, Equatable {
    case responseStatusCodeIsNil, responseErrorStatus(Int), requestCancelled
}

open class APIClient {
    let baseURL: URL
    let session = Session.default

    private let deserializationQueue = DispatchQueue(label: "DeserializationQueue",
                                                     qos: .default,
                                                     attributes: .concurrent)

    private var requestSubscriptions = Set<AnyCancellable>()

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    @discardableResult public func executeRequest<T>(_ request: APIRequest,
                                                     retries: Int = 0,
                                                     deserializer: ResponseDeserializer<T>,
                                                     uploadProgressObserver: ((Progress) -> Void)? = nil,
                                                     completion: @escaping (Swift.Result<T, Error>) -> Void) -> AnyCancellable {
        let requestPublisher = request.multipartFormData == nil
        ? requestResponsePublisher(request)
        : multipartRequestResponsePublisher(
            request,
            requestInputMultipartData: request.multipartFormData!,
            uploadProgressObserver: uploadProgressObserver
        )

        let cancellableToken = requestPublisher
            .retry(retries)
            .handleEvents(receiveCancel: {
                completion(.failure(APIClientError.requestCancelled))
            })
            .flatMap { self.handle(apiResponse: $0) }
            .subscribe(on: deserializationQueue)
            .flatMap { deserializer.deserialize(data: $0) }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { receivedCompletion in
                    if case let .failure(error) = receivedCompletion {
                        completion(.failure(error))
                    }
                },
                receiveValue: { value in
                    completion(.success(value))
                }
            )

        cancellableToken.store(in: &requestSubscriptions)

        return cancellableToken
    }

    @discardableResult public func executeRequest<T: DeserializeableRequest, U>(
        request: T,
        retries: Int = 0,
        uploadProgressObserver: ((Progress) -> Void)? = nil,
        completion: @escaping (Swift.Result<U, Error>) -> Void
    ) -> AnyCancellable where U == T.ResponseType {
        executeRequest(
            request,
            retries: retries,
            deserializer: request.deserializer,
            uploadProgressObserver: uploadProgressObserver,
            completion: completion
        )
    }

    public func cancelAllRequests() {
        requestSubscriptions.forEach { $0.cancel() }
        session.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
    }

    private func handle(apiResponse: APIResponse) -> AnyPublisher<Data, Error> {
        Future { promise in
            guard let statusCode = apiResponse.httpUrlResponse?.statusCode else {
                promise(.failure(APIClientError.responseStatusCodeIsNil))
                return
            }
            guard (200..<300).contains(statusCode) else {
                promise(.failure(APIClientError.responseErrorStatus(statusCode)))
                return
            }
            var success = true
            let responseData = apiResponse.responseData ?? Data(bytes: &success,
                                                                count: MemoryLayout.size(ofValue: success))
            promise(.success(responseData))
        }
        .eraseToAnyPublisher()
    }

    private func requestResponsePublisher(_ request: APIRequest) -> AnyPublisher<APIResponse, Error> {
        Deferred<DataResponsePublisher> { [weak self] in
            DataResponsePublisher(apiClient: self, apiRequest: request)
        }
        .eraseToAnyPublisher()
    }

    private func multipartRequestResponsePublisher(_ request: APIRequest,
                                                   requestInputMultipartData: [String: URL],
                                                   uploadProgressObserver: ((Progress) -> Void)? = nil) -> AnyPublisher<APIResponse, Error> {
        Deferred { [weak self] in
            MultipartResponsePublisher(apiClient: self,
                                       apiRequest: request,
                                       requestInputMultipartData: requestInputMultipartData,
                                       uploadProgressObserver: uploadProgressObserver)
        }
        .eraseToAnyPublisher()
    }
}
