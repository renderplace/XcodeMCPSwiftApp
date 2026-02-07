//
//  AppFeature.swift
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

// MARK: - Xcode Window Tab Model

struct XcodeWindowTab: Equatable, Identifiable, Sendable {
    var id: String { tabIdentifier }
    let tabIdentifier: String
    let workspacePath: String

    var displayName: String {
        let name = (workspacePath as NSString).lastPathComponent
        return "\(tabIdentifier) — \(name)"
    }

    /// Parse XcodeListWindows tool output into tab entries.
    static func parse(from text: String) -> [XcodeWindowTab] {
        var results: [XcodeWindowTab] = []
        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("tabIdentifier") else { continue }

            var tabId: String?
            var wsPath: String?

            if let range = trimmed.range(of: "tabIdentifier:") {
                let after = trimmed[range.upperBound...].trimmingCharacters(in: .whitespaces)
                if let commaIdx = after.firstIndex(of: ",") {
                    tabId = String(after[after.startIndex..<commaIdx]).trimmingCharacters(in: .whitespaces)
                } else {
                    tabId = after.trimmingCharacters(in: .whitespaces)
                }
            }

            if let range = trimmed.range(of: "workspacePath:") {
                let after = trimmed[range.upperBound...].trimmingCharacters(in: .whitespaces)
                if let commaIdx = after.firstIndex(of: ",") {
                    wsPath = String(after[after.startIndex..<commaIdx]).trimmingCharacters(in: .whitespaces)
                } else {
                    wsPath = after.trimmingCharacters(in: .whitespaces)
                }
            }

            if let tabId, !tabId.isEmpty {
                results.append(XcodeWindowTab(
                    tabIdentifier: tabId,
                    workspacePath: wsPath ?? "Unknown"
                ))
            }
        }
        return results
    }
}

// MARK: - AppFeature

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var bridge = MCPBridgeFeature.State()
        var toolList = ToolListFeature.State()
        var toolCall: ToolCallFeature.State?
        var selectedTab: Tab = .tools
        var availableWindows: [XcodeWindowTab] = []

        enum Tab: String, CaseIterable, Equatable {
            case tools = "Tools"
            case settings = "Settings"
        }
    }

    enum Action {
        case bridge(MCPBridgeFeature.Action)
        case toolList(ToolListFeature.Action)
        case toolCall(ToolCallFeature.Action)
        case tabSelected(State.Tab)
        case openToolCall(MCPTool)
        case closeToolCall
        case fetchWindows
        case windowsLoaded(Result<[XcodeWindowTab], Error>)
    }

    @Dependency(\.mcpBridgeClient) var mcpBridge

    var body: some ReducerOf<Self> {
        Scope(state: \.bridge, action: \.bridge) {
            MCPBridgeFeature()
        }
        Scope(state: \.toolList, action: \.toolList) {
            ToolListFeature()
        }

        Reduce { state, action in
            switch action {
            // When connection succeeds, auto-refresh tools
            case .bridge(._connectionResult(.success)):
                return .send(.toolList(.refreshTapped))

            // When tools are loaded, also fetch available windows
            case .toolList(.toolsLoaded(.success)):
                return .send(.fetchWindows)

            // When disconnected, clear everything
            case .bridge(._disconnected):
                state.toolList.tools = []
                state.toolCall = nil
                state.availableWindows = []
                return .none

            // When a tool is selected in the list, open the tool call panel
            case .toolList(.toolSelected(let tool)):
                state.toolCall = ToolCallFeature.State(
                    tool: tool,
                    availableWindows: state.availableWindows
                )
                return .none

            case .openToolCall(let tool):
                state.toolCall = ToolCallFeature.State(
                    tool: tool,
                    availableWindows: state.availableWindows
                )
                return .none

            case .closeToolCall:
                state.toolCall = nil
                state.toolList.selectedToolName = nil
                return .none

            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .fetchWindows:
                return .run { send in
                    do {
                        let result = try await mcpBridge.callTool("XcodeListWindows", [:])
                        let text = result.content.compactMap(\.text).joined(separator: "\n")
                        let tabs = XcodeWindowTab.parse(from: text)
                        await send(.windowsLoaded(.success(tabs)))
                    } catch {
                        await send(.windowsLoaded(.failure(error)))
                    }
                }

            case .windowsLoaded(.success(let windows)):
                state.availableWindows = windows
                state.toolCall?.availableWindows = windows
                if windows.count == 1, let tab = windows.first {
                    state.toolCall?.parameters["tabIdentifier"] = tab.tabIdentifier
                }
                return .none

            case .windowsLoaded(.failure):
                return .none

            case .bridge, .toolList, .toolCall:
                return .none
            }
        }
        .ifLet(\.toolCall, action: \.toolCall) {
            ToolCallFeature()
        }
    }
}
