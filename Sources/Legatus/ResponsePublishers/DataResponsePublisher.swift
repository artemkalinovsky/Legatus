import Alamofire
import Combine
import Foundation

public struct DataResponsePublisher: Publisher {
  public typealias Output = APIResponse
  public typealias Failure = Error

  private let apiClient: APIClient?
  private let apiRequest: APIRequest

  init(apiClient: APIClient?, apiRequest: APIRequest) {
    self.apiClient = apiClient
    self.apiRequest = apiRequest
  }

  public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
    guard let apiClient = apiClient else { return }

    let dataRequestSubscription = DataResponseSubscription(
      subscriber: subscriber,
      apiClient: apiClient,
      apiRequest: apiRequest
    )

    subscriber.receive(subscription: dataRequestSubscription)
  }

}
