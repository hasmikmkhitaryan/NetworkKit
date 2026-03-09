//
//  DefaultNetworkClient.swift
//  
//
//  Created by Hasmik Mirzakhanyan on 03/03/2026
//

import Foundation

public final class DefaultNetworkClient: NetworkClient {
    private let http: HTTPClient
    private let builder: RequestBuilder
    private let middlewares: [Middleware]
    private let retry: RetryMiddleware?

    public init(http: HTTPClient,
                builder: RequestBuilder,
                middlewares: [Middleware] = []) {
        self.http = http
        self.builder = builder
        self.middlewares = middlewares
        self.retry = middlewares.compactMap { $0 as? RetryMiddleware }.first
    }

    public func send<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        var request = try builder.makeRequest(endpoint)
        for mw in middlewares {
            request = try await mw.prepare(request, requiresAuth: endpoint.requiresAuth)
        }

        var attempt = 0
        while true {
            do {
                let (data, respAny) = try await http.send(request)
                guard let resp = respAny as? HTTPURLResponse else {
                    throw NetworkError.server(status: -1, data: nil)
                }
                if (200..<300).contains(resp.statusCode) {
                    do {
                        // Handle empty responses (204 No Content, etc.)
                        if data.isEmpty || E.Response.self == EmptyResponse.self {
                            let value = EmptyResponse() as! E.Response
                            await notify(result: .success((data, resp)), request: request)
                            return value
                        }
                        
                        let decoder = endpoint.decoder ?? JSONCoder.decoder
                        let value = try decoder.decode(E.Response.self, from: data)
                        await notify(result: .success((data, resp)), request: request)
                        return value
                    } catch {
                        let err = NetworkError.decode(error, data: data)
                        await notify(result: .failure(err), request: request)
                        throw err
                    }
                } else {
                    let err = NetworkError.server(status: resp.statusCode, data: data)
                    await notify(result: .failure(err), request: request)
                    if let retry = retry {
                        let advice = await retry.retryAdvice(response: resp, error: err, request: request, attempt: attempt)
                        if advice.shouldRetry {
                            attempt += 1; await retry.sleep(attempt: attempt); request = advice.newRequest ?? request; continue
                        }
                    }
                    throw err
                }
            } catch let err as NetworkError {
                await notify(result: .failure(err), request: request)
                if let retry = retry {
                    let advice = await retry.retryAdvice(response: nil, error: err, request: request, attempt: attempt)
                    if advice.shouldRetry {
                        attempt += 1; await retry.sleep(attempt: attempt); request = advice.newRequest ?? request; continue
                    }
                }
                throw err
            } catch {
                let e = NetworkError.unknown(error)
                await notify(result: .failure(e), request: request)
                throw e
            }
        }
    }

    public func sendRaw(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, resp) = try await http.send(request)
        guard let httpResp = resp as? HTTPURLResponse else {
            throw NetworkError.server(status: -1, data: nil)
        }
        return (data, httpResp)
    }

    private func notify(result: Result<(Data, HTTPURLResponse), NetworkError>, request: URLRequest) async {
        await withTaskGroup(of: Void.self) { g in
            for mw in middlewares {
                g.addTask { await mw.didReceive(result, for: request) }
            }
        }
    }
}
