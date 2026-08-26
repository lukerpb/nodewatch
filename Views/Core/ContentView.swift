import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var viewModel = NodewatchViewModel()
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        TabView {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "server.rack")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
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
