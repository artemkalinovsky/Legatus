import Foundation
import Combine
import Alamofire

public enum APIClientError: Error, Equatable {
    case unreachableNetwork, responseStatusCodeIsNil, responseErrorStatus(Int), requestCancelled
}

open class APIClient: NSObject {
    private struct Constants {
        static let hostNameKey = "host"
        static let reachableKey = "reachable"
    }

    var isReachable: Bool {
        return reachabilityManager?.isReachable ?? false
    }

    let baseURL: URL
    private(set) var manager: SessionManager

    private(set) var multipartRequestProgress: Double = 0
    private var reachabilityManager: NetworkReachabilityManager?

    private let deserializationQueue = DispatchQueue(label: "DeserializationQueue",
                                                     qos: .default,
                                                     attributes: .concurrent)

    private var requestSubscriptions = Set<AnyCancellable>()

    init(baseURL: URL) {
        let configuration: URLSessionConfiguration = {
            let identifier = "URL Session for \(baseURL.absoluteString). Id: \(UUID().uuidString)"
            let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
            return configuration
        }()
        self.baseURL = baseURL
        manager = SessionManager(configuration: configuration)
        
        super.init()

        if let host = baseURL.host {
            reachabilityManager = NetworkReachabilityManager(host: host)
            reachabilityManager?.listener = { status in
                NotificationCenter.default.post(name: Notification.Name.APIClientReachabilityChangedNotification,
                                                object: self,
                                                userInfo: [Constants.hostNameKey: host,
                                                           Constants.reachableKey: status != .notReachable])
            }
            reachabilityManager?.startListening()
        }
    }

    deinit {
        reachabilityManager?.stopListening()
    }

    @discardableResult public func executeRequest<T>(_ request: APIRequest,
                                                     retries: Int = 0,
                                                     deserializer: ResponseDeserializer<T>,
                                                     completion: @escaping (Swift.Result<T, Error>) -> Void) -> AnyCancellable {
        if reachabilityManager?.isReachable == false {
            completion(.failure(APIClientError.unreachableNetwork))
        }

        let responseSubject = PassthroughSubject<(data: Data?, response: HTTPURLResponse?), Error>()
        var isRequestFinished = false

        var cancellableToken: AnyCancellable!

        responseSubject
            .flatMap { self.handle(data: $0.data, response: $0.response, errorKeypath: request.errorKeyPath) }
            .subscribe(on: deserializationQueue)
            .flatMap { deserializer.deserialize(data: $0, headers: $1) }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { receivedCompletion in
                if case let .failure(error) = receivedCompletion {
                    completion(.failure(error))
                }
            }, receiveValue: { value in
                completion(.success(value))
            }).store(in: &requestSubscriptions)

        if let requestInputMultipartData = request.multipartFormData {
            self.multipartRequest(request, requestInputMultipartData: requestInputMultipartData)
                .retry(retries)
                .sink(receiveCompletion: { receivedCompletion in
                    responseSubject.send(completion: receivedCompletion)
                },
                      receiveValue: { dataResponse in
                        responseSubject.send((dataResponse.data, dataResponse.response))
                }).store(in: &requestSubscriptions)
        } else {
            cancellableToken = self.request(request)
                .retry(retries)
                .handleEvents(receiveSubscription: { _ in
                    isRequestFinished = false
                }, receiveCancel: {
                    if isRequestFinished == false {
                        responseSubject.send(completion: .failure(APIClientError.requestCancelled))
                        isRequestFinished = true
                    }
                })
                .sink(receiveCompletion: { receivedCompletion in
                    isRequestFinished = true
                    responseSubject.send(completion: receivedCompletion)
                }, receiveValue: { defaultDataResponse in
                    isRequestFinished = true
                    responseSubject.send((defaultDataResponse.data, defaultDataResponse.response))
                })
            cancellableToken.store(in: &requestSubscriptions)
        }

        return cancellableToken
    }

    @discardableResult public func executeRequest<T: DeserializeableRequest, U>(request: T,
                                                                                retries: Int = 0,
                                                                                completion: @escaping (Swift.Result<U, Error>) -> Void) -> AnyCancellable where U == T.ResponseType {
        return executeRequest(request,
                              retries: retries,
                              deserializer: request.deserializer,
                              completion: completion)
    }

    public func cancelAllRequests() {
        manager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() }
        }
    }

    private func handle(data: Data?,
                        response: HTTPURLResponse?,
                        errorKeypath: String?) -> Future <(Data, [String: Any]?), Error> {
        return Future { promise in
            let headers = response?.allHeaderFields as? [String: Any]
            guard let statusCode = response?.statusCode else {
                promise(.failure(APIClientError.responseStatusCodeIsNil))
                return
            }
            if (200..<300).contains(statusCode) {
                var success = true
                let responseData = data ?? Data(bytes: &success, count: MemoryLayout.size(ofValue: success))
                promise(.success((responseData, headers)))
            } else {
                promise(.failure(APIClientError.responseErrorStatus(statusCode)))
            }
        }
    }

    private func request(_ request: APIRequest) -> AnyPublisher<DefaultDataResponse, Error> {
        return Deferred<DataRequestPublisher> {
            return DataRequestPublisher(apiClient: self, apiRequest: request)
        }.eraseToAnyPublisher()
    }

    private func multipartRequest(_ request: APIRequest,
                                  requestInputMultipartData: [String: URL]) -> AnyPublisher<DataResponse<Data>, Error> {
        return Deferred {
            return Future<DataResponse<Data>, Error> { [weak self] promise in
                guard let self = self else { return }
                self.multipartRequestProgress = 0
                var headers = [String: String]()
                switch request.configureHeaders() {
                case .success(let configuredHeaders):
                    headers = configuredHeaders
                case .failure(let responseError):
                    promise(.failure(responseError))
                }
                self.manager.upload(multipartFormData: { multipartFormData in
                    for requestMultipartData in requestInputMultipartData {
                        multipartFormData.append(requestMultipartData.value,
                                                 withName: requestMultipartData.key)
                    }
                }, to: request.configurePath(baseUrl: self.baseURL),
                   method: request.method,
                   headers: headers) { result in
                    switch result {
                    case .success(let upload, _, _):
                        upload.uploadProgress(closure: { [weak self] progress in
                            self?.multipartRequestProgress = progress.fractionCompleted
                        })
                        upload.responseData(completionHandler: { dataResponse in
                            guard let error = dataResponse.error else {
                                promise(.success(dataResponse))
                                return
                            }
                            promise(.failure(error))
                        })
                    case .failure(let encodingError):
                        promise(.failure(encodingError))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
}
