# Networking

A scalable, async/await-first networking layer with middleware (auth, retry, logging), DI-friendly design, and URLSession transport.

## Quick start

```swift
import NetworkKit

let baseURL = URL(string: "https://api.example.com")!
let builder = RequestBuilder(baseURL: baseURL)
let http = URLSessionHTTPClient()
let tokenProvider = AppTokenProvider()

let client = DefaultNetworkClient(
    http: http,
    builder: builder,
    middlewares: [
        LoggingMiddleware(),
        AuthMiddleware(tokenProvider: tokenProvider),
        RetryMiddleware(policy: .limited(3), tokenProvider: tokenProvider)
    ])

let user = try await client.send(GetUser(id: "123"))
print(user.name)
```
