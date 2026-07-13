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
    @State private var selectedTab: AppTab

    init() {
        _selectedTab = State(initialValue: AppTab.initialTab)
    }

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
        .accessibilityIdentifier("app.tabs")
    }
}

private extension AppTab {
    static var initialTab: AppTab {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard
            let flagIndex = arguments.firstIndex(of: "-initialTab"),
            arguments.indices.contains(flagIndex + 1)
        else {
            return .scan
        }

        switch arguments[flagIndex + 1] {
        case "guide":
            return .guide
        case "nephron":
            return .nephron
        default:
            return .scan
        }
        #else
        return .scan
        #endif
    }
}

#Preview {
    ContentView()
}
