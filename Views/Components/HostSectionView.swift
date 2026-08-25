import SwiftUI

struct HostSectionView: View {
    let group: ServiceGroup
    @State private var isExpanded: Bool = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            TrafficLightBuilder(items: [
                (group.items.filter { $0.state == .ok }.count, .green),
                (group.items.filter { $0.state == .critical }.count, .red),
                (group.items.filter { $0.state == .warning }.count, .yellow),
                (group.items.filter { $0.state == .unknown }.count, .orange),
                (group.items.filter { $0.state == .pending }.count, .blue)
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
                if let hostState = group.hostState {
                    CountLozenge(text: hostState.rawValue, color: hostState.colour)
                }
            }
        }
    }
}
