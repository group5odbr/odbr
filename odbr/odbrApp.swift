//
//  odbrApp.swift
//  odbr
//
//  Created by 이현규 on 7/7/26.
//

import FirebaseAppCheck
import FirebaseCore
import OSLog
import SwiftUI

@main
struct odbrApp: App {
    init() {
        FirebaseBootstrap.configureIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private enum FirebaseBootstrap {
    private static let logger = Logger(subsystem: "com.hyeonkyu.odbr", category: "FirebaseBootstrap")

    static func configureIfPossible() {
        guard FirebaseApp.app() == nil else {
            logger.debug("Firebase was already configured")
            return
        }

        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: path)
        else {
            logger.error("GoogleService-Info.plist is missing or invalid; Firebase AI is disabled")
            return
        }

        logger.info("Loaded Firebase options from the app bundle")

        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(ODBRAppCheckProviderFactory())
        #endif
        FirebaseApp.configure(options: options)
        logger.info("Firebase configured for the iOS app")
    }
}

private final class ODBRAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        AppAttestProvider(app: app)
    }
}
