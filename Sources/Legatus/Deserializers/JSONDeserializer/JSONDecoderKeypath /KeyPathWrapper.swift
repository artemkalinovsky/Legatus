/// Object which is representing value
final class KeyPathWrapper<T: Decodable>: Decodable {

    enum KeyPathError: Error {
        case `internal`
    }

    /// Naive coding key implementation
    struct Key: CodingKey {
        init?(intValue: Int) {
            self.intValue = intValue
            stringValue = String(intValue)
        }

        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }

        let intValue: Int?
        let stringValue: String
    }

    typealias KeyedContainer = KeyedDecodingContainer<KeyPathWrapper<T>.Key>

    init(from decoder: Decoder) throws {
        guard let keyPath = decoder.userInfo[UserInfoKeys.decodingContext] as? [String],
            !keyPath.isEmpty
            else { throw KeyPathError.internal }

        /// Creates a `Key` from the first keypath element
        func getKey(from keyPath: [String]) throws -> Key {
            guard let first = keyPath.first,
                let key = Key(stringValue: first)
                else { throw KeyPathError.internal }
            return key
        }

        /// Finds nested container and returns it and the key for object
        func objectContainer(
            for keyPath: [String],
            in currentContainer: KeyedContainer,
            key currentKey: Key
        ) throws -> (KeyedContainer, Key) {
            guard !keyPath.isEmpty else { return (currentContainer, currentKey) }
            let container = try currentContainer.nestedContainer(keyedBy: Key.self, forKey: currentKey)
            let key = try getKey(from: keyPath)
            return try objectContainer(for: Array(keyPath.dropFirst()), in: container, key: key)
        }

        let rootKey = try getKey(from: keyPath)
        let rooTContainer = try decoder.container(keyedBy: Key.self)

        let (keyedContainer, key) = try objectContainer(
            for: Array(keyPath.dropFirst()),
            in: rooTContainer,
            key: rootKey
        )

        object = try keyedContainer.decode(T.self, forKey: key)
    }

    let object: T
}
