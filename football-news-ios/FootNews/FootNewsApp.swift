import SwiftUI

@main
struct FootNewsApp: App {
    @StateObject private var feedManager = FeedManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(feedManager)
                .preferredColorScheme(.dark)
        }
    }
}
