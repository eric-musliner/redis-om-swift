/// Helper type for models to define Geo Points
public struct Coordinate: Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// A geographic filter to be applied in queries.
public struct GeoFilter: Sendable {
    public let origin: Coordinate
    public let radius: Double
    public let unit: Unit

    public init(origin: Coordinate, radius: Double, unit: Unit) {
        self.origin = origin
        self.radius = radius
        self.unit = unit
    }

    /// Units supported by RediSearch (`m`, `km`, `mi`, `ft`).
    public enum Unit: String, Sendable {
        case meters = "m"
        case kilometers = "km"
        case miles = "mi"
        case feet = "ft"
    }
}

/// A numeric range filter.
public struct NumericRange: Sendable {
    public let min: Double?
    public let max: Double?

    public init(min: Double? = nil, max: Double? = nil) {
        self.min = min
        self.max = max
    }
}

/// A vector query for approximate nearest neighbor search.
public struct VectorQuery: Sendable {
    public let vector: [Double]
    public let k: Int  // number of neighbors

    public init(vector: [Double], k: Int) {
        self.vector = vector
        self.k = k
    }
}
