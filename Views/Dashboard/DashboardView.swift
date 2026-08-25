
import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: NodewatchViewModel
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if viewModel.selectedGrouping == .host {
                    HostTrafficLightView(viewModel: viewModel)
                        .padding(.horizontal)
                } else {
                    ServiceTrafficLightView(viewModel: viewModel)
                        .padding(.horizontal)
                }
                
                Picker("Group By", selection: $viewModel.selectedGrouping) {
                    ForEach(GroupBy.allCases, id: \.self) { group in
                        Text(group.rawValue).tag(group)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List {
                    ForEach(viewModel.groupedServices) { group in
                        if viewModel.selectedGrouping == .host {
                            HostSectionView(group: group)
                        } else if viewModel.selectedGrouping == .state {
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
                .navigationDestination(for: NodeService.self) { service in
                    ServiceDetailView(service: service)
                }
            }
            .navigationTitle(viewModel.instanceName)
            .task {
                await viewModel.fetchLiveData(from: "http://aphorite.local:5678/webhook/nodewatch-services")
            }
            .refreshable {
                await viewModel.fetchLiveData(from: "http://aphorite.local:5678/webhook/nodewatch-services")
            }
        }
    }
}
