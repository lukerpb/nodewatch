import Foundation

struct ServerConfig: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String = "nagios.mohc.net"
    var url: String = ""
    var port: String = ""
    var hostGroups: String = ""
    var lastError: String? = nil
    
    var fullUrl: String {
        let cleanPort = port.trimmingCharacters(in: .whitespaces)
        let finalPort = cleanPort.isEmpty ? "5678" : cleanPort
        return "\(url):\(finalPort)/webhook/nodewatch-services"
    }
}

enum TestState {
    case idle
    case testing
    case success
    case failure
}
