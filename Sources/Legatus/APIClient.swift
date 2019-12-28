import Foundation
import BoltsSwift
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

    private let responseExecutor: Executor = {
        let id = "\(Bundle.main.bundleIdentifier!).\(APIClient.self)"
        return .queue(DispatchQueue(label: id, attributes: .concurrent))
    }()


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
        let source = TaskCompletionSource<(Data, [String: Any]?)>()
        var requestPath = baseURL.appendingPathComponent(request.path).absoluteString
        if let fullPath = request.fullPath, !fullPath.isEmpty {
            requestPath = fullPath
        }

        if let requestMultipartDatas = request.multipartFormData {
            manager.upload(multipartFormData: { multipartFormData in
                for requestMultipartData in requestMultipartDatas {
                    multipartFormData.append(requestMultipartData.value, withName: requestMultipartData.key)
                }
            }, to: requestPath,
               method: request.method,
               headers: request.headers) { result in
                switch result {
                case .success(let upload, _, _):

                    upload.uploadProgress(closure: {[weak self] (progress) in
                        self?.progress = progress.fractionCompleted
                    })
                    upload.responseData(completionHandler: { [weak self] dataResponse in
                        let response = dataResponse.response
                        let data = dataResponse.data
                        let error = dataResponse.error
                        self?.handle(data: data, response: response, error: error, source: source)
                    })
                case .failure(let encodingError):
                    let generatedError = ResponseError(error: encodingError)
                    if !source.task.completed {
                        source.set(error: generatedError!)
                    }
                }
            }

        } else {
            _ = manager.request(requestPath,
                                method: request.method,
                                parameters: request.parameters,
                                encoding: request.encoding,
                                headers: request.headers).response {[weak self]  dataResponse in

                                    let response = dataResponse.response
                                    let data = dataResponse.data
                                    let error = dataResponse.error

                                    self?.handle(data: data, response: response, error: error, source: source)
            }
        }

        source.task.continueOnSuccessWithTask (responseExecutor, continuation: { (data, headers) -> Task<T> in
            return deserializer.deserialize(data, headers: headers)
        }).continueOnSuccessWith(.mainThread, continuation: { response in
            return response
        }).continueWith { task in
            completion(task.result, (task.error as? ResponseError))
        }
    }

    func executeRequest<T, U>(_ request: APIRequest,
                              deserializer: ResponseDeserializer<T>,
                              completion: @escaping (U?, ResponseError?) -> Void) {
        executeRequest(request, deserializer: deserializer) { data, error in
            completion(data as? U, error)
        }
    }

    func handle(data: Data?,
                response: HTTPURLResponse?,
                error: Error?,
                source: TaskCompletionSource<(Data, [String: Any]?)>) {
        let headers = response?.allHeaderFields as? [String: Any]
        var generatedError: ResponseError = ResponseError.resourceInvalidError()
        if let data = data, error == nil && !data.isEmpty {
            let errorSerializer = JSONDeserializer<ResponseError>.singleObjectDeserializer()
            errorSerializer.deserialize(data, headers: headers).continueWith { task in
                if let error = task.result {
                    error.errorCode = APIErrorCode(code: response?.statusCode)
                    source.set(error: error)
                } else {
                    source.set(result: (data, headers))
                }
            }

        } else if let statusCode = response?.statusCode,
            (200..<300).contains(statusCode),
            data?.isEmpty == true {
            var success = true
            let data = Data(bytes: &success, count: MemoryLayout.size(ofValue: success))
            source.set(result: (data, headers))
        } else if let response = response, let statusCodeError = ResponseError(errorCode: response.statusCode) {
            generatedError = statusCodeError
        } else if let error = error {
            generatedError = ResponseError(error: error)!
        }
        if !source.task.completed {
            source.set(error: generatedError)
        }
    }

    func cancelAllRequests() {
        manager.session.invalidateAndCancel()
        manager = SessionManager()
    }

}
