import SwiftUI

struct ServiceRowView: View {
    let service: NodeService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(service.serviceName)
                    .font(.headline)
                Text(service.host)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(service.state.rawValue)
                .font(.caption)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(service.state.colour.opacity(0.2))
                .foregroundStyle(service.state.colour)
                .cornerRadius(6)
        }
    }
}
