import SwiftUI

@main
struct AlarmVKApp: App {
    @State var fal = false
    var body: some Scene {
        WindowGroup {
            NavigationView {
                AlarmListView(bridge: $fal)
            }
            .accentColor(.primary)
        }
    }
}
