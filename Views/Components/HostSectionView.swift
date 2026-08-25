import SwiftUI

struct HostSectionView: View {
    let group: HostGroup
    @State private var isExpanded: Bool = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            // NEW: Added icons to the nested builder
            TrafficLightBuilder(items: [
                (group.items.filter { $0.state == .ok }.count, .green, "OK", NodeService.ServiceState.ok.icon),
                (group.items.filter { $0.state == .critical }.count, .red, "CRITICAL", NodeService.ServiceState.critical.icon),
                (group.items.filter { $0.state == .warning }.count, .yellow, "WARNING", NodeService.ServiceState.warning.icon),
                (group.items.filter { $0.state == .unknown }.count, .orange, "UNKNOWN", NodeService.ServiceState.unknown.icon),
                (group.items.filter { $0.state == .pending }.count, .blue, "PENDING", NodeService.ServiceState.pending.icon)
            ])
            .listRowSeparator(.hidden)
            .padding(.leading, -16)
            .padding(.top, 4)
            .padding(.bottom, 4)
            
            ForEach(group.items) { service in
                NavigationLink(value: service) {
                    ServiceRowView(service: service)
                }
            }
        } label: {
            HStack {
                Text(group.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                CountLozenge(
                    text: group.state.rawValue.uppercased(),
                    icon: group.state.icon,
                    colour: group.state.colour
                )
            }
        }
    }
}
