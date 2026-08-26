import SwiftUI
import Combine

enum HostNotificationState {
    case none, full, partial, hostOnly
}

class NotificationPreferences: ObservableObject {
    static let shared = NotificationPreferences()
    
    @Published var optedInHosts: Set<String> = [] {
        didSet { saveData() }
    }
    
    @Published var silencedServices: [String: Set<String>] = [:] {
        didSet { saveData() }
    }
    
    private let storageKey = "NodewatchNotificationPrefs"
    
    private init() { loadData() }
    
    func status(for host: String, totalServices: Int) -> HostNotificationState {
        guard optedInHosts.contains(host) else { return .none }
        let silencedCount = silencedServices[host]?.count ?? 0
        if silencedCount == 0 { return .full }
        if silencedCount >= totalServices { return .hostOnly }
        return .partial
    }
    
    func toggleHost(_ host: String) {
        if optedInHosts.contains(host) {
            optedInHosts.remove(host)
        } else {
            optedInHosts.insert(host)
        }
    }
    
    func toggleService(host: String, service: String) {
        var silenced = silencedServices[host] ?? []
        if silenced.contains(service) {
            silenced.remove(service)
        } else {
            silenced.insert(service)
        }
        
        if silenced.isEmpty {
            silencedServices.removeValue(forKey: host)
        } else {
            silencedServices[host] = silenced
        }
    }
    
    private func saveData() {
        let dict = ["hosts": Array(optedInHosts), "services": silencedServices.mapValues { Array($0) }] as [String : Any]
        if let data = try? JSONSerialization.data(withJSONObject: dict) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadData() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        
        if let hostsArr = dict["hosts"] as? [String] {
            optedInHosts = Set(hostsArr)
        }
        if let svcDict = dict["services"] as? [String: [String]] {
            silencedServices = svcDict.mapValues { Set($0) }
        }
    }
}
