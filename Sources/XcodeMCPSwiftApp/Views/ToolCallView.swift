//
//  ToolCallView.swift
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

struct ToolCallView: View {
    @Bindable var store: StoreOf<ToolCallFeature>
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.tool.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.monospaced)

                    if let desc = store.tool.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Parameters section
                    ParametersSection(store: store)

                    Divider()

                    // Execute button
                    HStack {
                        Button {
                            store.send(.executeTapped)
                        } label: {
                            HStack {
                                if store.isExecuting {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(store.isExecuting ? "Executing…" : "Execute Tool")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.isExecuting)
                        .keyboardShortcut(.return, modifiers: .command)

                        if store.result != nil {
                            Button("Clear Result") {
                                store.send(.clearResult)
                            }
                        }

                        Spacer()
                    }

                    // Error
                    if let error = store.error {
                        HStack(alignment: .top, spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(error)
                                .foregroundStyle(.red)
                                .textSelection(.enabled)
                        }
                        .font(.callout)
                    }

                    // Result
                    if let resultText = store.resultText {
                        ResultSection(text: resultText, isError: store.result?.isError ?? false)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Parameters Section

private struct ParametersSection: View {
    @Bindable var store: StoreOf<ToolCallFeature>

    var body: some View {
        let params = store.parameterKeys

        if params.isEmpty {
            Text("This tool takes no parameters")
                .foregroundStyle(.secondary)
                .font(.callout)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parameters")
                    .font(.headline)

                ForEach(params) { param in
                    ParameterField(
                        param: param,
                        value: Binding(
                            get: { store.parameters[param.key] ?? "" },
                            set: { store.send(.parameterChanged(key: param.key, value: $0)) }
                        ),
                        availableWindows: store.availableWindows
                    )
                }
            }
        }
    }
}

// MARK: - Parameter Field

private struct ParameterField: View {
    let param: ToolCallFeature.ParameterInfo
    @Binding var value: String
    var availableWindows: [XcodeWindowTab] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(param.key)
                    .font(.system(.callout, design: .monospaced))
                    .fontWeight(.medium)

                Text("(\(param.type))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if param.isRequired {
                    Text("required")
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.red.opacity(0.15))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }

            if let desc = param.description {
                Text(desc)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if param.key == "tabIdentifier" && !availableWindows.isEmpty {
                Picker("", selection: $value) {
                    Text("Select window…").tag("")
                    ForEach(availableWindows) { tab in
                        Text(tab.displayName).tag(tab.tabIdentifier)
                    }
                }
                .labelsHidden()
            } else if let enumValues = param.enumValues, !enumValues.isEmpty {
                Picker("", selection: $value) {
                    Text("Select…").tag("")
                    ForEach(enumValues, id: \.self) { val in
                        Text(val).tag(val)
                    }
                }
                .labelsHidden()
            } else if param.type == "boolean" {
                Toggle(isOn: Binding(
                    get: { value == "true" },
                    set: { value = $0 ? "true" : "false" }
                )) {
                    EmptyView()
                }
                .labelsHidden()
            } else {
                TextField(param.isRequired ? "Required" : "Optional", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }
}

// MARK: - Result Section

private struct ResultSection: View {
    let text: String
    let isError: Bool

    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Result")
                    .font(.headline)

                if isError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Tool reported an error")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Spacer()

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isCopied = false
                    }
                } label: {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                }
                .help("Copy result")
            }

            ScrollView(.vertical) {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(maxHeight: 400)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(.separator)
            )
        }
    }
}
