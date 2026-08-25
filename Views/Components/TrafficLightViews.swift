import SwiftUI

struct TrafficLightBuilder: View {
    let items: [(count: Int, colour: Color, label: String?, icon: String)]
    var filterText: String? = nil
    var onFilterTap: (() -> Void)? = nil
    
    let babyPink = Color(red: 1.0, green: 0.6, blue: 0.7)
    
    var body: some View {
        let visibleItems = items.filter { $0.count > 0 }
        
        HStack(spacing: 6) {
            ForEach(0..<visibleItems.count, id: \.self) { index in
                let item = visibleItems[index]
                let displayText = item.label != nil ? "\(item.count) \(item.label!)" : "\(item.count)"
                
                CountLozenge(text: displayText, icon: item.icon, colour: item.colour)
            }
            
            Spacer()
            
            if let filterText = filterText, !filterText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button(action: { onFilterTap?() }) {
                    Text("Filtering active")
                        .font(.system(.caption, design: .monospaced))
                        .bold()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(babyPink.opacity(0.2))
                        .foregroundStyle(babyPink)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
    }
}

struct ServiceTrafficLightView: View {
    @ObservedObject var viewModel: NodewatchViewModel
    var filterText: String? = nil
    var onFilterTap: (() -> Void)? = nil
    
    var body: some View {
        TrafficLightBuilder(
            items: [
                (viewModel.countOK, .green, nil, NodeService.ServiceState.ok.icon),
                (viewModel.countCritical, .red, nil, NodeService.ServiceState.critical.icon),
                (viewModel.countWarning, .yellow, nil, NodeService.ServiceState.warning.icon),
                (viewModel.countUnknown, .orange, nil, NodeService.ServiceState.unknown.icon),
                (viewModel.countPending, .blue, nil, NodeService.ServiceState.pending.icon)
            ],
            filterText: filterText,
            onFilterTap: onFilterTap
        )
    }
}

struct HostTrafficLightView: View {
    @ObservedObject var viewModel: NodewatchViewModel
    var filterText: String? = nil
    var onFilterTap: (() -> Void)? = nil
    
    var body: some View {
        TrafficLightBuilder(
            items: [
                (viewModel.countHostUp, .green, nil, NodeService.HostState.up.icon),
                (viewModel.countHostDown, .red, nil, NodeService.HostState.down.icon),
                (viewModel.countHostUnreachable, .orange, nil, NodeService.HostState.unreachable.icon),
                (viewModel.countHostPending, .blue, nil, NodeService.HostState.pending.icon)
            ],
            filterText: filterText,
            onFilterTap: onFilterTap
        )
    }
}
