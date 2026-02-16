//
//  ClaudeService.swift
//  danreps
//
//  Created by Claude Code
//

import Foundation

class ClaudeService {
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let apiVersion = "2023-06-01"
    private static var cache: [String: String] = [:]


    func prompt(_ prompt: String, systemMessage: String? = nil,
                model: String? = nil, maxTokens: Int? = nil) async throws -> String {
        let actualModel = model ?? "claude-sonnet-4-5"
        let actualMaxTokens = maxTokens ?? 1024

        // Check cache first (include model in key)
        let cacheKey = "\(actualModel):\(prompt)"
        if let cachedResponse = Self.cache[cacheKey] {
            print("DEBUG: Returning cached response for prompt")
            return cachedResponse
        }

        guard let apiKey = KeychainService.shared.getAPIKey() else {
            throw ClaudeError.noAPIKey
        }

        // Prepare the request body
        var requestBody: [String: Any] = [
            "model": actualModel,
            "max_tokens": actualMaxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        if let system = systemMessage {
            requestBody["system"] = system
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw ClaudeError.invalidRequest
        }

        // Create the request
        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = jsonData

        print("DEBUG: Sending request to Anthropic API (\(actualModel))...")

        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        print("DEBUG: Got response with status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("DEBUG: Error response: \(errorString)")
            }
            throw ClaudeError.httpError(statusCode: httpResponse.statusCode)
        }

        // Parse the response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ClaudeError.invalidResponse
        }

        print("DEBUG: Successfully got response from Claude (\(actualModel))")

        // Cache the response before returning
        Self.cache[cacheKey] = text

        return text
    }
}

enum ClaudeError: Error, LocalizedError {
    case noAPIKey
    case invalidRequest
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key found. Please set your API key in settings."
        case .invalidRequest:
            return "Failed to create request"
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        }
    }
}
