import SwiftUI

struct HostStateSectionView: View {
    let stateGroup: HostStateGroup
    @State private var isExpanded: Bool = false
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(stateGroup.hosts) { hostGroup in
                HostSectionView(group: hostGroup)
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
    }
}
