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

    var progress: Double = 0

    private let baseURL: URL
    private var manager: SessionManager
    private var reachabilityManager: NetworkReachabilityManager?

    private let deserializationQueue = DispatchQueue(label: "DeserializationQueue",
                                                     qos: .default,
                                                     attributes: .concurrent)

    private var requestSubscriptions = Set<AnyCancellable>()

    init(baseURL: URL) {
        let configuration: URLSessionConfiguration = {
            let identifier = "com.company.app.background-session"
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

    func executeRequest<T>(_ request: APIRequest,
                           deserializer: ResponseDeserializer<T>,
                           completion: @escaping (T?, ResponseError?) -> Void) {
        if reachabilityManager?.isReachable == false {
            completion(nil, ResponseError(errorCode: .noInternetConnection))
        }

        if let requestMultipartDatas = request.multipartFormData {
            //            manager.upload(multipartFormData: { multipartFormData in
            //                for requestMultipartData in requestMultipartDatas {
            //                    multipartFormData.append(requestMultipartData.value, withName: requestMultipartData.key)
            //                }
            //            }, to: requestPath,
            //               method: request.method,
            //               headers: request.headers) { result in
            //                switch result {
            //                case .success(let upload, _, _):
            //
            //                    upload.uploadProgress(closure: {[weak self] (progress) in
            //                        self?.progress = progress.fractionCompleted
            //                    })
            //                    upload.responseData(completionHandler: { [weak self] dataResponse in
            //                        let response = dataResponse.response
            //                        let data = dataResponse.data
            //                        let error = dataResponse.error
            //                        self?.handle(data: data, response: response, error: error, source: source)
            //                    })
            //                case .failure(let encodingError):
            //                    let generatedError = ResponseError(error: encodingError)
            //                    if !source.task.completed {
            //                        source.set(error: generatedError!)
            //                    }
            //                }
            //            }

        } else {
            //            _ = manager.request(requestPath,
            //                                method: request.method,
            //                                parameters: request.parameters,
            //                                encoding: request.encoding,
            //                                headers: request.headers).response {[weak self]  dataResponse in
            //                                    self?.handle(data: dataResponse.data,
            //                                                 response: dataResponse.response,
            //                                                 error: dataResponse.error,
            //                                                 source: source)
            //            }
            self.request(request)
                .flatMap { self.handle(data: $0.data, response: $0.response, error: $0.error) }
                .subscribe(on: deserializationQueue)
                .flatMap { deserializer.deserialize($0, headers: $1) }
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { receivedCompletion in
                    if case let .failure(error) = receivedCompletion {
                        completion(nil, error as? ResponseError)
                    }
                }, receiveValue: { value in
                    completion(value, nil)
                }).store(in: &requestSubscriptions)
        }

        //        source.task.continueOnSuccessWithTask (responseExecutor, continuation: { (data, headers) -> Task<T> in
        //            return deserializer.deserialize(data, headers: headers)
        //        }).continueOnSuccessWith(.mainThread, continuation: { response in
        //            return response
        //        }).continueWith { task in
        //            completion(task.result, (task.error as? ResponseError))
        //        }
    }

    func executeRequest<T, U>(_ request: APIRequest,
                              deserializer: ResponseDeserializer<T>,
                              completion: @escaping (U?, ResponseError?) -> Void) {
        executeRequest(request, deserializer: deserializer) { data, error in
            completion(data as? U, error)
        }
    }

    func executeRequest<T: DeserializeableRequest, U>(request: T,
                                                      completion: @escaping (U?, ResponseError?) -> Void) where U == T.ResponseType {
        executeRequest(request,
                       deserializer: request.deserializer,
                       completion: completion)
    }

    func handle(data: Data?,
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
            } else if let statusCode = response?.statusCode,
                (200..<300).contains(statusCode),
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

    func cancelAllRequests() {
        manager.session.invalidateAndCancel()
        manager = SessionManager()
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

    //    private func multipartRequest(_ request: APIRequest) -> Future<DefaultDataResponse, Never> {
    //        return Future { promise in
    //            _ = self.manager.request(self.path(for: request),
    //                                     method: request.method,
    //                                     parameters: request.parameters,
    //                                     encoding: request.encoding,
    //                                     headers: request.headers).response {dataResponse in
    //                                        promise(.success(dataResponse))
    //            }
    //        }
    //    }


    private func path(for request: APIRequest) -> String {
        var requestPath = baseURL.appendingPathComponent(request.path).absoluteString
        if let fullPath = request.fullPath, !fullPath.isEmpty {
            requestPath = fullPath
        }

        return requestPath
    }
}
