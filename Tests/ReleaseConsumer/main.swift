import Sabella
import SwiftUI

private enum Destination: Hashable {
    case home
    case settings
}

private struct RepresentativeSabellaView: View {
    @State private var destination = Destination.home
    @State private var title = ""

    var body: some View {
        BleeckerMobileAppShell(
            selection: $destination,
            tabs: [
                BleeckerAppTab(.home, label: "Home", systemImage: "house"),
                BleeckerAppTab(.settings, label: "Settings", systemImage: "gear"),
            ]
        ) {
            Text("Sabella consumer")
        } content: {
            BleeckerField("Title") {
                BleeckerTextField(placeholder: "Story title", text: $title)
            }
            Button("Save") {}
                .buttonStyle(BleeckerButtonStyle(.primary))
        }
    }
}

@main
private enum ReleaseConsumer {
    @MainActor
    static func main() {
        _ = RepresentativeSabellaView()
    }
}
