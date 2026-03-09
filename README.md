## NetworkKit

NetworkKit is a lightweight, composable Swift networking layer built on top of `URLSession`.  
It provides:

- **Type-safe endpoints**: Each endpoint declares its own `Response` type.
- **Pluggable middleware**: Logging, authentication, retry, ETag revalidation, and custom behaviors.
- **Configurable HTTP client**: A simple `HTTPClient` protocol with a `URLSession`-based implementation.
- **Clear error model**: Strongly typed `NetworkError` values for transport, server, and decoding failures.

It is distributed as a Swift Package and supports **iOS 15+** and **macOS 12+**.

---

## Installation

### Swift Package Manager

In Xcode:

1. Open **Package Dependencies** for your project.
2. Add a new package using the repository URL (for example):  
   `https://github.com/<your-org-or-user>/NetworkKit.git`
3. Select the **NetworkKit** library as a dependency of your app or framework target.

Or in your `Package.swift`:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/<your-org-or-user>/NetworkKit.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "NetworkKit", package: "NetworkKit")
            ]
        )
    ]
)
```

Replace the repository URL and version with the actual values for your setup.

---

## Core Concepts

### Endpoint

Endpoints describe a single request/response pair:

```swift
import NetworkKit
import Foundation

struct GetUser: Endpoint {
    struct UserDTO: Codable, Equatable {
        let id: String
        let name: String
    }

    typealias Response = UserDTO

    let id: String

    var method: HTTPMethod { .GET }
    var path: String { "/users/\(id)" }
    var requiresAuth: Bool { true }
    var cachePolicy: CachePolicy { .revalidate }
}
```

Key properties:

- **`Response`**: Decodable type that represents the successful response.
- **`method`**: The HTTP method (`GET`, `POST`, `DELETE`, etc.).
- **`path`**: Path relative to a base URL.
- **`query`**: Optional query parameters (`[URLQueryItem]`).
- **`headers`**: Request headers (`Headers` wrapper).
- **`body`**: Optional `Data` payload.
- **`requiresAuth`**: Whether auth middleware should attach a token.
- **`cachePolicy`**: How caching should be handled (`.useURLCache`, `.reloadIgnoringCache`, `.revalidate`).
- **`decoder`**: Optional custom `JSONDecoder` for this endpoint.

Default implementations are provided for `query`, `headers`, `body`, `requiresAuth`, `cachePolicy`, and `decoder`, so you only override what you need.

For endpoints that return no body (e.g. HTTP 204), use `EmptyResponse`:

```swift
struct DeletePost: Endpoint {
    typealias Response = EmptyResponse

    let id: String

    var method: HTTPMethod { .DELETE }
    var path: String { "/posts/\(id)" }
    var requiresAuth: Bool { true }
}
```

### NetworkClient

`NetworkClient` is the main abstraction used to send endpoints:

```swift
public protocol NetworkClient {
    func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response
    func sendRaw(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
```

The default implementation provided by the package is `DefaultNetworkClient`, which:

- Uses a `RequestBuilder` and an `HTTPClient` (e.g. `URLSessionHTTPClient`) to perform requests.
- Applies an array of `Middleware` before and after each request.
- Decodes JSON responses into the endpoint’s `Response` type.
- Handles retries via `RetryMiddleware` when configured.

---

## Getting Started

### Creating a Network Client

The package ships with an example wiring helper that shows a typical setup:

```swift
import NetworkKit
import Foundation

final class AppTokenProvider: TokenProvider {
    private(set) var accessToken: String?

    func refreshToken() async throws -> String {
        let new = "newAccessToken"
        accessToken = new
        return new
    }
}

func makeDefaultClient(baseURL: URL) -> DefaultNetworkClient {
    let builder = RequestBuilder(baseURL: baseURL)
    let http = URLSessionHTTPClient()
    let tokenProvider = AppTokenProvider()

    return DefaultNetworkClient(
        http: http,
        builder: builder,
        middlewares: [
            LoggingMiddleware(),
            ETagMiddleware(),
            AuthMiddleware(tokenProvider: tokenProvider),
            RetryMiddleware(policy: .limited(3), tokenProvider: tokenProvider)
        ]
    )
}
```

In your app you would typically keep the `NetworkClient` in a dependency container or environment.

### Sending an Endpoint

```swift
let baseURL = URL(string: "https://api.example.com")!
let client = makeDefaultClient(baseURL: baseURL)

let endpoint = GetUser(id: "123")

do {
    let user = try await client.send(endpoint)
    print("Loaded user:", user)
} catch let error as NetworkError {
    // Handle structured network errors
    print(error.localizedDescription)
} catch {
    // Fallback for unexpected errors
    print("Unexpected error:", error)
}
```

For endpoints that create resources with a JSON body:

```swift
struct CreatePost: Endpoint {
    struct Body: Encodable { let text: String }
    struct PostDTO: Decodable, Equatable { let id: String; let text: String }

    typealias Response = PostDTO

    let payload: Body

    var method: HTTPMethod { .POST }
    var path: String { "/posts" }
    var headers: Headers { ["Content-Type": "application/json"] }
    var body: Data? { try? JSONCoder.encoder.encode(payload) }
    var requiresAuth: Bool { true }
    var cachePolicy: CachePolicy { .reloadIgnoringCache }
}

let create = CreatePost(payload: .init(text: "Hello"))
let post = try await client.send(create)
```

---

## Middleware

Middleware lets you hook into request/response flow:

```swift
public protocol Middleware {
    func prepare(_ request: URLRequest, requiresAuth: Bool) async throws -> URLRequest
    func didReceive(
        _ result: Result<(Data, HTTPURLResponse), NetworkError>,
        for request: URLRequest
    ) async
}
```

Built-in middleware:

- **`LoggingMiddleware`**
  - Uses a `Logger` (default `ConsoleLogger`) to log requests, responses, and errors.
- **`AuthMiddleware`**
  - Reads an access token from a `TokenProvider` and adds a `Bearer` header for endpoints where `requiresAuth == true`.
- **`RetryMiddleware`**
  - Provides retry behavior for transient failures (timeouts, transport errors, 5xx responses).
  - Can optionally refresh tokens on 401 responses by calling `TokenProvider.refreshToken()`.
- **`ETagMiddleware`**
  - Adds `If-None-Match` headers for cached GET requests based on stored ETags.
  - Stores ETags and optionally cached response data via an `ETagCache` actor (`InMemoryETagCache` included).

You can also provide your own middleware by conforming to `Middleware`:

```swift
struct MyCustomMiddleware: Middleware {
    func prepare(_ request: URLRequest, requiresAuth: Bool) async throws -> URLRequest {
        var r = request
        r.setValue("my-value", forHTTPHeaderField: "X-My-Header")
        return r
    }

    func didReceive(
        _ result: Result<(Data, HTTPURLResponse), NetworkError>,
        for request: URLRequest
    ) async {
        // Inspect responses or errors here
    }
}
```

Add your middleware to the `DefaultNetworkClient`:

```swift
let client = DefaultNetworkClient(
    http: URLSessionHTTPClient(),
    builder: RequestBuilder(baseURL: baseURL),
    middlewares: [
        LoggingMiddleware(),
        MyCustomMiddleware()
    ]
)
```

---

## Errors

All high-level failures are represented by `NetworkError`:

- **`.invalidURL`**: Failed to build a valid `URL`.
- **`.transport(URLError)`**: Low-level `URLSession`/network error.
- **`.timeout`**: Request timed out.
- **`.cancelled`**: Request was cancelled.
- **`.server(status:data:)`**: Non-2xx HTTP status, optionally with response body.
- **`.decode(Error, data:)`**: Decoding error when mapping response JSON.
- **`.encode(Error)`**: Error encoding a request body.
- **`.unknown(Error)`**: Any other error type.

`NetworkError` conforms to `CustomNSError` and `LocalizedError`, so you can use:

- `error.localizedDescription` for user-friendly messages.
- `error.failureReason` and `error.recoverySuggestion` for additional context.

---

## Testing

NetworkKit is fully testable thanks to its abstractions:

- Depend on the `NetworkClient` protocol in your code.
- In tests, provide a fake implementation of `NetworkClient` or `HTTPClient`.
- Use the provided test targets (`NetworkKitTests`) as reference for how to unit test endpoints, the client, and middleware.

Example stub client:

```swift
final class StubNetworkClient: NetworkClient {
    var result: Any?

    func send<E>(_ endpoint: E) async throws -> E.Response where E : Endpoint {
        guard let value = result as? E.Response else {
            fatalError("Stub not configured for \(E.Response.self)")
        }
        return value
    }

    func sendRaw(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        fatalError("Not implemented")
    }
}
```

---

## Design Notes

- **Separation of concerns**:
  - `Endpoint` models the API contract.
  - `RequestBuilder` turns endpoints into `URLRequest` values.
  - `HTTPClient` performs the actual network I/O.
  - `Middleware` decorates requests and responses.
- **Async/await first**: APIs are fully asynchronous and Swift-concurrency friendly.
- **Composability**: You can replace or extend nearly every piece (HTTP client, logger, middleware, token provider, ETag cache) to fit your app’s needs.

---

## License

Specify your license here (e.g. MIT, Apache 2.0) and include the corresponding `LICENSE` file in the repository.

