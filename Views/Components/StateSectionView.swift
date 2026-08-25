import SwiftUI

struct StateSectionView: View {
    let group: ServiceGroup
    @State private var isExpanded: Bool
    
    init(group: ServiceGroup) {
        self.group = group
        _isExpanded = State(initialValue: group.items.count < 10)
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(group.items) { service in
                NavigationLink(value: service) {
                    ServiceRowView(service: service)
                }
            }
        } label: {
            HStack {
                let state = NodeService.ServiceState(rawValue: group.name)
                let stateColour = state?.colour ?? .gray
                let stateIcon = state?.icon
                
                CountLozenge(
                    text: "\(group.items.count) \(group.name.uppercased())",
                    icon: stateIcon,
                    colour: stateColour
                )
                
                Spacer()
            }
        }
    }
}
