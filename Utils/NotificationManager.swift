import Foundation
import Combine
import UserNotifications

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if let error = error {
                    print("Notification permission error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Nodewatch Alert"
        content.body = "This is a test notification to confirm the simulator is rendering them correctly!"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func processStateChanges(oldServices: [NodeService], newServices: [NodeService]) {
        guard hasPermission else { return }
        
        let oldDict = Dictionary(uniqueKeysWithValues: oldServices.map { ("\($0.host)-\($0.serviceName)", $0) })
        
        for newService in newServices {
            let key = "\(newService.host)-\(newService.serviceName)"
            let oldService = oldDict[key]
            
            let isNewlyCritical = newService.state == .critical && oldService?.state != .critical
            let isNewlyDown = newService.hostState == .down && oldService?.hostState != .down
            
            if isNewlyDown {
                dispatchAlert(
                    identifier: "down-\(key)",
                    title: "Host Down",
                    body: "\(newService.host) has gone offline."
                )
            } else if isNewlyCritical {
                dispatchAlert(
                    identifier: "crit-\(key)",
                    title: "Service Critical",
                    body: "\(newService.serviceName) on \(newService.host) is reporting a CRITICAL state."
                )
            }
        }
    }
        
    private func dispatchAlert(identifier: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to dispatch alert: \(error.localizedDescription)")
            }
        }
    }
    
    func userNotificationCenter(
        _ centre: UNUserNotificationCenter,
        willPresent notri: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
