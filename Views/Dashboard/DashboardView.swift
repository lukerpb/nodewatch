import SwiftUI
import Combine

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
                    } else if let error = viewModel.lastFetchError {
                        Text(error)
                            .foregroundStyle(.red)
                            .lineLimit(1)
                        Spacer()
                        Button {
                            Task { await viewModel.fetchLiveData(from: activeServer.fullUrl) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.red)
                        }
                    } else {
                        if let last = viewModel.lastRefresh {
                            Text("Last updated: \(last.formatted(date: .omitted, time: .shortened))")
                        } else {
                            Text("Waiting for data...")
                        }
                        Spacer()

                        Button(action: {
                            Task { await viewModel.fetchLiveData(from: activeServer.fullUrl) }
                        }) {
                            HStack(spacing: 4) {
                                Text("Refresh")
                                    .foregroundStyle(.blue)
                                
                                Text("in \(viewModel.nextRefreshCountdown)s")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                if activeServer.url.isEmpty {
        
                    EmptyStateView(
                        icon: Constants.Icons.dashboardTab,
                        title: Constants.EmptyStates.noServerTitle,
                        message: Constants.EmptyStates.noServerMsg,
                        actionTitle: Constants.EmptyStates.noServerAction
                    ) { presentFilterEditor() }
                    
                } else if let error = viewModel.lastFetchError, viewModel.services.isEmpty {
                    
                    EmptyStateView(
                        icon: Constants.Icons.error,
                        title: Constants.EmptyStates.errorTitle,
                        message: error,
                        actionTitle: Constants.EmptyStates.errorAction
                    ) { Task { await viewModel.fetchLiveData(from: activeServer.fullUrl) } }
                    
                } else if viewModel.services.isEmpty {
    
                    if viewModel.isRefreshing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Fetching services...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 40)
                    } else {
                    
                        EmptyStateView(
                            icon: Constants.Icons.emptyTray,
                            title: Constants.EmptyStates.noDataTitle,
                            message: Constants.EmptyStates.noDataMsg
                        )
                        
                    }
                    
                } else {
                    if viewModel.selectedGrouping == .host {
                        HostTrafficLightView(viewModel: viewModel, filterText: activeFilterText, onFilterTap: presentFilterEditor)
                            .padding(.horizontal)
                    } else {
                        ServiceTrafficLightView(viewModel: viewModel, filterText: activeFilterText, onFilterTap: presentFilterEditor)
                            .padding(.horizontal)
                    }
                    
                    Picker("Group by", selection: $viewModel.selectedGrouping) {
                        Text("\(Image(systemName: Constants.Icons.groupService)) service").tag(GroupBy.service)
                        Text("\(Image(systemName: Constants.Icons.dashboardTab)) host").tag(GroupBy.host)
                        Text("\(Image(systemName: Constants.Icons.groupAll)) all services").tag(GroupBy.none)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: Constants.Icons.search)
                            .foregroundStyle(.secondary)
                        
                        TextField(Constants.Strings.searchPlaceholder, text: currentSearchText)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                        
                        if !currentSearchText.wrappedValue.isEmpty {
                            Button(action: { currentSearchText.wrappedValue = "" }) {
                                Image(systemName: Constants.Icons.clear)
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
                    
                    if viewModel.searchedServices.isEmpty {
                        EmptyStateView(
                            icon: Constants.Icons.search,
                            title: Constants.EmptyStates.noResultsTitle,
                            message: Constants.EmptyStates.noResultsMsg
                        )
                    } else {
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
                        .environment(\.defaultMinListRowHeight, Constants.Layout.defaultListRowHeight)
                        .navigationDestination(for: NodeService.self) { service in
                            ServiceDetailView(service: service)
                        }
                    }
                }
            }
            .navigationTitle(activeServer.name)
            .task {
                if !activeServer.url.isEmpty && viewModel.lastRefresh == nil {
                    await viewModel.fetchLiveData(from: activeServer.fullUrl)
                }
            }
            .refreshable {
                if !activeServer.url.isEmpty {
                    await viewModel.fetchLiveData(from: activeServer.fullUrl)
                }
            }
            .onReceive(refreshTimer) { _ in
                guard viewModel.lastFetchError == nil else { return }
                
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
            .onChange(of: serverConfigData) { oldData, newData in
                guard let oldConfig = try? JSONDecoder().decode(ServerConfig.self, from: oldData),
                        let newConfig = try? JSONDecoder().decode(ServerConfig.self, from: newData) else { return }
                
                if oldConfig.fullUrl != newConfig.fullUrl {
                    viewModel.services = []
                    viewModel.lastFetchError = nil
                    if !newConfig.url.isEmpty {
                        Task { await viewModel.fetchLiveData(from: newConfig.fullUrl) }
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                // The sheet is now beautifully clean; the .onChange above handles all the heavy lifting
                EditServerView(config: $editingConfig, initialFocus: .hostGroups) { newConfig, _ in
                    if let encoded = try? JSONEncoder().encode(newConfig) {
                        serverConfigData = encoded
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
