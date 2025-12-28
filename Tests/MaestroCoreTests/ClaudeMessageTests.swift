import XCTest
@testable import MaestroCore

/// Claude Message JSONL Parsing Tests
/// Tests parsing of Claude Code session JSONL files
final class ClaudeMessageTests: XCTestCase {

    // MARK: - User Message Parsing

    func testParseUserMessage() throws {
        let json = """
        {"type":"user","sessionId":"00024b3d-10f7-42ad-8226-4d3cc8a2ce2d","uuid":"77c1bce4-9ba5-4af4-a457-792886d14bb0","timestamp":"2025-12-03T05:58:05.815Z","cwd":"/Users/test/project","gitBranch":"main","message":{"role":"user","content":"Hello world"}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        guard case .user(let userMsg) = message else {
            XCTFail("Expected user message")
            return
        }

        XCTAssertEqual(userMsg.type, "user")
        XCTAssertEqual(userMsg.sessionId, "00024b3d-10f7-42ad-8226-4d3cc8a2ce2d")
        XCTAssertEqual(userMsg.uuid, "77c1bce4-9ba5-4af4-a457-792886d14bb0")
        XCTAssertEqual(userMsg.cwd, "/Users/test/project")
        XCTAssertEqual(userMsg.gitBranch, "main")
    }

    func testParseUserMessageWithArrayContent() throws {
        let json = """
        {"type":"user","sessionId":"test-session","uuid":"test-uuid","timestamp":"2025-12-03T05:58:05.815Z","cwd":"/test","message":{"role":"user","content":[{"type":"text","text":"Hello"}]}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        guard case .user(let userMsg) = message else {
            XCTFail("Expected user message")
            return
        }

        if case .array(let blocks) = userMsg.message.content {
            XCTAssertEqual(blocks.count, 1)
        } else {
            XCTFail("Expected array content")
        }
    }

    // MARK: - Assistant Message Parsing

    func testParseAssistantMessageWithText() throws {
        let json = """
        {"type":"assistant","sessionId":"test-session","uuid":"test-uuid","timestamp":"2025-12-03T05:58:09.811Z","cwd":"/test","message":{"role":"assistant","model":"claude-opus-4-5-20251101","content":[{"type":"text","text":"Let me help you."}]}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        guard case .assistant(let assistantMsg) = message else {
            XCTFail("Expected assistant message")
            return
        }

        XCTAssertEqual(assistantMsg.type, "assistant")
        XCTAssertEqual(assistantMsg.message.model, "claude-opus-4-5-20251101")
        XCTAssertEqual(assistantMsg.message.content.count, 1)

        if case .text(let textContent) = assistantMsg.message.content[0] {
            XCTAssertEqual(textContent.text, "Let me help you.")
        } else {
            XCTFail("Expected text content")
        }
    }

    func testParseAssistantMessageWithToolUse() throws {
        let json = """
        {"type":"assistant","sessionId":"test-session","uuid":"test-uuid","timestamp":"2025-12-03T05:58:10.850Z","cwd":"/test","message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_019RsoTtpqTdLZMXzMKmbHgx","name":"Grep","input":{"pattern":"test","glob":"*.ts"}}]}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        guard case .assistant(let assistantMsg) = message else {
            XCTFail("Expected assistant message")
            return
        }

        XCTAssertEqual(assistantMsg.message.content.count, 1)

        if case .toolUse(let toolUse) = assistantMsg.message.content[0] {
            XCTAssertEqual(toolUse.name, "Grep")
            XCTAssertEqual(toolUse.id, "toolu_019RsoTtpqTdLZMXzMKmbHgx")
            XCTAssertNotNil(toolUse.input)
        } else {
            XCTFail("Expected tool_use content")
        }
    }

    func testExtractToolCalls() throws {
        let json = """
        {"type":"assistant","sessionId":"test-session","uuid":"test-uuid","timestamp":"2025-12-03T05:58:10.850Z","message":{"role":"assistant","content":[{"type":"text","text":"Searching..."},{"type":"tool_use","id":"tool1","name":"Grep","input":{}},{"type":"tool_use","id":"tool2","name":"Read","input":{}}]}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        let toolCalls = message!.toolCalls
        XCTAssertEqual(toolCalls.count, 2)
        XCTAssertEqual(toolCalls[0].name, "Grep")
        XCTAssertEqual(toolCalls[1].name, "Read")
    }

    // MARK: - Session Info Extraction

    func testExtractSessionInfo() throws {
        let json = """
        {"type":"user","sessionId":"session-123","uuid":"uuid-456","timestamp":"2025-12-03T05:58:05.815Z","cwd":"/project/path","gitBranch":"feature-branch","message":{"role":"user","content":"test"}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        let sessionInfo = message!.sessionInfo
        XCTAssertNotNil(sessionInfo)
        XCTAssertEqual(sessionInfo?.sessionId, "session-123")
        XCTAssertEqual(sessionInfo?.cwd, "/project/path")
        XCTAssertEqual(sessionInfo?.gitBranch, "feature-branch")
        XCTAssertEqual(sessionInfo?.timestamp, "2025-12-03T05:58:05.815Z")
    }

    func testSessionInfoNilForSummary() throws {
        let json = """
        {"type":"summary","summary":"Test summary","leafUuid":"leaf-123"}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        let sessionInfo = message!.sessionInfo
        XCTAssertNil(sessionInfo)
    }

    // MARK: - Other Message Types

    func testParseSummaryMessage() throws {
        let json = """
        {"type":"summary","summary":"Implemented feature X","leafUuid":"7d65d559-be7a-4ccb-b91d-68678c1ccc4a"}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        guard case .summary(let summaryMsg) = message else {
            XCTFail("Expected summary message")
            return
        }

        XCTAssertEqual(summaryMsg.summary, "Implemented feature X")
        XCTAssertEqual(summaryMsg.leafUuid, "7d65d559-be7a-4ccb-b91d-68678c1ccc4a")
    }

    func testParseFileHistorySnapshot() throws {
        let json = """
        {"type":"file-history-snapshot","messageId":"77c1bce4-9ba5-4af4-a457-792886d14bb0","isSnapshotUpdate":false}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        guard case .fileHistorySnapshot(let snapshot) = message else {
            XCTFail("Expected file-history-snapshot message")
            return
        }

        XCTAssertEqual(snapshot.messageId, "77c1bce4-9ba5-4af4-a457-792886d14bb0")
        XCTAssertEqual(snapshot.isSnapshotUpdate, false)
    }

    func testParseQueueOperation() throws {
        let json = """
        {"type":"queue-operation","operation":"enqueue","timestamp":"2025-12-01T16:23:20.258Z","sessionId":"027fe62e-f654-451e-8632-8b484bfe42fb"}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        guard case .queueOperation(let queueOp) = message else {
            XCTFail("Expected queue-operation message")
            return
        }

        XCTAssertEqual(queueOp.operation, "enqueue")
        XCTAssertEqual(queueOp.sessionId, "027fe62e-f654-451e-8632-8b484bfe42fb")
    }

    func testParseUnknownType() throws {
        let json = """
        {"type":"future-type","data":"some data"}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        guard case .unknown(let type) = message else {
            XCTFail("Expected unknown message")
            return
        }

        XCTAssertEqual(type, "future-type")
    }

    // MARK: - Error Handling

    func testParseMalformedJSON() throws {
        let malformed = "{not valid json"
        let message = ClaudeJSONLParser.parseLine(malformed)
        XCTAssertNil(message)
    }

    func testParseEmptyLine() throws {
        let message = ClaudeJSONLParser.parseLine("")
        XCTAssertNil(message)
    }

    func testParseWhitespaceLine() throws {
        let message = ClaudeJSONLParser.parseLine("   \n\t  ")
        XCTAssertNil(message)
    }

    // MARK: - Multiple Lines

    func testParseMultipleLines() throws {
        let content = """
        {"type":"user","sessionId":"s1","uuid":"u1","timestamp":"2025-01-01T00:00:00Z","message":{"role":"user","content":"Hello"}}
        {"type":"summary","summary":"Test"}

        {"type":"assistant","sessionId":"s1","uuid":"u2","timestamp":"2025-01-01T00:00:01Z","message":{"role":"assistant","content":[{"type":"text","text":"Hi"}]}}
        {invalid json}
        """

        let messages = ClaudeJSONLParser.parseLines(content)

        // Should parse 3 valid messages (user, summary, assistant)
        // Skips empty line and malformed JSON
        XCTAssertEqual(messages.count, 3)

        guard case .user = messages[0] else {
            XCTFail("First should be user")
            return
        }

        guard case .summary = messages[1] else {
            XCTFail("Second should be summary")
            return
        }

        guard case .assistant = messages[2] else {
            XCTFail("Third should be assistant")
            return
        }
    }

    // MARK: - Tool Call Edge Cases

    func testToolCallWithNoInput() throws {
        let json = """
        {"type":"assistant","sessionId":"s1","uuid":"u1","timestamp":"2025-01-01T00:00:00Z","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"BashOutput"}]}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        let toolCalls = message!.toolCalls
        XCTAssertEqual(toolCalls.count, 1)
        XCTAssertEqual(toolCalls[0].name, "BashOutput")
        XCTAssertNil(toolCalls[0].input)
    }

    func testToolCallWithComplexInput() throws {
        let json = """
        {"type":"assistant","sessionId":"s1","uuid":"u1","timestamp":"2025-01-01T00:00:00Z","message":{"role":"assistant","content":[{"type":"tool_use","id":"t1","name":"Edit","input":{"file_path":"/test.txt","old_string":"foo","new_string":"bar","replace_all":true}}]}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)

        let toolCalls = message!.toolCalls
        XCTAssertEqual(toolCalls.count, 1)
        XCTAssertNotNil(toolCalls[0].input)
    }

    // MARK: - User Message Returns No Tool Calls

    func testUserMessageHasNoToolCalls() throws {
        let json = """
        {"type":"user","sessionId":"s1","uuid":"u1","timestamp":"2025-01-01T00:00:00Z","message":{"role":"user","content":"test"}}
        """

        let message = ClaudeJSONLParser.parseLine(json)
        XCTAssertNotNil(message)
        XCTAssertEqual(message!.toolCalls.count, 0)
    }
}
