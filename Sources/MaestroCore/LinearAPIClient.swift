import Foundation

/// Linear GraphQL API Client
/// Handles authentication and API calls to Linear
public class LinearAPIClient {

    private let apiKey: String
    private let endpoint = "https://api.linear.app/graphql"

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - GraphQL Queries

    /// Fetch issues assigned to the authenticated user
    public func fetchMyIssues() async throws -> [LinearIssue] {
        let query = """
        query {
            viewer {
                assignedIssues(first: 100) {
                    nodes {
                        id
                        identifier
                        title
                        description
                        priority
                        state {
                            id
                            name
                            type
                        }
                        team {
                            id
                            name
                        }
                        createdAt
                        updatedAt
                        dueDate
                    }
                }
            }
        }
        """

        let response: LinearResponse<ViewerResponse> = try await executeQuery(query)
        return response.data.viewer.assignedIssues.nodes
    }

    /// Fetch a specific issue by ID
    public func fetchIssue(id: String) async throws -> LinearIssue {
        let query = """
        query {
            issue(id: "\(id)") {
                id
                identifier
                title
                description
                priority
                state {
                    id
                    name
                    type
                }
                team {
                    id
                    name
                }
                createdAt
                updatedAt
                dueDate
            }
        }
        """

        let response: LinearResponse<IssueResponse> = try await executeQuery(query)
        return response.data.issue
    }

    /// Create a new issue in Linear
    public func createIssue(
        teamId: String,
        title: String,
        description: String?,
        priority: Int? = nil,
        stateId: String? = nil
    ) async throws -> LinearIssue {
        var input: [String: Any] = [
            "teamId": teamId,
            "title": title
        ]

        if let description = description {
            input["description"] = description
        }
        if let priority = priority {
            input["priority"] = priority
        }
        if let stateId = stateId {
            input["stateId"] = stateId
        }

        let inputJSON = try JSONSerialization.data(withJSONObject: input)
        let inputString = String(data: inputJSON, encoding: .utf8)!

        let mutation = """
        mutation {
            issueCreate(input: \(inputString)) {
                success
                issue {
                    id
                    identifier
                    title
                    description
                    priority
                    state {
                        id
                        name
                        type
                    }
                    team {
                        id
                        name
                    }
                    createdAt
                    updatedAt
                    dueDate
                }
            }
        }
        """

        let response: LinearResponse<CreateIssueResponse> = try await executeQuery(mutation)
        guard response.data.issueCreate.success else {
            throw LinearAPIError.createFailed
        }
        return response.data.issueCreate.issue
    }

    /// Update an issue in Linear
    public func updateIssue(
        id: String,
        title: String? = nil,
        description: String? = nil,
        stateId: String? = nil,
        priority: Int? = nil
    ) async throws -> LinearIssue {
        var input: [String: Any] = ["id": id]

        if let title = title { input["title"] = title }
        if let description = description { input["description"] = description }
        if let stateId = stateId { input["stateId"] = stateId }
        if let priority = priority { input["priority"] = priority }

        let inputJSON = try JSONSerialization.data(withJSONObject: input)
        let inputString = String(data: inputJSON, encoding: .utf8)!

        let mutation = """
        mutation {
            issueUpdate(input: \(inputString)) {
                success
                issue {
                    id
                    identifier
                    title
                    description
                    priority
                    state {
                        id
                        name
                        type
                    }
                    team {
                        id
                        name
                    }
                    createdAt
                    updatedAt
                    dueDate
                }
            }
        }
        """

        let response: LinearResponse<UpdateIssueResponse> = try await executeQuery(mutation)
        guard response.data.issueUpdate.success else {
            throw LinearAPIError.updateFailed
        }
        return response.data.issueUpdate.issue
    }

    /// Fetch all workflow states for a team
    public func fetchWorkflowStates(teamId: String) async throws -> [LinearWorkflowState] {
        let query = """
        query {
            team(id: "\(teamId)") {
                states {
                    nodes {
                        id
                        name
                        type
                        position
                    }
                }
            }
        }
        """

        let response: LinearResponse<TeamStatesResponse> = try await executeQuery(query)
        return response.data.team.states.nodes
    }

    // MARK: - GraphQL Execution

    private func executeQuery<T: Decodable>(_ query: String) async throws -> T {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["query": query]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LinearAPIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw LinearAPIError.httpError(httpResponse.statusCode)
        }

        // Check for GraphQL errors
        if let errorResponse = try? JSONDecoder().decode(LinearErrorResponse.self, from: data) {
            if let error = errorResponse.errors.first {
                throw LinearAPIError.graphQLError(error.message)
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - Models

public struct LinearIssue: Codable {
    public let id: String
    public let identifier: String
    public let title: String
    public let description: String?
    public let priority: Int?
    public let state: LinearWorkflowState
    public let team: LinearTeam
    public let createdAt: Date
    public let updatedAt: Date
    public let dueDate: Date?
}

public struct LinearWorkflowState: Codable {
    public let id: String
    public let name: String
    public let type: String
    public let position: Double?
}

public struct LinearTeam: Codable {
    public let id: String
    public let name: String
}

// MARK: - Response Types

private struct LinearResponse<T: Decodable>: Decodable {
    let data: T
}

private struct ViewerResponse: Decodable {
    let viewer: Viewer

    struct Viewer: Decodable {
        let assignedIssues: IssueConnection
    }
}

private struct IssueResponse: Decodable {
    let issue: LinearIssue
}

private struct CreateIssueResponse: Decodable {
    let issueCreate: IssuePayload

    struct IssuePayload: Decodable {
        let success: Bool
        let issue: LinearIssue
    }
}

private struct UpdateIssueResponse: Decodable {
    let issueUpdate: IssuePayload

    struct IssuePayload: Decodable {
        let success: Bool
        let issue: LinearIssue
    }
}

private struct TeamStatesResponse: Decodable {
    let team: Team

    struct Team: Decodable {
        let states: StateConnection
    }
}

private struct IssueConnection: Decodable {
    let nodes: [LinearIssue]
}

private struct StateConnection: Decodable {
    let nodes: [LinearWorkflowState]
}

private struct LinearErrorResponse: Decodable {
    let errors: [LinearError]

    struct LinearError: Decodable {
        let message: String
    }
}

// MARK: - Errors

public enum LinearAPIError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case graphQLError(String)
    case createFailed
    case updateFailed

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Linear API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .graphQLError(let message):
            return "GraphQL error: \(message)"
        case .createFailed:
            return "Failed to create issue in Linear"
        case .updateFailed:
            return "Failed to update issue in Linear"
        }
    }
}
