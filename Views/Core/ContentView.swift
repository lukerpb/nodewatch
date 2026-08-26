import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel = NodewatchViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        TabView {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: Constants.Icons.dashboardTab)
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: Constants.Icons.settingsTab)
                }
        }
        .task {
            notificationManager.requestPermission()
        }
    }
}

#Preview {
    ContentView()
}
