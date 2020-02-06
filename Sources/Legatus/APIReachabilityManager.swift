import Foundation
import Alamofire

open class APIReachabilityManager {
    public static let shared = APIReachabilityManager()

    @Published public private(set) var isReachable = false
    @Published public private(set) var isStarted = false

    private var reachabilityManager: NetworkReachabilityManager?

    private init() {}

    public func start(for url: URL) {
        guard let host = url.host else { return }
        if isStarted {
            stop()
        }
        reachabilityManager = NetworkReachabilityManager(host: host)
        reachabilityManager?.listener = { [unowned self] status in
            self.isReachable = status == .reachable(.ethernetOrWiFi) || status == .reachable(.wwan)
        }
        reachabilityManager?.startListening()
        isReachable = reachabilityManager?.isReachable ?? false
        isStarted = true
    }

    public func stop() {
        reachabilityManager?.stopListening()
        reachabilityManager?.listener = nil
        reachabilityManager = nil
        isStarted = false
        isReachable = false
    }
}
