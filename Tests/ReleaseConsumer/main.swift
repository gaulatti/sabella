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

#if os(tvOS)
private struct RepresentativeSabellaTVView: View {
    @State private var page = SabellaTVChannelBrowserPage.home
    @State private var focusedGroupID: String?
    @State private var selection = "news"
    @State private var guideVisible = false

    private let groups = [
        SabellaTVChannelGroupSummary(
            id: "live",
            name: "Live",
            channelCount: 1
        ),
    ]

    private let channels = [
        SabellaTVChannel(
            id: "news",
            streamURL: URL(string: "https://example.com/live.m3u8")!,
            number: "1",
            name: "News",
            now: "Live bulletin",
            progress: 0.5,
            medium: .television
        ),
    ]

    var body: some View {
        VStack {
            SabellaTVChannelHome(
                productName: "Release Consumer",
                state: .ready(groups),
                page: $page,
                focusedGroupID: $focusedGroupID,
                userName: "Viewer",
                userDetail: "Authorized remote consumer",
                userActions: [],
                retry: {},
                selectUserAction: { _ in },
                select: { _ in }
            )
            SabellaTVLivePlayer(
                channels: channels,
                selection: $selection,
                guideVisible: $guideVisible,
                onPlaybackActivityChanged: { _ in },
                onExit: {}
            )
        }
    }
}
#endif

@main
private enum ReleaseConsumer {
    @MainActor
    static func main() {
#if os(tvOS)
        _ = RepresentativeSabellaTVView()
#else
        _ = RepresentativeSabellaView()
#endif
        print("Sabella release consumer APIs loaded")
    }
}
