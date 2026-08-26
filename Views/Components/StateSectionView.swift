import SwiftUI

private enum LocalConfig {
    static let autoExpandThreshold = 10
}

struct StateSectionView: View {
    let group: ServiceGroup
    var isSearching: Bool // NEW
    @State private var isExpanded: Bool
    
    init(group: ServiceGroup, isSearching: Bool) {
        self.group = group
        self.isSearching = isSearching
        _isExpanded = State(initialValue: group.items.count < 10)
    }
    
    var body: some View {
        let expandedBinding = Binding(
            get: { isSearching || isExpanded },
            set: { isExpanded = $0 }
        )
        
        DisclosureGroup(isExpanded: expandedBinding) {
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
