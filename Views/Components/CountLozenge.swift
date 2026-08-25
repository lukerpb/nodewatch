import SwiftUI

struct CountLozenge: View {
    let text: String
    var icon: String? = nil
    let colour: Color
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
            }
            Text(text)
        }
        .font(.system(.caption, design: .monospaced))
        .bold()
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(colour.opacity(0.2))
        .foregroundStyle(colour)
        .cornerRadius(6)
    }
}
