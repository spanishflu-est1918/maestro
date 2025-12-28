import Foundation

// MARK: - Claude Code JSONL Message Types

/// Represents a single line from a Claude Code JSONL session file
/// Each line is one of several message types
public enum ClaudeMessage: Decodable {
    case user(ClaudeUserMessage)
    case assistant(ClaudeAssistantMessage)
    case summary(ClaudeSummaryMessage)
    case fileHistorySnapshot(ClaudeFileHistorySnapshot)
    case queueOperation(ClaudeQueueOperation)
    case unknown(type: String)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "user":
            self = .user(try ClaudeUserMessage(from: decoder))
        case "assistant":
            self = .assistant(try ClaudeAssistantMessage(from: decoder))
        case "summary":
            self = .summary(try ClaudeSummaryMessage(from: decoder))
        case "file-history-snapshot":
            self = .fileHistorySnapshot(try ClaudeFileHistorySnapshot(from: decoder))
        case "queue-operation":
            self = .queueOperation(try ClaudeQueueOperation(from: decoder))
        default:
            self = .unknown(type: type)
        }
    }

    /// Extract session metadata from any message type
    public var sessionInfo: ClaudeSessionInfo? {
        switch self {
        case .user(let msg):
            return ClaudeSessionInfo(
                sessionId: msg.sessionId,
                cwd: msg.cwd,
                gitBranch: msg.gitBranch,
                timestamp: msg.timestamp
            )
        case .assistant(let msg):
            return ClaudeSessionInfo(
                sessionId: msg.sessionId,
                cwd: msg.cwd,
                gitBranch: msg.gitBranch,
                timestamp: msg.timestamp
            )
        case .summary, .fileHistorySnapshot, .queueOperation, .unknown:
            return nil
        }
    }

    /// Extract tool calls from assistant messages
    public var toolCalls: [ClaudeToolUse] {
        guard case .assistant(let msg) = self else { return [] }
        return msg.message.content.compactMap { content in
            guard case .toolUse(let tool) = content else { return nil }
            return tool
        }
    }
}

// MARK: - Session Info

/// Common session metadata extracted from messages
public struct ClaudeSessionInfo {
    public let sessionId: String
    public let cwd: String?
    public let gitBranch: String?
    public let timestamp: String
}

// MARK: - User Message

public struct ClaudeUserMessage: Decodable {
    public let type: String
    public let sessionId: String
    public let uuid: String
    public let timestamp: String
    public let cwd: String?
    public let gitBranch: String?
    public let message: ClaudeUserContent

    public struct ClaudeUserContent: Decodable {
        public let role: String
        public let content: ClaudeUserContentValue
    }
}

/// User content can be a string or array of content blocks
public enum ClaudeUserContentValue: Decodable {
    case string(String)
    case array([ClaudeContentBlock])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([ClaudeContentBlock].self) {
            self = .array(array)
        } else {
            self = .string("")
        }
    }
}

// MARK: - Assistant Message

public struct ClaudeAssistantMessage: Decodable {
    public let type: String
    public let sessionId: String
    public let uuid: String
    public let timestamp: String
    public let cwd: String?
    public let gitBranch: String?
    public let message: ClaudeAssistantContent

    public struct ClaudeAssistantContent: Decodable {
        public let role: String
        public let content: [ClaudeContentBlock]
        public let model: String?
    }
}

// MARK: - Content Blocks

public enum ClaudeContentBlock: Decodable {
    case text(ClaudeTextContent)
    case toolUse(ClaudeToolUse)
    case unknown(type: String)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            self = .text(try ClaudeTextContent(from: decoder))
        case "tool_use":
            self = .toolUse(try ClaudeToolUse(from: decoder))
        default:
            self = .unknown(type: type)
        }
    }
}

public struct ClaudeTextContent: Decodable {
    public let type: String
    public let text: String
}

public struct ClaudeToolUse: Decodable {
    public let type: String
    public let id: String
    public let name: String
    // input is dynamic JSON, store as raw data
    public let input: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case type, id, name, input
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        input = try container.decodeIfPresent([String: AnyCodable].self, forKey: .input)
    }
}

// MARK: - Other Message Types

public struct ClaudeSummaryMessage: Decodable {
    public let type: String
    public let summary: String
    public let leafUuid: String?
}

public struct ClaudeFileHistorySnapshot: Decodable {
    public let type: String
    public let messageId: String
    public let isSnapshotUpdate: Bool?
}

public struct ClaudeQueueOperation: Decodable {
    public let type: String
    public let operation: String
    public let timestamp: String
    public let sessionId: String
}

// MARK: - AnyCodable Helper

/// Type-erased Codable wrapper for dynamic JSON values
public struct AnyCodable: Decodable {
    public let value: Any

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
}

// MARK: - JSONL Parser

public struct ClaudeJSONLParser {
    /// Parse a single JSONL line into a ClaudeMessage
    /// Returns nil for empty lines or parse failures (graceful degradation)
    public static func parseLine(_ line: String) -> ClaudeMessage? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        guard let data = trimmed.data(using: .utf8) else { return nil }

        do {
            return try JSONDecoder().decode(ClaudeMessage.self, from: data)
        } catch {
            // Graceful degradation: skip malformed lines
            return nil
        }
    }

    /// Parse multiple JSONL lines
    public static func parseLines(_ content: String) -> [ClaudeMessage] {
        return content
            .components(separatedBy: .newlines)
            .compactMap(parseLine)
    }

    /// Parse JSONL data from a file starting at a byte offset
    /// Returns parsed messages and the new offset position
    public static func parseFromOffset(
        fileHandle: FileHandle,
        offset: Int64
    ) -> (messages: [ClaudeMessage], newOffset: Int64) {
        fileHandle.seek(toFileOffset: UInt64(offset))

        guard let data = try? fileHandle.readToEnd(),
              let content = String(data: data, encoding: .utf8) else {
            return ([], offset)
        }

        let messages = parseLines(content)
        let newOffset = offset + Int64(data.count)

        return (messages, newOffset)
    }
}
