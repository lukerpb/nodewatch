import Foundation

struct ServerConfig: Codable, Equatable, Identifiable {
    var id = UUID()
    var name: String = Constants.Defaults.instanceName
    var url: String = ""
    var port: String = ""
    var hostGroups: String = ""
    var lastError: String? = nil
    
    var fullUrl: String {
        let cleanPort = port.trimmingCharacters(in: .whitespaces)
        let finalPort = cleanPort.isEmpty ? Constants.Defaults.port : cleanPort
        return "\(url):\(finalPort)/webhook/nodewatch-services"
    }
}

enum TestState {
    case idle
    case testing
    case success
    case failure
}
