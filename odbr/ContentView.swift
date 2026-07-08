import SwiftUI

enum AppTab: Hashable {
    case scan
    case guide
    case nephron

    var title: String {
        switch self {
        case .scan:
            "스캔"
        case .guide:
            "배출가이드"
        case .nephron:
            "네프론"
        }
    }

    var systemImage: String {
        switch self {
        case .scan:
            "camera.fill"
        case .guide:
            "list.bullet"
        case .nephron:
            "mappin.and.ellipse"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .scan

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanView(selectedTab: $selectedTab)
                .tabItem {
                    Label(AppTab.scan.title, systemImage: AppTab.scan.systemImage)
                }
                .tag(AppTab.scan)

            GuideView()
                .tabItem {
                    Label(AppTab.guide.title, systemImage: AppTab.guide.systemImage)
                }
                .tag(AppTab.guide)

            NephronView()
                .tabItem {
                    Label(AppTab.nephron.title, systemImage: AppTab.nephron.systemImage)
                }
                .tag(AppTab.nephron)
        }
        .tint(AppTheme.accent)
    }
}

#Preview {
    ContentView()
}
