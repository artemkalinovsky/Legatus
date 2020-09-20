import Foundation

struct HttpBinGetResponse: Decodable {
    let url: String

    enum CodingKeys: String, CodingKey {
        case url
    }
}
