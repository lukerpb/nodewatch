import SwiftUI

struct TrafficLightBuilder: View {
    let items: [(count: Int, color: Color)]
    
    var body: some View {
        let visibleItems = items.filter { $0.count > 0 }
        
        HStack(spacing: 8) {
            ForEach(0..<visibleItems.count, id: \.self) { index in
                CountLozenge(text: "\(visibleItems[index].count)", color: visibleItems[index].color)
                
                if index < visibleItems.count - 1 {
                    Text("|")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .offset(y: -1)
                }
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

struct ServiceTrafficLightView: View {
    @ObservedObject var viewModel: NodewatchViewModel
    var body: some View {
        TrafficLightBuilder(items: [
            (viewModel.countOK, .green),
            (viewModel.countCritical, .red),
            (viewModel.countWarning, .yellow),
            (viewModel.countUnknown, .orange),
            (viewModel.countPending, .blue)
        ])
    }
}

struct HostTrafficLightView: View {
    @ObservedObject var viewModel: NodewatchViewModel
    var body: some View {
        TrafficLightBuilder(items: [
            (viewModel.countHostUp, .green),
            (viewModel.countHostDown, .red),
            (viewModel.countHostUnreachable, .orange),
            (viewModel.countHostPending, .blue)
        ])
    }
}
