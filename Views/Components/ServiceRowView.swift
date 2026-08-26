import SwiftUI

struct ServiceRowView: View {
    let service: NodeService
    @ObservedObject private var prefs = NotificationPreferences.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(service.serviceName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(service.host)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .fadingTrailingEdge()
            
            let isSilenced = prefs.silencedServices[service.host]?.contains(service.serviceName) ?? false
            if isSilenced {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.red)
                    .imageScale(.small)
                    .padding(.trailing, 2)
            }
            
            CountLozenge(
                text: service.state.rawValue.uppercased(),
                colour: service.state.colour
            )
        }
        .padding(.vertical, -2)
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
}
