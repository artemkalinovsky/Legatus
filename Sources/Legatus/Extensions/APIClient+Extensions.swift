import Foundation
import Combine

public extension APIClient {

    func requestPublisher<T>(_ request: APIRequest,
                             deserializer: ResponseDeserializer<T>,
                             uploadProgressObserver: ((Progress) -> Void)? = nil) -> AnyPublisher<T, Error> {
        return Deferred {
            return Future { promise in
                self.executeRequest(request,
                                    deserializer: deserializer,
                                    uploadProgressObserver: uploadProgressObserver) { result in
                                        switch result {
                                        case .success(let deserializedObjects):
                                            promise(.success(deserializedObjects))
                                        case .failure(let error):
                                            promise(.failure(error))
                                        }
                }
            }
        }.eraseToAnyPublisher()
    }

    func requestPublisher<T: DeserializeableRequest, U>(request: T,
                                                        uploadProgressObserver: ((Progress) -> Void)? = nil) -> AnyPublisher<U, Error> where U == T.ResponseType {
        return Deferred {
            return Future { promise in
                self.executeRequest(request: request,
                                    uploadProgressObserver: uploadProgressObserver) { result in
                                        switch result {
                                        case .success(let deserializedObjects):
                                            promise(.success(deserializedObjects))
                                        case .failure(let error):
                                            promise(.failure(error))
                                        }
                }
            }
        }.eraseToAnyPublisher()
    }

}
