import SwiftUI

enum Constants {
    enum Storage {
        static let serverConfigKey = "serverConfigData"
        static let notificationPrefsKey = "NodewatchNotificationPrefs"
        static let lastKnownPayloadKey = "lastKnownServicesPayload"
    }
    
    enum Defaults {
        static let instanceName = "My Nagios Instance"
        static let port = "5678"
    }
    
    enum Network {
        static let fetchTimeout: TimeInterval = 10.0
        static let testRequestTimeout: TimeInterval = 5.0
        static let webhookPath = "/webhook/nodewatch-services"
    }
    
    enum URLs {
        static let setupGuide = URL(string: "https://github.com/lukerpb/Nodewatch/wiki/Setup-Guide")!
    }
    
    enum UI {
        static let animationDuration: Double = 0.3
        static let testSpinnerDelay: UInt64 = 750_000_000
        static let testResultHoldDuration: UInt64 = 2_000_000_000
    }

    enum AppState {
        static let searchClearThreshold: TimeInterval = 60.0
        static let autoRefreshInterval: Int = 60
        static let backgroundTaskIdentifier = "com.nodewatch.refresh"
    }
    
    enum Colours {
        static let filterActive = Color(red: 1.0, green: 0.6, blue: 0.7)
    }
    
    enum Layout {
        static let lozengeBackgroundOpacity: Double = 0.2
        static let lozengeCornerRadius: CGFloat = 6.0
        static let lozengeOutlineWidth: CGFloat = 1.5
        
        static let fadeStartLocation: CGFloat = 0.85
        static let fadeEndLocation: CGFloat = 1.0
        
        static let defaultListRowHeight: CGFloat = 32.0
        static let hostTrafficLightLeadingPad: CGFloat = -20.0
        static let hostTrafficLightVerticalPad: CGFloat = -16.0
    }
    
    enum Icons {
        // General UI
        static let search = "magnifyingglass"
        static let clear = "xmark.circle.fill"
        static let info = "info.circle"
        static let success = "checkmark.circle.fill"
        static let error = "xmark.circle.fill"
        
        // Tabs & Grouping
        static let dashboardTab = "server.rack"
        static let settingsTab = "gearshape"
        static let groupService = "square.stack.3d.up"
        static let groupAll = "list.bullet"
        
        // Notifications
        static let bell = "bell.fill"
        static let bellMuted = "bell.slash.fill"
        static let bellTest = "bell.badge.fill"
        
        // Service States
        static let serviceOk = "checkmark.circle.fill"
        static let serviceWarning = "exclamationmark.triangle.fill"
        static let serviceCritical = "xmark.octagon.fill"
        static let serviceUnknown = "questionmark.circle.fill"
        static let servicePending = "clock.fill"
        
        // Host States
        static let hostUp = "arrow.up.circle.fill"
        static let hostDown = "arrow.down.circle.fill"
        static let hostUnreachable = "network.slash"
    }
    
    enum Strings {
        static let filterActiveText = "Filtering active"
        static let defaultAlertTitle = "Nodewatch Alert"
        static let searchPlaceholder = "Search..."
    }
}
