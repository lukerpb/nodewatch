import SwiftUI
import Combine

enum GroupBy: String, CaseIterable {
    case service = "By Service"
    case host = "By Host"
    case none = "All Services"
}

struct ServiceGroup: Identifiable {
    var id: String { "\(name)-\(items.count)" }
    let name: String
    let hostState: NodeService.HostState?
    let items: [NodeService]
}

struct HostGroup: Identifiable {
    var id: String { "\(name)-\(items.count)" }
    let name: String
    let state: NodeService.HostState
    let items: [NodeService]
}

struct HostStateGroup: Identifiable {
    var id: String { "\(state.rawValue)-\(hosts.reduce(0) { $0 + $1.items.count })" }
    let state: NodeService.HostState
    let hosts: [HostGroup]
}

class NodewatchViewModel: ObservableObject {
    @Published var services: [NodeService] = []
    @Published var selectedGrouping: GroupBy = .service
    @Published var hostGroupsFilter: String = ""

    @Published var searchTexts: [GroupBy: String] = [.service: "", .host: "", .none: ""]
    @Published var lastRefresh: Date? = nil
    @Published var nextRefreshCountdown: Int = Constants.AppState.autoRefreshInterval
    @Published var isRefreshing: Bool = false
    
    var isFiltering: Bool {
        !hostGroupsFilter.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var filteredServices: [NodeService] {
        if !isFiltering || selectedGrouping == .none { return services }
        
        let filters = hostGroupsFilter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        
        return services.filter { service in
            guard let serviceGroups = service.hostGroups else { return false }
            return serviceGroups.contains { group in
                filters.contains { filterTerm in group.lowercased().contains(filterTerm) }
            }
        }
    }

    var searchedServices: [NodeService] {
        let base = filteredServices
        let currentSearch = (searchTexts[selectedGrouping] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if currentSearch.isEmpty { return base }

        return base.filter { service in
            service.serviceName.lowercased().contains(currentSearch) ||
            service.host.lowercased().contains(currentSearch)
        }
    }
    
    var totalHostCount: Int { Set(services.map { $0.host }).count }
    var filteredHostCount: Int { Set(filteredServices.map { $0.host }).count }
    
    var totalServiceCount: Int { services.count }
    var filteredServiceCount: Int { filteredServices.count }
    
    var countOK: Int { filteredServices.filter { $0.state == .ok }.count }
    var countCritical: Int { filteredServices.filter { $0.state == .critical }.count }
    var countWarning: Int { filteredServices.filter { $0.state == .warning }.count }
    var countUnknown: Int { filteredServices.filter { $0.state == .unknown }.count }
    var countPending: Int { filteredServices.filter { $0.state == .pending }.count }
    
    var uniqueHosts: [String: NodeService.HostState] {
        var hosts = [String: NodeService.HostState]()
        for service in filteredServices { hosts[service.host] = service.hostState ?? .up }
        return hosts
    }
    
    var countHostUp: Int { uniqueHosts.values.filter { $0 == .up }.count }
    var countHostDown: Int { uniqueHosts.values.filter { $0 == .down }.count }
    var countHostUnreachable: Int { uniqueHosts.values.filter { $0 == .unreachable }.count }
    var countHostPending: Int { uniqueHosts.values.filter { $0 == .pending }.count }
    
    // NEW: Computed property to group Hosts by State
    var hostStateGroups: [HostStateGroup] {
        let hostDict = Dictionary(grouping: searchedServices, by: { $0.host })
        let allHostGroups = hostDict.map { (hostName, services) -> HostGroup in
            let state = services.first?.hostState ?? .up
            let sortedItems = services.sorted {
                if $0.state.priority == $1.state.priority { return $0.serviceName < $1.serviceName }
                return $0.state.priority < $1.state.priority
            }
            return HostGroup(name: hostName, state: state, items: sortedItems)
        }
        
        let stateDict = Dictionary(grouping: allHostGroups, by: { $0.state })
        let sortedStates: [NodeService.HostState] = [.down, .unreachable, .pending, .up]
        
        return sortedStates.compactMap { state in
            guard let hosts = stateDict[state], !hosts.isEmpty else { return nil }
            let sortedHosts = hosts.sorted { $0.name < $1.name }
            return HostStateGroup(state: state, hosts: sortedHosts)
        }
    }
    
    var groupedServices: [ServiceGroup] {
        switch selectedGrouping {
        case .none:
            let sortedItems = searchedServices.sorted {
                if $0.serviceName == $1.serviceName { return $0.host < $1.host }
                return $0.serviceName < $1.serviceName
            }
            return [ServiceGroup(name: "All Services", hostState: nil, items: sortedItems)]
            
        case .service:
            let dict = Dictionary(grouping: searchedServices, by: { $0.state })
            let sortedStates = dict.keys.sorted { $0.priority < $1.priority }
            
            return sortedStates.map { state in
                let sortedItems = dict[state]!.sorted {
                    if $0.host == $1.host { return $0.serviceName < $1.serviceName }
                    return $0.host < $1.host
                }
                return ServiceGroup(name: state.rawValue, hostState: nil, items: sortedItems)
            }
            
        case .host:
            return []
        }
    }
    
    func fetchLiveData(from endpoint: String) async {
        guard let url = URL(string: endpoint) else { return }
        
        await MainActor.run {
            self.isRefreshing = true
        }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = Constants.Network.fetchTimeout
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                await MainActor.run { self.isRefreshing = false }
                return
            }
            
            let decoder = JSONDecoder()
            let decodedServices = try decoder.decode([NodeService].self, from: data)
            
            await MainActor.run {
                self.services = decodedServices
                self.lastRefresh = Date()
                self.nextRefreshCountdown = Constants.AppState.autoRefreshInterval
                self.isRefreshing = false
            }
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
            await MainActor.run {
                self.isRefreshing = false
            }
        }
    }
}
