import SwiftUI

struct HostSectionView: View {
    let group: HostGroup
    var isSearching: Bool
    @State private var isExpanded: Bool = false
    @ObservedObject private var prefs = NotificationPreferences.shared
    
    var body: some View {
        let expandedBinding = Binding(
            get: { isSearching || isExpanded },
            set: { isExpanded = $0 }
        )
        
        DisclosureGroup(isExpanded: expandedBinding) {
            TrafficLightBuilder(items: [
                (group.items.filter { $0.state == .ok }.count, .green, "OK", NodeService.ServiceState.ok.icon),
                (group.items.filter { $0.state == .critical }.count, .red, "CRITICAL", NodeService.ServiceState.critical.icon),
                (group.items.filter { $0.state == .warning }.count, .yellow, "WARNING", NodeService.ServiceState.warning.icon),
                (group.items.filter { $0.state == .unknown }.count, .orange, "UNKNOWN", NodeService.ServiceState.unknown.icon),
                (group.items.filter { $0.state == .pending }.count, .blue, "PENDING", NodeService.ServiceState.pending.icon)
            ])
            .listRowSeparator(.hidden)
            .padding(.leading, Constants.Layout.hostTrafficLightLeadingPad)
            .padding(.vertical, Constants.Layout.hostTrafficLightVerticalPad)
            
            ForEach(group.items) { service in
                NavigationLink(value: service) {
                    ServiceRowView(service: service)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    let isSilenced = prefs.silencedServices[group.name]?.contains(service.serviceName) ?? false
                    Button {
                        prefs.toggleService(host: group.name, service: service.serviceName)
                    } label: {
                        Label(isSilenced ? "Unmute" : "Mute", systemImage: isSilenced ? Constants.Icons.bell : Constants.Icons.bellMuted)
                    }
                    .tint(isSilenced ? .blue : .orange)
                }
            }
        } label: {
            HStack {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .fadingTrailingEdge()
                
                let status = prefs.status(for: group.name, totalServices: group.items.count)
                if status != .none {
                    let isFull = status == .full
                    let isPartial = status == .partial
                    
                    let labelText = isFull ? "Full" : (isPartial ? "Partial" : "Host Only")
                    let colour: Color = (isFull || isPartial) ? .cyan : .gray
                    let isOutline = !isFull
                    
                    CountLozenge(
                        text: labelText,
                        icon: Constants.Icons.bell,
                        colour: colour,
                        isOutline: isOutline
                    )
                }
                
                CountLozenge(
                    text: group.state.rawValue.uppercased(),
                    icon: group.state.icon,
                    colour: group.state.colour
                )
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                let isOptedIn = prefs.optedInHosts.contains(group.name)
                Button {
                    prefs.toggleHost(group.name)
                } label: {
                    Label(isOptedIn ? "Disable Alerts" : "Enable Alerts", systemImage: isOptedIn ? Constants.Icons.bellMuted : Constants.Icons.bell)
                }
                .tint(isOptedIn ? .red : .blue)
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}

