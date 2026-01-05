import SwiftUI
internal import UniformTypeIdentifiers

struct ContentView: View {
    @State private var nodes: [JSONNode] = []
    @State private var displayNodes: [JSONNode] = []
    @State private var rawJSON = ""
    @State private var errorMessage: String?
    @State private var fileName = "Untitled"
    @State private var fileURL: URL? = nil
    @State private var searchText = ""
    @State private var navigateToPath: [String]? = nil
    @State private var currentCursorPath: [String] = []
    @State private var hasUnsavedChanges = false
    @State private var characterCount = 0
    
    @Binding var appearanceMode: AppearanceMode
    
    var body: some View {
        mainContent
            .toolbar { toolbarContent }
            .navigationTitle(fileName)
            .background(windowAccessor)
            .safeAreaInset(edge: .bottom, spacing: 0) { footerBar }
            .onReceive(NotificationCenter.default.publisher(for: .newFile)) { _ in newFile() }
            .onReceive(NotificationCenter.default.publisher(for: .openFile)) { _ in openFile() }
            .onReceive(NotificationCenter.default.publisher(for: .openFileURL)) { notification in
                if let url = notification.object as? URL { loadFile(url) }
            }
            .onDrop(of: [.fileURL], isTargeted: nil) { handleDrop($0) }
    }
    
    private var windowAccessor: some View {
        WindowAccessor(
            fileURL: fileURL,
            fileName: hasUnsavedChanges ? "\(fileName) — Edited" : fileName,
            hasUnsavedChanges: hasUnsavedChanges
        )
    }
    
    private var mainContent: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                leftPanel
                    .frame(width: geometry.size.width * 0.28)
                
                Divider()
                
                rightPanel
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let error = errorMessage {
                ErrorBanner(message: error)
            }
            searchBar
            Divider()
            treeContent
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Filter keys...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(height: 33)
    }
    
    @ViewBuilder
    private var treeContent: some View {
        if displayNodes.isEmpty && errorMessage == nil {
            EmptyStateView()
        } else {
            TreeView(
                nodes: displayNodes,
                searchText: searchText,
                highlightedPath: currentCursorPath,
                onNodeTap: { path in navigateToPath = path }
            )
        }
    }
    
    private var rightPanel: some View {
        EditableJSONView(
            rawJSON: $rawJSON,
            nodes: $nodes,
            displayNodes: $displayNodes,
            errorMessage: $errorMessage,
            navigateToPath: $navigateToPath,
            currentCursorPath: $currentCursorPath,
            hasUnsavedChanges: $hasUnsavedChanges,
            characterCount: $characterCount
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button(action: newFile) {
                Label("New", systemImage: "doc.badge.plus")
            }
            Button(action: openFile) {
                Label("Open", systemImage: "doc")
            }
            Button(action: saveFile) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .disabled(rawJSON.isEmpty)
        }
        ToolbarItem(placement: .automatic) {
            Spacer()
        }
        ToolbarItemGroup(placement: .automatic) {
            Button(action: { appearanceMode = appearanceMode.toggled() }) {
                Label(appearanceMode.isLight ? "Dark Mode" : "Light Mode", systemImage: appearanceMode.icon)
            }
            .help(appearanceMode.isLight ? "Switch to Dark Mode" : "Switch to Light Mode")
        }
    }
    
    private var footerBar: some View {
        HStack {
            Text(fileURL?.path ?? "Not saved")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text("\(characterCount) characters")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }
    
    private func newFile() {
        rawJSON = "{}"
        fileName = "Untitled"
        fileURL = nil
        errorMessage = nil
        hasUnsavedChanges = false
        if let data = rawJSON.data(using: .utf8) {
            nodes = (try? JSONParser.parse(data)) ?? []
            displayNodes = nodes
        }
    }
    
    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            loadFile(url)
        }
    }
    
    private func loadFile(_ url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
            var prettyString = String(data: prettyData, encoding: .utf8) ?? ""
            prettyString = prettyString.replacingOccurrences(of: " : ", with: ": ")
            rawJSON = prettyString
            nodes = try JSONParser.parse(data)
            displayNodes = nodes
            fileName = url.lastPathComponent
            fileURL = url
            errorMessage = nil
            hasUnsavedChanges = false
            characterCount = rawJSON.count
        } catch {
            errorMessage = "Failed to parse JSON: \(error.localizedDescription)"
            nodes = []
            displayNodes = []
        }
    }
    
    private func saveFile() {
        if let url = fileURL {
            do {
                try rawJSON.write(to: url, atomically: true, encoding: .utf8)
                hasUnsavedChanges = false
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = fileName.hasSuffix(".json") ? fileName : "\(fileName).json"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try rawJSON.write(to: url, atomically: true, encoding: .utf8)
                fileURL = url
                fileName = url.lastPathComponent
                hasUnsavedChanges = false
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: "public.file-url") { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            
            DispatchQueue.main.async {
                loadFile(url)
            }
        }
        return true
    }
}
