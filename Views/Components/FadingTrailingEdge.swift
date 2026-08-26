
import SwiftUI


struct FadingTrailingEdge: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: Constants.Layout.fadeStartLocation),
                        .init(color: .clear, location: Constants.Layout.fadeEndLocation)
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
