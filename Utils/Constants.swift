import SwiftUI

enum Constants {
    enum Storage {
        static let serverConfigKey = "serverConfigData"
    }
    
    enum Defaults {
        static let instanceName = "My Nagios Instance"
        static let port = "5678"
    }
    
    enum Network {
        static let fetchTimeout: TimeInterval = 10
        static let testRequestTimeout: TimeInterval = 5.0
        static let webhookPath = "/webhook/nodewatch-services"
    }
    
    enum URLs {
        static let setupGuide = URL(string: "https://github.com/lukerpb/Nodewatch/wiki/Setup-Guide")
    }
    
    enum UI {
        static let animationDuration: Double = 0.3
        static let testSpinnerDelay: UInt64 = 750_000_000 // 0.75 seconds
        static let testResultHoldDuration: UInt64 = 2_000_000_000 // 2 seconds
    }

    enum AppState {
        static let searchClearThreshold: TimeInterval = 60.0
        static let autoRefreshInterval: Int = 60
    }
}
