import Foundation

public extension JSONDecoder {

    /// Decode value at the keypath of the given type from the given JSON representation
    ///
    /// - Parameters:
    ///   - type: The type of the value to decode.
    ///   - data: The data to decode from.
    ///   - keyPath: The JSON keypath
    ///   - keyPathSeparator: Nested keypath separator
    /// - Returns: A value of the requested type.
    /// - Throws: An error if any value throws an error during decoding.
    func decode<T>(_ type: T.Type,
                   from data: Data,
                   keyPath: String,
                   keyPathSeparator separator: String = ".") throws -> T where T: Decodable {
        userInfo[UserInfoKeys.decodingContext] = keyPath.components(separatedBy: separator)
        return try decode(KeyPathWrapper<T>.self, from: data).object
    }

}
