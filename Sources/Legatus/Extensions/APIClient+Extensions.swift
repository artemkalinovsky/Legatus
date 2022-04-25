import Combine
import Foundation

extension APIClient {

    public func responsePublisher<T>(
        request: APIRequest,
        deserializer: ResponseDeserializer<T>,
        uploadProgressObserver: ((Progress) -> Void)? = nil
    ) -> AnyPublisher<T, Error> {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                self.executeRequest(
                    request,
                    deserializer: deserializer,
                    uploadProgressObserver: uploadProgressObserver
                ) { result in
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

    public func responsePublisher<T: DeserializeableRequest, U>(
        request: T,
        uploadProgressObserver: ((Progress) -> Void)? = nil
    ) -> AnyPublisher<U, Error> where U == T.ResponseType {
        Deferred {
            Future { [weak self] promise in
                guard let self = self else { return }

                self.executeRequest(
                    request: request,
                    uploadProgressObserver: uploadProgressObserver
                ) { result in
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
