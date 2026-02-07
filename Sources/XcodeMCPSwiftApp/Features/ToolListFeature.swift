//
//  ToolListFeature.swift
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
struct ToolListFeature {
    @ObservableState
    struct State: Equatable {
        var tools: [MCPTool] = []
        var isLoading = false
        var searchText = ""
        var selectedToolName: String?
        var error: String?

        var filteredTools: [MCPTool] {
            if searchText.isEmpty { return tools }
            let query = searchText.lowercased()
            return tools.filter {
                $0.name.lowercased().contains(query)
                    || ($0.description?.lowercased().contains(query) ?? false)
            }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case refreshTapped
        case toolsLoaded(Result<[MCPTool], Error>)
        case toolSelected(MCPTool)
        case clearSelection
    }

    @Dependency(\.mcpBridgeClient) var mcpBridge

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .refreshTapped:
                state.isLoading = true
                state.error = nil
                return .run { send in
                    do {
                        let tools = try await mcpBridge.listTools()
                        await send(.toolsLoaded(.success(tools)))
                    } catch {
                        await send(.toolsLoaded(.failure(error)))
                    }
                }

            case .toolsLoaded(.success(let tools)):
                state.isLoading = false
                state.tools = tools.sorted(by: { $0.name < $1.name })
                return .none

            case .toolsLoaded(.failure(let error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none

            case .toolSelected(let tool):
                state.selectedToolName = tool.name
                return .none

            case .clearSelection:
                state.selectedToolName = nil
                return .none
            }
        }
    }
}
