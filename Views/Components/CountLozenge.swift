import SwiftUI

private enum LozengeStyle {
    static let backgroundOpacity: Double = 0.2
    static let cornerRadius: CGFloat = 6.0
    static let outlineWidth: CGFloat = 1.5
}

struct CountLozenge: View {
    let text: String
    var icon: String? = nil
    let colour: Color
    var isOutline: Bool = false
    
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
        .background(isOutline ? Color.clear : colour.opacity(LozengeStyle.backgroundOpacity))
        .overlay(
            RoundedRectangle(cornerRadius: LozengeStyle.cornerRadius)
                .stroke(colour, lineWidth: isOutline ? LozengeStyle.outlineWidth : 0)
        )
        .foregroundStyle(colour)
        .cornerRadius(LozengeStyle.cornerRadius)
    }
}
