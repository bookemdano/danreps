import Foundation

class ApiService {
    static let shared = ApiService()

    private static let prodURL = "https://danreps.vercel.app"
    private static let baseURLKey = "ApiBaseURL"

    func read(userId: String) async throws -> String {
        let url = URL(string: "\(ApiService.prodURL)/api/data?userId=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userId, forHTTPHeaderField: "X-API-Key")

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode != 200 {
            throw ApiError.httpError(statusCode: httpResponse.statusCode)
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func write(userId: String, json: String) async throws {
        let url = URL(string: "\(ApiService.prodURL)/api/data?userId=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(userId, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = json.data(using: .utf8)

        let (_, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        if httpResponse.statusCode != 200 {
            throw ApiError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    enum ApiError: Error, LocalizedError {
        case httpError(statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .httpError(let statusCode):
                return "API request failed with status \(statusCode)"
            }
        }
    }
}
