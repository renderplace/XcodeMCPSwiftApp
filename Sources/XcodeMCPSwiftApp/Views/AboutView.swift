//
//  AboutView.swift
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

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App Icon
            Image("AppLogo")
                .resizable()
                .frame(width: 128, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            // App Name
            Text("Xcode MCP Swift App")
                .font(.title)
                .fontWeight(.bold)

            // Version
            Text("Version 1.0")
                .font(.title3)
                .foregroundStyle(.secondary)

            Divider()
                .frame(maxWidth: 300)

            // Author
            VStack(spacing: 4) {
                Text("Created by")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Anton Gregorn")
                    .font(.headline)
                Link("@renderplace", destination: URL(string: "https://x.com/renderplace")!)
                    .font(.subheadline)
            }

            Divider()
                .frame(maxWidth: 300)

            // License
            VStack(spacing: 4) {
                Text("Licensed under the MIT License")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Copyright © 2026 Anton Gregorn")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
