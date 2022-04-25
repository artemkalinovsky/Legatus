import Combine
import Foundation

// MARK: - Combine support

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
        }
        .eraseToAnyPublisher()
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
        }
        .eraseToAnyPublisher()
    }

}

// MARK: - Swift Concurrency support

extension APIClient {
    public func executeRequest<T>(
        request: APIRequest,
        deserializer: ResponseDeserializer<T>,
        retries: Int = 0,
        uploadProgressObserver: ((Progress) -> Void)? = nil
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            executeRequest(
                request,
                retries: retries,
                deserializer: deserializer,
                uploadProgressObserver: uploadProgressObserver
            ) { result in
                continuation.resume(with: result)
            }
        }
    }

    
    public func executeRequest<T: DeserializeableRequest, U>(
        request: T,
        retries: Int = 0,
        uploadProgressObserver: ((Progress) -> Void)? = nil
    ) async throws -> U where U == T.ResponseType {
        try await withCheckedThrowingContinuation { continuation in
            executeRequest(
                request,
                retries: retries,
                deserializer: request.deserializer,
                uploadProgressObserver: uploadProgressObserver
            ) { result in
                continuation.resume(with: result)
            }
        }
    }
}
