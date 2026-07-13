import FirebaseCore
import FirebaseRemoteConfig
import Foundation
import OSLog

nonisolated enum RemoteConfiguration {
    private static let remoteConfig = RemoteConfig.remoteConfig()

    static var isImageAnalysisEnabled: Bool {
        remoteConfig.configValue(forKey: "ai_enabled").boolValue
    }

    static var isSearchAIEnabled: Bool {
        remoteConfig.configValue(forKey: "search_ai_enabled").boolValue
    }

    static var primaryModelName: String {
        string(for: "primary_model_version", fallback: "gemini-3.1-flash-lite")
    }

    static var reviewModelName: String {
        string(for: "review_model_version", fallback: "gemini-3.5-flash")
    }

    static var searchModelName: String {
        string(for: "search_model_version", fallback: "gemini-3.1-flash-lite")
    }

    static var analysisTimeout: TimeInterval {
        boundedTimeout(for: "analysis_timeout", fallback: 12)
    }

    static var reviewTimeout: TimeInterval {
        boundedTimeout(for: "review_timeout", fallback: 8)
    }

    static var searchTimeout: TimeInterval {
        boundedTimeout(for: "search_timeout", fallback: 8)
    }

    static func configureIfPossible() {
        guard FirebaseApp.app() != nil else { return }

        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        settings.fetchTimeout = 10
        remoteConfig.configSettings = settings

        remoteConfig.activate { _, error in
            if let error {
                Logger.remoteConfiguration.warning("기존 Remote Config 활성화 실패: \(String(describing: error), privacy: .private)")
            }
        }

        remoteConfig.fetch { status, error in
            guard status == .success else {
                if let error {
                    Logger.remoteConfiguration.warning("Remote Config 가져오기 실패: \(String(describing: error), privacy: .private)")
                }
                return
            }
            remoteConfig.activate { _, activationError in
                if let activationError {
                    Logger.remoteConfiguration.warning("Remote Config 갱신 활성화 실패: \(String(describing: activationError), privacy: .private)")
                }
            }
        }
    }

    private static func string(for key: String, fallback: String) -> String {
        let value = remoteConfig.configValue(forKey: key).stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? fallback : value
    }

    private static func boundedTimeout(for key: String, fallback: TimeInterval) -> TimeInterval {
        let value = remoteConfig.configValue(forKey: key).numberValue.doubleValue
        guard value > 0 else { return fallback }
        return min(30, max(5, value))
    }
}

nonisolated private extension Logger {
    static let remoteConfiguration = Logger(subsystem: "com.hyeonkyu.odbr", category: "RemoteConfiguration")
}
