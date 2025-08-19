@propertyWrapper
public struct Indexed<T> {
    public var wrappedValue: T
    public let fieldType: IndexType
    public let sortable: Bool
    public let noIndex: Bool
    
    public init(
        wrappedValue: T,
        type: IndexType? = nil,
        sortable: Bool = false,
        noIndex: Bool = false
    ) {
        self.wrappedValue = wrappedValue
        self.sortable = sortable
        self.noIndex = noIndex
        
        if let type = type {
            self.fieldType = type
        } else {
            self.fieldType = Self.detectFieldType(for: T.self)
        }
    }
    
    private static func detectFieldType(for type: Any.Type) -> IndexType {
        switch type {
        case is String.Type, is String?.Type:
            return .text
        case is Int.Type, is Int?.Type,
             is Double.Type, is Double?.Type,
             is Float.Type, is Float?.Type:
            return .numeric
        case is Array<String>.Type, is Array<String>?.Type:
            return .tag
//        case is CLLocationCoordinate2D.Type, is CLLocationCoordinate2D?.Type:
//            return .geo
        default:
            return .text
        }
    }
}

//@propertyWrapper
//public struct Indexed<Value: Codable & Sendable>: Codable, Sendable {
//    public var wrappedValue: Value
//    public let type: IndexType
//
//    public init(wrappedValue: Value, _ type: IndexType) {
//        self.wrappedValue = wrappedValue
//        self.type = type
//    }
//}


//@propertyWrapper
//public struct Indexed<Value: Codable & Sendable>: Codable, Sendable {
//    public var wrappedValue: Value
//    public let indexType: IndexType
//    public let options: [String]  // extra args e.g. ["SORTABLE"]
//
//    public init(wrappedValue: Value, _ indexType: IndexType, options: [String] = []) {
//        self.wrappedValue = wrappedValue
//        self.indexType = indexType
//        self.options = options
//    }
//
//    // Codable conformance
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        self.wrappedValue = try container.decode(Value.self)
//        self.indexType = .text
//        self.options = []
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.singleValueContainer()
//        try container.encode(wrappedValue)
//    }
//}

