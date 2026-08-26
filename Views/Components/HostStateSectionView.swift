import SwiftUI

struct HostStateSectionView: View {
    let stateGroup: HostStateGroup
    var isSearching: Bool
    @State private var isExpanded: Bool = false
    
    var body: some View {
        let expandedBinding = Binding(
            get: { isSearching || isExpanded },
            set: { isExpanded = $0 }
        )
        
        DisclosureGroup(isExpanded: expandedBinding) {
            ForEach(stateGroup.hosts) { hostGroup in
                HostSectionView(group: hostGroup, isSearching: isSearching)
            }
        } label: {
            HStack {
                CountLozenge(
                    text: "\(stateGroup.hosts.count) \(stateGroup.state.rawValue.uppercased())",
                    icon: stateGroup.state.icon,
                    colour: stateGroup.state.colour
                )
                Spacer()
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}
