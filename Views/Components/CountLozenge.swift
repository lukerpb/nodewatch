import SwiftUI

private enum LozengeStyle {
    static let backgroundOpacity: Double = 0.2
    static let cornerRadius: CGFloat = 6.0
}

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
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background(colour.opacity(LozengeStyle.backgroundOpacity))
        .foregroundStyle(colour)
        .cornerRadius(LozengeStyle.cornerRadius)
    }
}
