//
//  APIKeySettingsView.swift
//  danreps
//
//  Created by Claude Code
//

import SwiftUI

struct APIKeySettingsView: View {
    @State private var apiKey: String = ""
    @State private var showSaved = false
    @State private var keyExists = false
    @State private var testResult: String = ""
    @State private var isTesting = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Anthropic API Key")) {
                    SecureField("sk-ant-...", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))

                    if keyExists {
                        Text("✓ API Key is saved")
                            .foregroundColor(.green)
                    }
                }

                Section(header: Text("Get Your API Key")) {
                    Link("Open Anthropic Console", destination: URL(string: "https://console.anthropic.com/")!)
                    Text("Sign up, add credits, and create an API key in the console.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Section {
                    Button("Save API Key") {
                        saveKey()
                    }
                    .disabled(apiKey.isEmpty)

                    if keyExists {
                        Button("Test API Key") {
                            Task {
                                await testAPIKey()
                            }
                        }
                        .disabled(isTesting)

                        if !testResult.isEmpty {
                            Text(testResult)
                                .font(.caption)
                                .foregroundColor(testResult.contains("✓") ? .green : .red)
                        }

                        Button("Delete API Key", role: .destructive) {
                            deleteKey()
                        }
                    }
                }

                if isTesting {
                    Section {
                        ProgressView("Testing API key...")
                    }
                }
            }
            .navigationTitle("Claude API Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkIfKeyExists()
            }
            .alert("Saved!", isPresented: $showSaved) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your API key has been saved securely in the Keychain.")
            }
        }
    }

    private func saveKey() {
        let success = KeychainService.shared.saveAPIKey(apiKey)
        if success {
            showSaved = true
            keyExists = true
            apiKey = "" // Clear the text field for security
        }
    }

    private func deleteKey() {
        _ = KeychainService.shared.deleteAPIKey()
        keyExists = false
        apiKey = ""
    }

    private func checkIfKeyExists() {
        keyExists = KeychainService.shared.getAPIKey() != nil
    }

    private func testAPIKey() async {
        isTesting = true
        testResult = ""

        do {
            let claude = ClaudeService()
            let response = try await claude.prompt("Say 'API key working!' and nothing else.")
            testResult = "✓ Success: \(response)"
        } catch {
            testResult = "✗ Failed: \(error)"
        }

        isTesting = false
    }
}
