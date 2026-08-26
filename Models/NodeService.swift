import SwiftUI

struct NodeService: Identifiable, Codable, Hashable {
    var id: String { "\(host)-\(serviceName)" }
    let host: String
    let hostState: HostState?
    let hostGroups: [String]?
    let serviceName: String
    let state: ServiceState
    let output: String
    
    enum CodingKeys: String, CodingKey {
        case host
        case hostState = "host_state"
        case hostGroups = "host_groups"
        case serviceName = "service_name"
        case state
        case output
    }
    
    enum ServiceState: String, Codable {
        case ok = "OK"
        case warning = "WARNING"
        case critical = "CRITICAL"
        case pending = "PENDING"
        case unknown = "UNKNOWN"
        
        var colour: Color {
            switch self {
                case .ok: return .green
                case .warning: return .yellow
                case .critical: return .red
                case .pending: return .blue
                case .unknown: return .orange
            }
        }
        
        var icon: String {
            switch self {
                case .ok: return Constants.Icons.serviceOk
                case .warning: return Constants.Icons.serviceWarning
                case .critical: return Constants.Icons.serviceCritical
                case .pending: return Constants.Icons.servicePending
                case .unknown: return Constants.Icons.serviceUnknown
            }
        }
        
        var emoji: String {
            switch self {
                case .ok: return "🟢"
                case .critical: return "🔴"
                case .warning: return "🟡"
                case .unknown: return "🟠"
                case .pending: return "🔵"
            }
        }
        
        var priority: Int {
            switch self {
                case .critical: return 0
                case .warning: return 1
                case .unknown: return 2
                case .pending: return 3
                case .ok: return 4
            }
        }
    }
    
    enum HostState: String, Codable {
        case up = "UP"
        case down = "DOWN"
        case unreachable = "UNREACHABLE"
        case pending = "PENDING"
        
        var colour: Color {
            switch self {
                case .up: return .green
                case .down: return .red
                case .unreachable: return .orange
                case .pending: return .blue
            }
        }
        
        var icon: String {
            switch self {
                case .up: return Constants.Icons.hostUp
                case .down: return Constants.Icons.hostDown
                case .unreachable: return Constants.Icons.hostUnreachable
                case .pending: return Constants.Icons.servicePending
            }
        }
        
        var emoji: String {
            switch self {
                case .up: return "🟢"
                case .down: return "🔴"
                case .unreachable: return "🟠"
                case .pending: return "🔵"
            }
        }
        
        var priority: Int {
            switch self {
                case .down: return 0
                case .unreachable: return 1
                case .pending: return 2
                case .up: return 3
            }
        }
    }
}
