import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: NodewatchViewModel
    @AppStorage("serverConfigData") private var serverConfigData: Data = Data()
    
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
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                
                if viewModel.selectedGrouping == .host {
                    HostTrafficLightView(viewModel: viewModel, filterText: activeFilterText, onFilterTap: presentFilterEditor)
                        .padding(.horizontal)
                } else {
                    ServiceTrafficLightView(viewModel: viewModel, filterText: activeFilterText, onFilterTap: presentFilterEditor)
                        .padding(.horizontal)
                }
                
                // NEW: Iconography mixed into the title text
                Picker("Group By", selection: $viewModel.selectedGrouping) {
                    Text("\(Image(systemName: "square.stack.3d.up")) By Service").tag(GroupBy.service)
                    Text("\(Image(systemName: "server.rack")) By Host").tag(GroupBy.host)
                    Text("\(Image(systemName: "list.bullet")) All Services").tag(GroupBy.none)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List {
                    if viewModel.selectedGrouping == .host {
                        // NEW: Loop over the outer HostState groups
                        ForEach(viewModel.hostStateGroups) { stateGroup in
                            HostStateSectionView(stateGroup: stateGroup)
                        }
                    } else {
                        ForEach(viewModel.groupedServices) { group in
                            if viewModel.selectedGrouping == .service {
                                StateSectionView(group: group)
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
