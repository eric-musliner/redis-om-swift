import Foundation
import NIOCore
import RediStack

///
public protocol RedisModel: Codable, Sendable {
    associatedtype IDType: LosslessStringConvertible & Hashable & Sendable

    var id: IDType? { get set }
    static var keyPrefix: String { get }

    mutating func save(using client: RedisClient) async throws
    static func get(id: IDType, using client: RedisClient) async throws
        -> EventLoopFuture<Self?>
    func delete(using client: RedisClient) async throws
}

extension RedisModel {
    public var redisKey: String {
        "\(Self.keyPrefix):\(id ?? UUID().uuidString as! IDType)"
    }
}

public protocol JsonModel: RedisModel {}

extension JsonModel {

    /// Save model to Redis
    ///
    public mutating func save(using client: RedisClient) async throws {
        let newId: IDType = id ?? UUID().uuidString as! IDType
        self.id = newId

        let data = try JSONEncoder().encode(self)

        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw RedisError.init(
                reason: "Unable to serialize data to JSON object."
            )
        }

        let _ = client.send(
            command: "JSON.SET",
            with: [
                .bulkString(ByteBuffer(string: redisKey)),
                .bulkString(ByteBuffer(string: "$")),
                .bulkString(ByteBuffer(string: jsonString)),
            ],
        )
    }

    ///
    public static func get(id: IDType, using client: RedisClient) async throws
        -> EventLoopFuture<Self?>
    {
        let key = "\(keyPrefix):\(id)"

        return client.send(
            command: "JSON.GET",
            with: [.bulkString(ByteBuffer(string: key))]
        ).flatMapThrowing { response in
            guard let string = response.string else {
                return nil
            }
            guard let data = string.data(using: .utf8) else {
                throw RedisError.init(
                    reason: "Unable to deserialize JSON string."
                )
            }
            return try JSONDecoder().decode(Self.self, from: data)
        }

    }

    ///
    public func delete(using client: RedisClient) async throws {
        let _ = client.send(
            command: "DEL",
            with: [.bulkString(ByteBuffer(string: redisKey))]
        )
    }

    ///
    ///
    public static func delete(pk: String, using client: RedisClient)
        async throws
    {

    }

}
