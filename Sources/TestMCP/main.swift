import Foundation
import MCP
import _Concurrency

var testServer: Server?

_Concurrency.Task {
    testServer = Server(
        name: "test-mcp",
        version: "1.0.0",
        capabilities: .init(tools: .init(listChanged: true))
    )

    await testServer!.withMethodHandler(ListTools.self) { _ in
        let tool = Tool(
            name: "hello",
            description: "Say hello",
            inputSchema: .object([
                "type": "object",
                "properties": .object([:]),
                "additionalProperties": false
            ])
        )
        return .init(tools: [tool])
    }

    await testServer!.withMethodHandler(CallTool.self) { params in
        if params.name == "hello" {
            return .init(content: [.text("Hello from MCP!")])
        }
        return .init(content: [.text("Unknown tool")], isError: true)
    }

    let transport = StdioTransport()
    try await testServer!.start(transport: transport)
}

RunLoop.main.run()
