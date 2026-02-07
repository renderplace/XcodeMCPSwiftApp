//
//  ToolCallFeature.swift
//  XcodeMCPSwiftApp
//
//  Created by Anton Gregorn on 7. 2. 26.
//
//  MIT License
//
//  Copyright © 2026 Anton Gregorn. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import ComposableArchitecture
import Foundation
import XcodeMCPBridge

@Reducer
struct ToolCallFeature {
    @ObservableState
    struct State: Equatable {
        var tool: MCPTool
        var parameters: [String: String] = [:]
        var result: BridgeToolResult?
        var isExecuting = false
        var error: String?
        var availableWindows: [XcodeWindowTab] = []

        /// Sorted parameter keys from the tool's input schema
        var parameterKeys: [ParameterInfo] {
            guard let schema = tool.inputSchema,
                  let properties = schema.properties
            else { return [] }

            let requiredSet = Set(schema.required ?? [])
            return properties.keys.sorted().map { key in
                let prop = properties[key]!
                return ParameterInfo(
                    key: key,
                    type: prop.type ?? "string",
                    description: prop.description,
                    isRequired: requiredSet.contains(key),
                    enumValues: prop.enum
                )
            }
        }

        /// The text content of the result, joined
        var resultText: String? {
            guard let result else { return nil }
            let texts = result.content.compactMap(\.text)
            return texts.isEmpty ? nil : texts.joined(separator: "\n")
        }
    }

    struct ParameterInfo: Equatable, Identifiable {
        var id: String { key }
        let key: String
        let type: String
        let description: String?
        let isRequired: Bool
        let enumValues: [String]?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case parameterChanged(key: String, value: String)
        case executeTapped
        case resultReceived(Result<BridgeToolResult, Error>)
        case clearResult
    }

    @Dependency(\.mcpBridgeClient) var mcpBridge

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .parameterChanged(let key, let value):
                state.parameters[key] = value
                return .none

            case .executeTapped:
                state.isExecuting = true
                state.error = nil
                state.result = nil
                let toolName = state.tool.name
                // Filter out empty parameters
                let args = state.parameters.filter { !$0.value.isEmpty }
                return .run { send in
                    do {
                        let result = try await mcpBridge.callTool(toolName, args)
                        await send(.resultReceived(.success(result)))
                    } catch {
                        await send(.resultReceived(.failure(error)))
                    }
                }

            case .resultReceived(.success(let result)):
                state.isExecuting = false
                state.result = result
                if result.isError {
                    state.error = "Tool returned an error"
                }
                return .none

            case .resultReceived(.failure(let error)):
                state.isExecuting = false
                state.error = error.localizedDescription
                return .none

            case .clearResult:
                state.result = nil
                state.error = nil
                return .none
            }
        }
    }
}
