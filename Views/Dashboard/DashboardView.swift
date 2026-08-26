import SwiftUI
import Combine

private enum UIConstants {
    static let searchPlaceholder = "Search..."
    static let searchIcon = "magnifyingglass"
    static let clearIcon = "xmark.circle.fill"
}

struct DashboardView: View {
    @ObservedObject var viewModel: NodewatchViewModel
    @AppStorage(Constants.Storage.serverConfigKey) private var serverConfigData: Data = Data()
    
    @Environment(\.scenePhase) var scenePhase
    @State private var backgroundDate: Date?
    let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var editingConfig: ServerConfig = ServerConfig()
    @State private var showEditSheet = false
    
    private var activeServer: ServerConfig {
        if let decoded = try? JSONDecoder().decode(ServerConfig.self, from: serverConfigData) {
            return decoded
        }
        return ServerConfig(name: "Not configured")
    }
    
    private var activeFilterText: String? {
        viewModel.selectedGrouping == .none ? nil : activeServer.hostGroups
    }
    
    private var currentSearchText: Binding<String> {
        Binding(
            get: { viewModel.searchTexts[viewModel.selectedGrouping] ?? "" },
            set: { viewModel.searchTexts[viewModel.selectedGrouping] = $0 }
        )
    }
    
    private var isSearching: Bool {
        !currentSearchText.wrappedValue.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                
                HStack {
                    if viewModel.isRefreshing {
                        Text("Refreshing...")
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        if let last = viewModel.lastRefresh {
                            Text("Last updated: \(last.formatted(date: .omitted, time: .shortened))")
                        } else {
                            Text("Waiting for data...")
                        }
                        Spacer()
                        Text("Refresh in \(viewModel.nextRefreshCountdown)s")
                            .monospacedDigit()
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                if viewModel.selectedGrouping == .host {
                    HostTrafficLightView(viewModel: viewModel, filterText: activeFilterText, onFilterTap: presentFilterEditor)
                        .padding(.horizontal)
                } else {
                    ServiceTrafficLightView(viewModel: viewModel, filterText: activeFilterText, onFilterTap: presentFilterEditor)
                        .padding(.horizontal)
                }
                
                Picker("Group By", selection: $viewModel.selectedGrouping) {
                    Text("\(Image(systemName: "square.stack.3d.up")) By Service").tag(GroupBy.service)
                    Text("\(Image(systemName: "server.rack")) By Host").tag(GroupBy.host)
                    Text("\(Image(systemName: "list.bullet")) All Services").tag(GroupBy.none)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                HStack {
                    Image(systemName: UIConstants.searchIcon)
                        .foregroundStyle(.secondary)
                    
                    TextField(UIConstants.searchPlaceholder, text: currentSearchText)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                    
                    if !currentSearchText.wrappedValue.isEmpty {
                        Button(action: { currentSearchText.wrappedValue = "" }) {
                            Image(systemName: UIConstants.clearIcon)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
                .background(Color(uiColor: .tertiarySystemFill))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 8)
                
                List {
                    if viewModel.selectedGrouping == .host {
                        ForEach(viewModel.hostStateGroups) { stateGroup in
                            HostStateSectionView(stateGroup: stateGroup, isSearching: isSearching)
                        }
                    } else {
                        ForEach(viewModel.groupedServices) { group in
                            if viewModel.selectedGrouping == .service {
                                StateSectionView(group: group, isSearching: isSearching)
                            } else {
                                Section(header: Text(group.name)) {
                                    ForEach(group.items) { service in
                                        NavigationLink(value: service) {
                                            ServiceRowView(service: service)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .contentMargins(.top, 0, for: .scrollContent)
                .environment(\.defaultMinListRowHeight, 32)
                .navigationDestination(for: NodeService.self) { service in
                    ServiceDetailView(service: service)
                }
            }
            .navigationTitle(activeServer.name)
            .task {
                if !activeServer.url.isEmpty {
                    await viewModel.fetchLiveData(from: activeServer.fullUrl)
                }
            }
            .refreshable {
                if !activeServer.url.isEmpty {
                    await viewModel.fetchLiveData(from: activeServer.fullUrl)
                }
            }
            .onReceive(refreshTimer) { _ in
                if viewModel.nextRefreshCountdown > 0 {
                    viewModel.nextRefreshCountdown -= 1
                } else {
                    viewModel.nextRefreshCountdown = Constants.AppState.autoRefreshInterval
                    Task {
                        if !activeServer.url.isEmpty {
                            await viewModel.fetchLiveData(from: activeServer.fullUrl)
                        }
                    }
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    backgroundDate = Date()
                } else if newPhase == .active {
                    if let bgDate = backgroundDate, Date().timeIntervalSince(bgDate) > Constants.AppState.searchClearThreshold {
                        viewModel.searchTexts = [.service: "", .host: "", .none: ""]
                    }
                    backgroundDate = nil
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditServerView(config: $editingConfig, initialFocus: .hostGroups) { newConfig, _ in
                    if let encoded = try? JSONEncoder().encode(newConfig) {
                        serverConfigData = encoded
                    }
                    Task {
                        if !newConfig.url.isEmpty {
                            await viewModel.fetchLiveData(from: newConfig.fullUrl)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.hostGroupsFilter = activeServer.hostGroups
            }
            .onChange(of: activeServer.hostGroups) {
                viewModel.hostGroupsFilter = activeServer.hostGroups
            }
        }
    }
    
    private func presentFilterEditor() {
        editingConfig = activeServer
        showEditSheet = true
    }
}
