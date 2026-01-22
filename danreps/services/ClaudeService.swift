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

    func prompt(_ prompt: String) async throws -> String {
        guard let apiKey = KeychainService.shared.getAPIKey() else {
            throw ClaudeError.noAPIKey
        }

        let fake = false
        if (fake){
            return "# Workout Review: Solid Effort! 💪\n\n## What You Did Well:\n\n**✅ Exercise Selection**: Great compound movements focusing on lower body and core - deadlifts, squats, and unilateral work is a smart combination.\n\n**✅ Volume**: You completed 19 total sets, which is solid for a leg-focused session.\n\n**✅ Consistency**: Good rep ranges (10-12) across most exercises - shows you're working in a hypertrophy/strength endurance zone.\n\n**✅ Core Work**: Including deadbugs at the end is smart for stability and injury prevention.\n\n## Areas for Improvement:\n\n**⚠️ Workout Order**: Your timestamps show you did exercises out of the listed order. Typically, you'd want to do:\n1. Deadlifts first (heaviest compound) ✓ \n2. Goblet squats next... but you did them BEFORE deadlifts\n- This scattered approach could impact your performance on heavier lifts\n\n**⚠️ Step-Ups Drop-Off**: You went from 50lbs x 10 to 25lbs x 10 - that's a big drop. This suggests either:\n- First set was too heavy\n- Fatigue management issue\n- Consider starting lighter"
        }
        // Prepare the request body
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-5",
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

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

        print("DEBUG: Sending request to Anthropic API...")

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

        print("DEBUG: Successfully got response from Claude")
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
