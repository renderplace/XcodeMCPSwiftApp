//
//  ToolListView.swift
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
import SwiftUI
import XcodeMCPBridge

struct ToolListView: View {
    @Bindable var store: StoreOf<ToolListFeature>

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Available Tools")
                    .font(.headline)
                Spacer()

                if store.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button {
                    store.send(.refreshTapped)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                .help("Refresh tool list")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search tools…", text: $store.searchText)
                    .textFieldStyle(.plain)

                if !store.searchText.isEmpty {
                    Button {
                        store.send(.binding(.set(\.searchText, "")))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            Divider()

            // Tool list
            if store.filteredTools.isEmpty && !store.isLoading {
                VStack(spacing: 8) {
                    if store.tools.isEmpty {
                        Text("No tools available")
                            .foregroundStyle(.secondary)
                        Text("Connect to Xcode and refresh")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("No matching tools")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ToolListContent(store: store)
            }

            // Error
            if let error = store.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }

            // Footer: tool count
            HStack {
                Text("\(store.tools.count) tools")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .background(.bar)
        }
    }
}

// MARK: - Tool List Content

private struct ToolListContent: View {
    let store: StoreOf<ToolListFeature>

    var body: some View {
        List(store.filteredTools, selection: .constant(store.selectedToolName)) { tool in
            ToolRow(tool: tool)
                .contentShape(Rectangle())
                .onTapGesture {
                    store.send(.toolSelected(tool))
                }
                .tag(tool.name)
        }
        .listStyle(.inset)
    }
}

// MARK: - Tool Row

private struct ToolRow: View {
    let tool: MCPTool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: toolIcon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 16)
                Text(tool.name)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)
            }

            if let desc = tool.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let schema = tool.inputSchema, let props = schema.properties {
                HStack(spacing: 4) {
                    Text("\(props.count) params")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.quaternary)
                        .clipShape(Capsule())

                    if let required = schema.required, !required.isEmpty {
                        Text("\(required.count) required")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var toolIcon: String {
        let name = tool.name.lowercased()
        if name.contains("build") { return "hammer" }
        if name.contains("test") { return "checkmark.circle" }
        if name.contains("doc") || name.contains("search") { return "doc.text.magnifyingglass" }
        if name.contains("file") { return "doc" }
        if name.contains("preview") || name.contains("render") { return "eye" }
        if name.contains("snippet") || name.contains("swift") { return "swift" }
        if name.contains("project") || name.contains("scheme") { return "folder" }
        return "wrench"
    }
}
