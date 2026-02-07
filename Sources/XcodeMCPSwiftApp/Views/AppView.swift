//
//  AppView.swift
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

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
        } detail: {
            DetailView(store: store)
        }
        .navigationTitle("Xcode MCP Swift App")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                ConnectionIndicator(store: store.scope(state: \.bridge, action: \.bridge))
            }
        }
    }
}

// MARK: - Sidebar

private struct SidebarView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        List(selection: $store.selectedTab.sending(\.tabSelected)) {
            Section("Navigation") {
                Label("Tools", systemImage: "wrench.and.screwdriver")
                    .tag(AppFeature.State.Tab.tools)

                Label("Settings", systemImage: "gear")
                    .tag(AppFeature.State.Tab.settings)

                Label("About", systemImage: "info.circle")
                    .tag(AppFeature.State.Tab.about)
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180)
    }
}

// MARK: - Detail

private struct DetailView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        switch store.selectedTab {
        case .tools:
            ToolsPanel(store: store)
        case .settings:
            SettingsPanel(store: store.scope(state: \.bridge, action: \.bridge))
        case .about:
            AboutView()
        }
    }
}

// MARK: - Tools Panel (split: list + call)

private struct ToolsPanel: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        HSplitView {
            ToolListView(store: store.scope(state: \.toolList, action: \.toolList))
                .frame(minWidth: 250, idealWidth: 300)

            if let toolCallStore = store.scope(state: \.toolCall, action: \.toolCall) {
                ToolCallView(store: toolCallStore, onClose: { store.send(.closeToolCall) })
                    .frame(minWidth: 400)
            } else {
                EmptyToolCallPlaceholder(isConnected: store.bridge.isConnected)
            }
        }
    }
}

// MARK: - Connection Indicator (toolbar)

private struct ConnectionIndicator: View {
    let store: StoreOf<MCPBridgeFeature>

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(store.isConnected ? .green : .red)
                .frame(width: 8, height: 8)

            Text(store.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
    }
}

// MARK: - Settings Panel

private struct SettingsPanel: View {
    let store: StoreOf<MCPBridgeFeature>

    private var isConnecting: Bool {
        store.status == .connecting || store.status == .installing
    }

    var body: some View {
        Form {
            Section("Connection") {
                HStack {
                    if store.isConnected {
                        Button("Disconnect") {
                            store.send(.disconnectTapped)
                        }
                        .tint(.red)
                    } else {
                        Button(isConnecting ? "Connecting…" : "Connect to Xcode") {
                            store.send(.connectTapped)
                        }
                        .disabled(isConnecting)
                    }
                }

                if let error = store.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                if let info = store.serverInfo {
                    LabeledContent("Server", value: info.name)
                    LabeledContent("Version", value: info.version)
                    LabeledContent("Protocol", value: info.protocolVersion)
                }
            }

            Section("CLI Binary") {
                LabeledContent("Install Path", value: MCPBridgeConfiguration().installPath)

                switch store.status {
                case .notInstalled:
                    LabeledContent("Status", value: "Not Installed")
                case .installing:
                    HStack {
                        Text("Status")
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                        Text("Installing…")
                            .foregroundStyle(.secondary)
                    }
                case .installed, .connecting, .connected, .executing:
                    LabeledContent("Status", value: "Installed ✓")
                }

                if store.isConnected || store.status == .installed {
                    Button("Uninstall CLI") {
                        store.send(.uninstallTapped)
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Placeholder

private struct EmptyToolCallPlaceholder: View {
    let isConnected: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: isConnected ? "wrench.and.screwdriver" : "cable.connector")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(isConnected
                ? "Select a tool from the list to execute it"
                : "Connect to Xcode MCP Bridge first")
                .foregroundStyle(.secondary)

            if !isConnected {
                Text("Go to Settings and click Connect")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
