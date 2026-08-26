
import SwiftUI

private enum UIFadeConstants {
    static let startLocation: CGFloat = 0.85
    static let endLocation: CGFloat = 1.0
}

struct FadingTrailingEdge: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: UIFadeConstants.startLocation),
                        .init(color: .clear, location: UIFadeConstants.endLocation)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
}

extension View {
    func fadingTrailingEdge() -> some View {
        self.modifier(FadingTrailingEdge())
    }
}
