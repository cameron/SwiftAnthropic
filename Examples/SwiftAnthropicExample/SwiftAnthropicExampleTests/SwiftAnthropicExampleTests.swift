//
//  SwiftAnthropicExampleTests.swift
//  SwiftAnthropicExampleTests
//
//  Created by James Rochabrun on 2/24/24.
//

import XCTest
@testable import SwiftAnthropicExample
import SwiftAnthropic

final class SwiftAnthropicExampleTests: XCTestCase {
    private var service : AnthropicService = AnthropicServiceFactory.service(apiKey: "TODO")

    func testSimpleFunctionCall() async throws {
        // TODO this belongs in the package's test target, but i haven't been able to figure out
        // how to get xcode to actually run that target from this (example) project
        
        let tools = [MessageParameter.ToolDefinition(
            name: "get_weather",
            description: "gets the weather for a given location",
            parameters: JSONSchema(type: .object,
                                   properties: ["location": JSONSchema.Property(type: .string, description: "The city and state, e.g., Portland, OR")]))
            ]

        struct GetWeather: Decodable {
            let location: String
        }
        
        let msg = MessageParameter(model: .claude3Opus,
                                   messages: [MessageParameter.Message(role: .user, content: .text("What is the weather like in New York City?"))],
                                   maxTokens: 4096,
                                   tools: tools,
                                   temperature: 0.01)
        
        let response = try await service.createMessage(msg)
        XCTAssertEqual(response.content.count, 2)

        guard let data = response.content[1].input else {
            return XCTFail("missing function argments")
        }
        print("-------- \(try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any])")

        let gotWeather = try JSONDecoder().decode(GetWeather.self, from: data)
        XCTAssertEqual(gotWeather.location, "New York City")

    }
}
