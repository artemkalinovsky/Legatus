import Foundation
import JASON

extension JSON {

    internal subscript(indexes: [String]) -> JSON {
        if object == nil { return self }

        var json = self

        for index in indexes {
            if let object = json.nsDictionary?[index] {
                json = JSON(object)
                continue
            }
        }

        return json
    }
    
}
