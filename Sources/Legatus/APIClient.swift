import Foundation
import Combine
import Alamofire

public enum APIClientError: Error {
    case unreachableNetwork, responseStatusCodeIsNil, responseErrorStatus(Int)
}

open class APIClient: NSObject {
    private struct Constants {
        static let hostNameKey = "host"
        static let reachableKey = "reachable"
    }

    var isReachable: Bool {
        return reachabilityManager?.isReachable ?? false
    }

    private(set) var multipartRequestProgress: Double = 0

    private let baseURL: URL
    private var manager: SessionManager
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

    public func executeRequest<T>(_ request: APIRequest,
                                  retries: Int = 0,
                                  deserializer: ResponseDeserializer<T>,
                                  completion: @escaping (Swift.Result<T, Error>) -> Void) {
        if reachabilityManager?.isReachable == false {
            completion(.failure(APIClientError.unreachableNetwork))
        }

        let responseSubject = PassthroughSubject<(data: Data?, response: HTTPURLResponse?), Error>()

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
            self.request(request)
                .retry(retries)
                .sink(receiveCompletion: { receivedCompletion in
                    responseSubject.send(completion: receivedCompletion)
                }, receiveValue: { defaultDataResponse in
                    responseSubject.send((defaultDataResponse.data, defaultDataResponse.response))
                }).store(in: &requestSubscriptions)
        }
    }

    public func executeRequest<T: DeserializeableRequest, U>(request: T,
                                                             retries: Int = 0,
                                                             completion: @escaping (Swift.Result<U, Error>) -> Void) where U == T.ResponseType {
        executeRequest(request,
                       retries: retries,
                       deserializer: request.deserializer,
                       completion: completion)
    }

    public func cancelAllRequests() {
        manager.session.invalidateAndCancel()
        manager = SessionManager()
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
        return Deferred {
            return Future<DefaultDataResponse, Error> { [weak self] promise in
                guard let self = self else { return }
                var headers = [String: String]()
                switch self.configureHeaders(for: request) {
                case .success(let configuredHeaders):
                    headers = configuredHeaders
                case .failure(let responseError):
                    promise(.failure(responseError))
                }
                _ = self.manager.request(self.configurePath(for: request),
                                         method: request.method,
                                         parameters: request.parameters,
                                         encoding: request.encoding,
                                         headers: headers).response { dataResponse in
                                            guard let error = dataResponse.error else {
                                                promise(.success(dataResponse))
                                                return
                                            }
                                            promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }

    private func multipartRequest(_ request: APIRequest,
                                  requestInputMultipartData: [String: URL]) -> AnyPublisher<DataResponse<Data>, Error> {
        return Deferred {
            return Future<DataResponse<Data>, Error> { [weak self] promise in
                guard let self = self else { return }
                self.multipartRequestProgress = 0
                var headers = [String: String]()
                switch self.configureHeaders(for: request) {
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
                }, to: self.configurePath(for: request),
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

    private func configureHeaders(for request: APIRequest) -> Swift.Result<[String: String], Error> {
        var headers = [String: String]()
        do {
            headers = try request.headers()
        } catch {
            return .failure(error)
        }
        return .success(headers)
    }

    private func configurePath(for request: APIRequest) -> String {
        var requestPath = baseURL.appendingPathComponent(request.path).absoluteString
        if let fullPath = request.fullPath, !fullPath.isEmpty {
            requestPath = fullPath
        }

        return requestPath
    }
}
