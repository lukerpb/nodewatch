import SwiftUI

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
        .background(isOutline ? Color.clear : colour.opacity(Constants.Layout.lozengeBackgroundOpacity))
        .overlay(
            RoundedRectangle(cornerRadius: Constants.Layout.lozengeCornerRadius)
                .stroke(colour, lineWidth: isOutline ? Constants.Layout.lozengeOutlineWidth : 0)
        )
        .foregroundStyle(colour)
        .cornerRadius(Constants.Layout.lozengeCornerRadius)
    }
}
