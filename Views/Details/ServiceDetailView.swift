import SwiftUI

struct ServiceDetailView: View {
    let service: NodeService
    
    var body: some View {
        List {
            Section(header: Text("Service Details")) {
                LabeledContent("Host", value: service.host)
                LabeledContent("Service", value: service.serviceName)
                
                LabeledContent {
                    Text(service.state.rawValue)
                        .foregroundStyle(service.state.colour)
                        .bold()
                } label: {
                    Text("Status")
                }
            }
            
            Section(header: Text("Plugin Output")) {
                Text(service.output)
                    .font(.system(.body, design: .monospaced))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .navigationTitle(service.serviceName)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
