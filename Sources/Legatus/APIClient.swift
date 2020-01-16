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
                                                     uploadProgressObserver: ((Progress) -> Void)? = nil,
                                                     completion: @escaping (Swift.Result<T, Error>) -> Void) -> AnyCancellable? {
        var cancellableToken: AnyCancellable?

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
            cancellableToken = multipartRequestResponsePublisher(request,
                                                                 requestInputMultipartData: requestInputMultipartData,
                                                                 uploadProgressObserver: uploadProgressObserver)
                .retry(retries)
                .handleEvents(receiveCancel: {
                    responseSubject.send(completion: .failure(APIClientError.requestCancelled))
                })
                .sink(receiveCompletion: { receivedCompletion in
                    responseSubject.send(completion: receivedCompletion)
                },
                      receiveValue: { dataResponse in
                        responseSubject.send((dataResponse.data, dataResponse.response))
                })
            cancellableToken?.store(in: &requestSubscriptions)
        } else {
            cancellableToken = requestResponsePublisher(request)
                .retry(retries)
                .handleEvents(receiveCancel: {
                    responseSubject.send(completion: .failure(APIClientError.requestCancelled))
                })
                .sink(receiveCompletion: { receivedCompletion in
                    responseSubject.send(completion: receivedCompletion)
                }, receiveValue: { defaultDataResponse in
                    responseSubject.send((defaultDataResponse.data, defaultDataResponse.response))
                })
            cancellableToken?.store(in: &requestSubscriptions)
        }

        return cancellableToken
    }

    @discardableResult public func executeRequest<T: DeserializeableRequest, U>(request: T,
                                                                                retries: Int = 0,
                                                                                uploadProgressObserver: ((Progress) -> Void)? = nil,
                                                                                completion: @escaping (Swift.Result<U, Error>) -> Void) -> AnyCancellable? where U == T.ResponseType {
        return executeRequest(request,
                              retries: retries,
                              deserializer: request.deserializer,
                              uploadProgressObserver: uploadProgressObserver,
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
            guard (200..<300).contains(statusCode) else {
                promise(.failure(APIClientError.responseErrorStatus(statusCode)))
                return
            }
            var success = true
            let responseData = data ?? Data(bytes: &success, count: MemoryLayout.size(ofValue: success))
            promise(.success((responseData, headers)))
        }
    }

    private func requestResponsePublisher(_ request: APIRequest) -> AnyPublisher<DefaultDataResponse, Error> {
        return Deferred<DataRequestPublisher> { [weak self] in
            return DataRequestPublisher(apiClient: self, apiRequest: request)
        }.eraseToAnyPublisher()
    }

    private func multipartRequestResponsePublisher(_ request: APIRequest,
                                                   requestInputMultipartData: [String: URL],
                                                   uploadProgressObserver: ((Progress) -> Void)? = nil) -> AnyPublisher<DataResponse<Data>, Error> {
        return Deferred { [weak self] in
            return MultipartRequestPublisher(apiClient: self,
                                             apiRequest: request,
                                             uploadProgressObserver: uploadProgressObserver)
        }.eraseToAnyPublisher()
    }
}
