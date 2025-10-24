<div align="center">
  <br/>
  <br/>
  <img width="360" src="docs/images/logo.svg" alt="RedisOM" />
  <br/>
  <br/>
</div>

<p align="center">
    <p align="center">
        Object mapping, and more, for Redis and Swift
    </p>
</p>

---

![Swift Version][ver-svg]
[![License][license-image]][license-url]
[![Build Status][ci-svg]][ci-url]

## Overview
`RedisOM Swift` is a high-level Redis client and object mapper for Swift inspired by `redis-om-python` and the other official RedisOM libraries published under the Redis org. It provides a typed, declarative way to model, persist, and query JSON documents in Redis using Swift's key paths and macros.

`RedisOM Swift` combines RedisJSON, RediSearch, and connection pooling into a unified API that feels native to Swift. It integrates with both Vapor's app lifecycle and the Swift Service Lifecycle framwork, making it ideal for server applications, background workers, or distributed systems.

**Key Features**
* Declarative Models - Define models using the @Model macro and store them as queryable RedisJSON documnts.
* Full-text and numeric search - Query your data using a fluent, type-safe biulder powered by RediSearch.
* Lifecycle Integration - Works out of the box with Vapor and Service Lifecycle.
* Automatic Index Migration - `RedisOM Swift` automatically creates and updates RediSearch indexes

## Installation
You can add `RedisOM Swift` to your project using Swift Package Manager.

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/eric-musliner/redis-om-swift.git", from: "0.1.0")
]
...

targets : [
    .product(name:"RedisOM", package: "redis-om-swift")
]
```

This ensures that the Redis connections and index migrations are automatically started and stopped as part of your service lifecycle

## Modeling Your Data
Define your data models by implementing the `JsonModel` protocol

Use the the `@Id` Property wrapper to define the id field and auto assign an UUID on save to the model records.


```swift
struct User: JsonModel {
    @Id var id: String?
    var name: String
    var email: String
    var aliases: [String]?
    var age: Int?
    var createdAt: Date?

    static let keyPrefix: String = "user"
}
```

You can then persist, retrieve, update, or delete models like:

```swift
var user = User(name: "Alice", email: "alice@example.com")
try await user.save()

var user2 = User(name: "Alice", email: "alice@example.com", age: 45)
try await user2.save()

// Retrieve model from Redis by id
let user = try await User.get(id: user.id!)
try await user.delete()

// Make updates to model
user.name = "Alicia"
user.save()

// Delete by id
try await User.delete(id: user2.id!)

// Get all keys in Redis for a given model
try await User.allKeys()
```

## Indexing and Migration
Model fields are automatically "Indexed" using the `@Index` Property wrapper on your model fields. `@Index` supports passing a type parameter to specify what type the index is in Redis for your field: eg. (`.text`, `.tag`, `.numeric`). The default type is `.tag`

```swift
@Index 
var address: [Address]?

@Index(type: .text)
var description: String?

@Index(type: .numeric)
var weight: Int
```
When a model is registered, `RedisOM Swift` automatically builds and synchronizes its schema with Redis.

```swift
redis.register(User.self)
```

If you change your model fields or index configuration, the migrator updates the RediSearch index definitions automatically on next startup.

You can also manually run migrations:

```swift
let migrator = try Migrator(client: redis.poolService)
try await migrator.migrate(models: [User.self])
```

## Rich Queries and Embedded Models
RedisOM supports rich, type-safe queries via RediSearch, allowing you to filter, sort, and combine complex predicates with a Fluent-style API.

To make your models searchable, simply annotate them with the `@Model` macro.
This macro generates the necessary schema metadata for RediSearch, enabling `RedisOM Swift` to:

* Register the model automatically with the `RedisOM Swift` instance.
* Create and migrate RediSearch indexes.
* Support type-safe and chainable query builders.

### Querying Flat Models

Here's a basic example of a searchable model:
```swift
@Model
struct User: JsonModel {
    @Id var id: String?
    @Index(type: .text) var name: String
    @Index var email: String
    @Index var aliases: [String]?
    @Index(type: .numeric) var age: Int?

    static let keyPrefix: String = "user"
}
```

Perform queries using a fluent API:

```swift
let users: [User] = try await User.find().where(\.$name == "Alice").all()
```

Chain multiple predicates together:

```swift
let users: [User] = try await User
    .find()
    .where(\.$name == "Alice")
    .or(\.$name == "Sandra")
    .and(\.$age == 33)
    .all()
```

You can also use range operators, in, and between

```swift
@Model
struct Item: JsonModel {
    @Id var id: String?
    @Index(type: .numeric) var price: Double
    @Index var name: String

    static let keyPrefix: String = "item"
}

let items: [Item] = try await Item
    .find()
    .where(\.$price <= 65.99)
    .and(\.$price > 10)
    .all()

// Between
let users: [User] = try await User
    .find()
    .where(\.$age...(34, 60))
    .and(\.$name == "Bill")
    .all()

// In
let items: [Item] = try await Item.find()
    .where(\.$price ~= [24.99, 50.99])
    .all()

```

### Negation
You can invert any query predicate using the .not() modifier at the end of a query chain.
This tells `RedisOM Swift` to negate the preceding condition or group of conditions.

For example:

```swift
let users: [User] = try await User
    .find()
    .where(\.$name == "Alice")
    .not()
    .all()
```

This generates a RediSearch query equivalent to:
```
-(@name:Alice)
```

You can also chain .not() with other predicates to express complex filters:
```swift
let users: [User] = try await User
    .find()
    .where(\.$age >= 18)
    .and(\.$email == "alice@example.com")
    .not()
    .all()
```
This translates to
```
-((@age:[18 inf] @email:alice@example.com))
```

### Embedded and Nested Models
`RedisOM Swift` allows you to embed nested models within your root model, while still making their fields searchable using the same key-path syntax

For example

```swift
@Model
struct Address: JsonModel {
    @Id var id: String?
    @Index var city: String
    @Index var state: String
    @Index var zip: String
}

@Model
struct Person: JsonModel {
    @Id var id: String?
    @Index var name: String
    @Index var address: Address
}
```
Under the hood, `RedisOM Swift` automatically flattens the nested schema so that RediSearch can index it with fully qualified field names (e.g. address__city, address__state).

You can then query nested fields directly using key paths:

```swift
let people = try await Person
    .find()
    .where(\.$address.city == "Boston")
    .and(\.$address.state == "MA")
    .all()
```

Even nested collections are supported:

```swift
@Model
struct Bike: JsonModel {
    @Id var id: String?
    @Index var model: String
    @Index var brand: String
    @Index(type: .numeric) var price: Int
    @Index var type: String
    @Index var specs: [Spec]
    @Index(type: .text) var description: String?
    var addons: [String]?
    @Index var helmetIncluded: Bool
    var createdAt: Date?

    static let keyPrefix: String = "bike"
}

@Model
struct Spec: JsonModel {
    var id: String?
    @Index var manufacturer: String
    @Index var material: String
    @Index(type: .numeric) var weight: Int

    static let keyPrefix: String = "spec"
}
```

You can query deeply into arrays of embedded models:

```swift
let bikes = try await Bike
    .find()
    .where(\.$specs[\.$manufacturer] == "Giant")
    .all()

let bikes = try await Bike
    .find()
    .where(\.$specs[\.$weight]...(40, 60))
    .and(\.$specs[\.$material] == "carbon fiber")
    .all()
```

### Combining Nested Predicates
You can freely mix predicates across nested and root fields:

```swift
let results = try await Person
    .find()
    .where(\.$name == "Alice")
    .and(\.$address.city == "Cambridge")
    .or(\.$address.state == "MA")
    .all()
```
Internally, `RedisOM Swift` automatically generates a valid RediSearch query such as:

```
(@name:Alice @address__city:Cambridge) | (@address__state:MA)
```

### Limit, First, & Exist

You can also control the number of results, get only the first, or simply check if a record exists

```swift
let items = try await Item
    .find()
    .where(\.$price...(24.00, 70.0))
    .limit(0..<2)
    .all()

let result: Item? = try await Item
    .find()
    .where(\.$price...(24.00, 70.0))
    .first()

let exists = try await Item.find()
    .where(\.$price <= 65.99)
    .exists()
```

## Why It Matters

Traditional Redis clients treat Redis as a key-value store.
`RedisOM Swift` turns it into a typed, searchable document store, allowing you to:

 * Model data like you would in an ORM.
 * Query using Swift key paths instead of strings.
 * Combine nested model fields in a type-safe way.
 * Let Redis handle full-text search and indexing behind the scenes.

## Configuration
By default `RedisOM Swift` will connect to a Redis instance using the environment variable `REDIS_URL`.

```
export REDIS_URL=redis://localhost:6379
```

You can also pass the URL directly:

```swift
let redis = try RedisOM(url: "redis://localhost:6379")
```

or for secure connections:
```swift
let redis = try RedisOM(
    url: "rediss://:mySecretPassword@redis.example.com:6379"
)
```

You can also customize the logger and retry policy:
```swift
let redis = try RedisOM(
    url: "redis://localhost:6379",
    retryPolicy: .limited(3),
    logger: Logger(label: "redis.om")
)
```

### Advanced Configuration

For more granular control — such as setting custom authentication, selecting a database, or enabling TLS manually — you can construct a full RedisConfiguration object and pass it directly.

Pragmatic Configuration:

```swift
var config = try RedisConfiguration(hostname: "redis.prod.internal", port: 6380)
config.password = "prodSecret"
config.tlsConfiguration = .forClient()

let logger = Logger(label: "redis.om.prod")

let redis = try RedisOM(
    config: config,
    logger: logger,
    retryPolicy: .infinite
)
```

This is ideal when your app runs in environments that require explicit control over:

* Authentication credentials
* Database selection
* TLS certificates / client auth
* Socket options or timeouts

## Usage with Vapor App Lifecycle

When used in a Vapor app, `RedisOM Swift` can participate in the lifecycle and automatically migrate your search indexes during startup

```swift
public func configure(_ app: Application) throws {
    let redis = try RedisOM(url: "redis://localhost:6379")

    # Register models for automatic indexing
    redis.register(User.self)

    app.lifecycle.use(redis)
}
```
When the application boots, `RedisOM Swift` will automatically
1. Establish a connection pool to Redis
2. Create or re-create RediSearch indexes for all registered models
3. Cleanly shut down connections on app termination

## Usage with Swift Service Lifecycle

If you're building a service using Swift Service Lifecycle, `RedisOM Swift` can run as a managed service

```swift
import RedisOM
import ServiceLifecycle

@main
struct App {
    static func main() async throws {
        let redis = try RedisOM()
        redis.register(User.self)

        // Run as part of the Swift Service Lifecycle
        let group = ServiceGroup(services: [redis])
        try await group.run()
    }
}
```
This ensures that the Redis connections and index migrations are automatically started and stopped as part of your service lifecycle

## Logging

`RedisOM Swift` integrates with Swift's `swift-log` system. You can inject a custom Logger to control verbosity:

```swift
var logger = Logger(label: "redis.om.debug")
logger.logLevel = .debug

let redis = try RedisOM(logger: logger)
```

## License

redis-om-swift is available under the MIT License. See LICENSE for details.

<!-- Badges -->
[license-image]: https://img.shields.io/badge/license-mit-green.svg?style=flat-square
[license-url]: LICENSE
[ci-svg]: https://github.com/eric-musliner/redis-om-swift/actions/workflows/ci.yml/badge.svg
[ci-url]: https://github.com/eric-musliner/redis-om-swift/actions/workflows/ci.yml
[ver-svg]: https://img.shields.io/badge/swift-6.2%20%2F%206.1-brightgreen.svg
