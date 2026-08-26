import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: NodewatchViewModel
    
    @AppStorage(Constants.Storage.serverConfigKey) private var serverConfigData: Data = Data()
    @State private var serverConfig: ServerConfig = ServerConfig()
    @State private var isShowingEditSheet = false
    @State private var testState: TestState = .idle
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Servers")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(serverConfig.name).font(.headline)
                            
                            Text(serverConfig.url.isEmpty ? "Not Configured" : serverConfig.url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            // NEW: Dynamic Data Readout
                            if serverConfig.lastError == nil && !viewModel.services.isEmpty {
                                if viewModel.isFiltering {
                                    Text("Filtering active: showing \(viewModel.filteredHostCount)/\(viewModel.totalHostCount) hosts, \(viewModel.filteredServiceCount)/\(viewModel.totalServiceCount) services")
                                        .font(.caption)
                                        .foregroundStyle(Color(red: 1.0, green: 0.6, blue: 0.7)) // babyPink
                                } else {
                                    Text("\(viewModel.totalHostCount) hosts, \(viewModel.totalServiceCount) services")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            Task { await runConnectionTest() }
                        }) {
                            ZStack {
                                if testState == .idle {
                                    Text("Test")
                                        .bold()
                                        .foregroundStyle(.blue)
                                        .transition(.opacity)
                                } else if testState == .testing {
                                    ProgressView()
                                        .transition(.opacity)
                                } else if testState == .success {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .transition(.opacity)
                                } else if testState == .failure {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .transition(.opacity)
                                }
                            }
                            .frame(width: 60, alignment: .trailing)
                            .animation(.easeInOut(duration: Constants.UI.animationDuration), value: testState)
                        }
                        .buttonStyle(.plain)
                        .disabled(testState != .idle)
                        
                        // Edit Trigger
                        Button(action: { isShowingEditSheet = true }) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                        .padding(.leading, 8)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { loadConfig() }
            .sheet(isPresented: $isShowingEditSheet) {
                EditServerView(config: $serverConfig, saveAction: saveConfig)
            }
        }
    }
    
    private func loadConfig() {
        if let decoded = try? JSONDecoder().decode(ServerConfig.self, from: serverConfigData) {
            serverConfig = decoded
        }
    }
    
    private func saveConfig(newConfig: ServerConfig, triggerTest: Bool) {
        serverConfig = newConfig
        if let encoded = try? JSONEncoder().encode(serverConfig) {
            serverConfigData = encoded
        }
        if triggerTest {
            Task { await runConnectionTest() }
        }
    }
    
    private func runConnectionTest() async {
        await MainActor.run {
            withAnimation(.easeInOut(duration: Constants.UI.animationDuration)) {
                testState = .testing
            }
        }
        
        try? await Task.sleep(nanoseconds: Constants.UI.testSpinnerDelay)
        
        guard let url = URL(string: serverConfig.fullUrl) else {
            serverConfig.lastError = "Invalid URL format. Please check the address and port."
            saveConfig(newConfig: serverConfig, triggerTest: false)
            finaliseTestState(to: .failure)
            return
        }
        
        do {
            var request = URLRequest(url: url)
            
            request.timeoutInterval = Constants.Network.testRequestTimeout
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                serverConfig.lastError = nil
                finaliseTestState(to: .success)
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                serverConfig.lastError = "The server responded, but returned an error code: \(statusCode)."
                finaliseTestState(to: .failure)
            }
        } catch {
            serverConfig.lastError = "Connection failed: \(error.localizedDescription)"
            finaliseTestState(to: .failure)
        }
        
        saveConfig(newConfig: serverConfig, triggerTest: false)
    }
    
    private func finaliseTestState(to finalState: TestState) {
        Task {
            await MainActor.run {
                withAnimation(.easeInOut(duration: Constants.UI.animationDuration)) {
                    testState = finalState
                }
            }
            try? await Task.sleep(nanoseconds: Constants.UI.testResultHoldDuration)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: Constants.UI.animationDuration)) {
                    testState = .idle
                }
            }
        }
    }
}
