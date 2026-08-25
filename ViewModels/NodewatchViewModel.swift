import SwiftUI
import Combine

enum GroupBy: String, CaseIterable {
    case state = "By State"
    case host = "By Host"
    case none = "All Services"
}

struct ServiceGroup: Identifiable {
    var id: String { name }
    let name: String
    let hostState: NodeService.HostState? 
    let items: [NodeService]
}

class NodewatchViewModel: ObservableObject {
    @Published var instanceName: String = "nagios.mohc.net"
    @Published var services: [NodeService] = []
    @Published var selectedGrouping: GroupBy = .state
    
    // -- Service Counts --
    var countOK: Int { services.filter { $0.state == .ok }.count }
    var countCritical: Int { services.filter { $0.state == .critical }.count }
    var countWarning: Int { services.filter { $0.state == .warning }.count }
    var countUnknown: Int { services.filter { $0.state == .unknown }.count }
    var countPending: Int { services.filter { $0.state == .pending }.count }
    
    // -- Host Counts --
    var uniqueHosts: [String: NodeService.HostState] {
        var hosts = [String: NodeService.HostState]()
        for service in services {
            // Safely defaults to .up if the JSON didn't provide a host state
            hosts[service.host] = service.hostState ?? .up
        }
        return hosts
    }
    var countHostUp: Int { uniqueHosts.values.filter { $0 == .up }.count }
    var countHostDown: Int { uniqueHosts.values.filter { $0 == .down }.count }
    var countHostUnreachable: Int { uniqueHosts.values.filter { $0 == .unreachable }.count }
    var countHostPending: Int { uniqueHosts.values.filter { $0 == .pending }.count }
    
    var groupedServices: [ServiceGroup] {
        switch selectedGrouping {
        case .none:
            let sortedItems = services.sorted {
                if $0.serviceName == $1.serviceName { return $0.host < $1.host }
                return $0.serviceName < $1.serviceName
            }
            return [ServiceGroup(name: "All Services", hostState: nil, items: sortedItems)]
            
        case .host:
            let dict = Dictionary(grouping: services, by: { $0.host })
            let sortedHosts = dict.keys.sorted(by: <)
            
            return sortedHosts.map { host in
                let items = dict[host]!
                let hostState = items.first?.hostState ?? .up
                let sortedItems = items.sorted {
                    if $0.state.priority == $1.state.priority { return $0.serviceName < $1.serviceName }
                    return $0.state.priority < $1.state.priority
                }
                return ServiceGroup(name: host, hostState: hostState, items: sortedItems)
            }
            
        case .state:
            let dict = Dictionary(grouping: services, by: { $0.state })
            let sortedStates = dict.keys.sorted { $0.priority < $1.priority }
            
            return sortedStates.map { state in
                let sortedItems = dict[state]!.sorted {
                    if $0.host == $1.host { return $0.serviceName < $1.serviceName }
                    return $0.host < $1.host
                }
                return ServiceGroup(name: state.rawValue, hostState: nil, items: sortedItems)
            }
        }
    }
    
    func fetchLiveData(from endpoint: String) async {
        guard let url = URL(string: endpoint) else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            let decoder = JSONDecoder()
            let decodedServices = try decoder.decode([NodeService].self, from: data)
            
            await MainActor.run { self.services = decodedServices }
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
        }
    }
}
