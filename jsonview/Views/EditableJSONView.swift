import SwiftUI

struct EditableJSONView: View {
    @Binding var rawJSON: String
    @Binding var nodes: [JSONNode]
    @Binding var displayNodes: [JSONNode]
    @Binding var errorMessage: String?
    @Binding var navigateToPath: [String]?
    @Binding var currentCursorPath: [String]
    @Binding var hasUnsavedChanges: Bool
    @Binding var characterCount: Int
    
    @State private var isValid = true
    @State private var debounceTask: Task<Void, Never>?
    @State private var isFormatted = true
    
    var body: some View {
        VStack(spacing: 0) {
            statusBar
            Divider()
            editorView
        }
        .onAppear { characterCount = rawJSON.count }
    }
    
    private var statusBar: some View {
        HStack {
            validationIndicator
            Spacer()
            formatButtons
            Spacer()
        }
        .padding(.horizontal)
        .frame(height: 33)
    }
    
    private var validationIndicator: some View {
        HStack {
            Circle()
                .fill(isValid ? .green : .red)
                .frame(width: 8, height: 8)
            Text(isValid ? "Valid JSON" : "Invalid JSON")
                .font(.caption)
                .foregroundStyle(isValid ? Color.secondary : Color.red)
        }
    }
    
    private var formatButtons: some View {
        HStack(spacing: 2) {
            formatButton(title: "Formatted", isActive: isFormatted, action: prettyPrint)
            formatButton(title: "Compact", isActive: !isFormatted, action: minify)
        }
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(4)
    }
    
    private func formatButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .background(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .disabled(rawJSON.isEmpty)
    }
    
    private var editorView: some View {
        SyntaxHighlightingTextView(
            text: $rawJSON,
            isValid: $isValid,
            navigateToPath: $navigateToPath,
            currentCursorPath: $currentCursorPath,
            onTextChange: handleTextChange
        )
    }
    
    private func handleTextChange(_ newText: String) {
        characterCount = newText.count
        hasUnsavedChanges = true
        debounceValidation(newText)
    }
    
    private func prettyPrint() {
        guard let data = rawJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              var prettyString = String(data: prettyData, encoding: .utf8) else { return }
        prettyString = prettyString.replacingOccurrences(of: " : ", with: ": ")
        rawJSON = prettyString
        isFormatted = true
    }
    
    private func minify() {
        guard let data = rawJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              let minData = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]),
              let minString = String(data: minData, encoding: .utf8) else { return }
        rawJSON = minString
        isFormatted = false
    }
    
    private func debounceValidation(_ text: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !Task.isCancelled {
                await MainActor.run { validateAndSync(text) }
            }
        }
    }
    
    private func validateAndSync(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            isValid = false
            errorMessage = "Invalid text encoding"
            return
        }
        
        do {
            nodes = try JSONParser.parse(data)
            displayNodes = nodes
            isValid = true
            errorMessage = nil
        } catch {
            isValid = false
            errorMessage = "Invalid JSON: \(error.localizedDescription)"
        }
    }
}
