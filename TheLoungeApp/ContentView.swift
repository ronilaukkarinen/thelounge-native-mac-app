import SwiftUI

struct ContentView: View {
    // Standard macOS titlebar height
    private let titlebarHeight: CGFloat = 28

    var body: some View {
        WebView(url: URL(string: "https://irc.pulina.fi")!)
            .padding(.top, titlebarHeight)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
