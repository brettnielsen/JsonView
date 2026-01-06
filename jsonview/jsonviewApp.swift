import SwiftUI

@main
struct JSONEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    var body: some Scene {
        // Menu bar item
        MenuBarExtra {
            Button("Open JSON Editor") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut("o")
            
            Divider()
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: "curlybraces")
        }
        
        // Main window
        WindowGroup {
            ContentView(appearanceMode: $appearanceMode)
                .preferredColorScheme(appearanceMode.colorScheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    NotificationCenter.default.post(name: .newFile, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Open...") {
                    NotificationCenter.default.post(name: .openFile, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            NotificationCenter.default.post(name: .openFileURL, object: url)
        }
    }
}

extension Notification.Name {
    static let newFile = Notification.Name("newFile")
    static let openFile = Notification.Name("openFile")
    static let openFileURL = Notification.Name("openFileURL")
}
