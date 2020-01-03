import Foundation
import Combine
import Alamofire

open class APIClient: NSObject {
    private struct Constants {
        static let hostNameKey = "host"
        static let reachableKey = "reachable"
    }

    var isReachable: Bool {
        return reachabilityManager?.isReachable ?? false
    }

    private var progress: Double = 0

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
                                  deserializer: ResponseDeserializer<T>,
                                  completion: @escaping (Swift.Result<T, ResponseError>) -> Void) {
        if reachabilityManager?.isReachable == false {
            completion(.failure(ResponseError(errorCode: .noInternetConnection)))
        }

        if let requestInputMultipartData = request.multipartFormData {
            self.multipartRequest(request, requestInputMultipartData: requestInputMultipartData)
                .flatMap { self.handle(data: $0.data, response: $0.response, error: $0.error) }
                .subscribe(on: deserializationQueue)
                .flatMap { deserializer.deserialize($0, headers: $1) }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { receivedCompletion in
                    if case let .failure(error) = receivedCompletion,
                        let responseError = error as? ResponseError {
                        completion(.failure(responseError))
                    }
                }, receiveValue: { value in
                    completion(.success(value))
                }).store(in: &requestSubscriptions)
        } else {
            self.request(request)
                .flatMap { self.handle(data: $0.data, response: $0.response, error: $0.error) }
                .subscribe(on: deserializationQueue)
                .flatMap { deserializer.deserialize($0, headers: $1) }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { receivedCompletion in
                    if case let .failure(error) = receivedCompletion,
                        let responseError = error as? ResponseError {
                        completion(.failure(responseError))
                    }
                }, receiveValue: { value in
                    completion(.success(value))
                }).store(in: &requestSubscriptions)
        }
    }

    public func executeRequest<T, U>(_ request: APIRequest,
                                     deserializer: ResponseDeserializer<T>,
                                     completion: @escaping (Swift.Result<U, ResponseError>) -> Void) {
        executeRequest(request, deserializer: deserializer) { result in
            switch result {
            case .success(let responseObject):
                guard let castedResponseObject = responseObject as? U else {
                    completion(.failure(ResponseError(errorCode: .wrongResponseType)))
                    return
                }
                completion(.success(castedResponseObject))
            case .failure(let error):
                completion(.failure(error))

            }
        }
    }

    public func executeRequest<T: DeserializeableRequest, U>(request: T,
                                                             completion: @escaping (Swift.Result<U, ResponseError>) -> Void) where U == T.ResponseType {
        executeRequest(request,
                       deserializer: request.deserializer,
                       completion: completion)
    }

    public func cancelAllRequests() {
        manager.session.invalidateAndCancel()
        manager = SessionManager()
    }

    private func handle(data: Data?,
                        response: HTTPURLResponse?,
                        error: Error?) -> Future <(Data, [String: Any]?), Error> {
        var errorDeserializerSubscriptions = Set<AnyCancellable>()
        return Future { promise in
            let headers = response?.allHeaderFields as? [String: Any]
            var generatedError: ResponseError = ResponseError.resourceInvalidError()
            if let data = data, error == nil && !data.isEmpty {
                let errordeserializer = JSONDeserializer<ResponseError>.singleObjectDeserializer()
                errordeserializer.deserialize(data, headers: headers)
                    .sink(receiveCompletion: { errorCompletion in
                        if case .failure = errorCompletion {
                            promise(.success((data, headers)))
                        }
                    },
                          receiveValue: { deserializedError in
                            deserializedError.errorCode = APIErrorCode(code: response?.statusCode)
                            promise(.failure(deserializedError))
                    }).store(in: &errorDeserializerSubscriptions)
            } else if let statusCode = response?.statusCode, (200..<300).contains(statusCode),
                data?.isEmpty == true {
                var success = true
                let data = Data(bytes: &success, count: MemoryLayout.size(ofValue: success))
                promise(.success((data, headers)))
            } else if let response = response, let statusCodeError = ResponseError(errorCode: response.statusCode) {
                generatedError = statusCodeError
                promise(.failure(generatedError))
            } else if let error = error {
                generatedError = ResponseError(error: error)!
                promise(.failure(generatedError))
            }
        }
    }

    private func request(_ request: APIRequest) -> Future<DefaultDataResponse, Error> {
        return Future { promise in
            _ = self.manager.request(self.path(for: request),
                                     method: request.method,
                                     parameters: request.parameters,
                                     encoding: request.encoding,
                                     headers: request.headers).response { dataResponse in
                                        promise(.success(dataResponse))
            }
        }
    }

    private func multipartRequest(_ request: APIRequest,
                                  requestInputMultipartData: [String: URL]) -> Future<DataResponse<Data>, Error> {
        progress = 0
        return Future { promise in
            self.manager.upload(multipartFormData: { multipartFormData in
                for requestMultipartData in requestInputMultipartData {
                    multipartFormData.append(requestMultipartData.value,
                                             withName: requestMultipartData.key)
                }
            }, to: self.path(for: request),
               method: request.method,
               headers: request.headers) { result in
                switch result {
                case .success(let upload, _, _):
                    upload.uploadProgress(closure: { [weak self] progress in
                        self?.progress = progress.fractionCompleted
                    })
                    upload.responseData(completionHandler: { dataResponse in
                        promise(.success(dataResponse))
                    })
                case .failure(let encodingError):
                    let generatedError = ResponseError(error: encodingError)
                    promise(.failure(generatedError ?? ResponseError.resourceInvalidError()))
                }
            }
        }
    }


    private func path(for request: APIRequest) -> String {
        var requestPath = baseURL.appendingPathComponent(request.path).absoluteString
        if let fullPath = request.fullPath, !fullPath.isEmpty {
            requestPath = fullPath
        }

        return requestPath
    }
}
