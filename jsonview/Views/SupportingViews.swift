import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Open a JSON file to get started")
                .font(.headline)
                .foregroundStyle(.primary)
            Text("Use ⌘O or drag and drop a file")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.yellow)
            Text(message)
                .font(.caption)
            Spacer()
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
    }
}

struct WindowAccessor: NSViewRepresentable {
    let fileURL: URL?
    let fileName: String
    let hasUnsavedChanges: Bool
    
    func makeNSView(context: Context) -> NSView {
        NSView()
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.isDocumentEdited = hasUnsavedChanges
            if let url = fileURL {
                window.representedURL = url
                window.standardWindowButton(.documentIconButton)?.isHidden = false
            } else {
                window.representedURL = nil
                window.title = fileName
            }
        }
    }
}
