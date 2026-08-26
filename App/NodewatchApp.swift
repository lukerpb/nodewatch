import SwiftUI
import BackgroundTasks

@main
struct NodewatchApp: App {
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                scheduleAppRefresh()
            }
        }
        .backgroundTask(.appRefresh("com.nodewatch.refresh")) {
            await performBackgroundUpdate()
        }
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.nodewatch.refresh")
        
        request.earliestBeginDate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error.localizedDescription)")
        }
    }
    
    private func performBackgroundUpdate() async {
        guard let data = UserDefaults.standard.data(forKey: Constants.Storage.serverConfigKey),
              let config = try? JSONDecoder().decode(ServerConfig.self, from: data),
              !config.url.isEmpty else {
            return
        }
        
        let tempViewModel = NodewatchViewModel()
        
        tempViewModel.hostGroupsFilter = config.hostGroups
        
        await tempViewModel.fetchLiveData(from: config.fullUrl)
        
        scheduleAppRefresh()
    }
}
