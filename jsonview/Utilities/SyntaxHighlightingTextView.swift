import SwiftUI

struct SyntaxHighlightingTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var isValid: Bool
    @Binding var navigateToPath: [String]?
    @Binding var currentCursorPath: [String]
    var onTextChange: (String) -> Void
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.backgroundColor = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.delegate = context.coordinator
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        if let path = navigateToPath {
            DispatchQueue.main.async {
                context.coordinator.navigateToPath(path, in: textView)
                self.navigateToPath = nil
            }
        }
        
        if textView.string != text && !context.coordinator.isEditing {
            let selectedRanges = textView.selectedRanges
            context.coordinator.isUpdating = true
            
            let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            let highlighted = JSONSyntaxHighlighter.highlight(text, font: font)
            
            textView.textStorage?.setAttributedString(highlighted)
            textView.selectedRanges = selectedRanges
            
            context.coordinator.isUpdating = false
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SyntaxHighlightingTextView
        var isUpdating = false
        var isEditing = false
        var highlightTask: DispatchWorkItem?
        var cursorUpdateTask: DispatchWorkItem?
        weak var textView: NSTextView?
        
        init(_ parent: SyntaxHighlightingTextView) {
            self.parent = parent
        }
        
        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }
        
        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }
        
        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            
            let newText = textView.string
            parent.text = newText
            parent.onTextChange(newText)
            
            highlightTask?.cancel()
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.applyHighlighting(to: textView)
                }
            }
            highlightTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: task)
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            cursorUpdateTask?.cancel()
            let task = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.updateCursorPath(in: textView)
                }
            }
            cursorUpdateTask = task
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: task)
        }
        
        private func updateCursorPath(in textView: NSTextView) {
            let cursorPosition = textView.selectedRange().location
            let text = textView.string
            let path = findPathAtPosition(cursorPosition, in: text)
            if path != parent.currentCursorPath {
                parent.currentCursorPath = path
            }
        }
        
        private func findPathAtPosition(_ position: Int, in text: String) -> [String] {
            guard position <= text.count else { return ["root"] }
            
            let chars = Array(text)
            var path: [String] = ["root"]
            var stack: [(type: Character, objectKey: String?, arrayIndex: Int)] = []
            var i = 0
            var inString = false
            var stringStart = 0
            var pendingKey: String? = nil
            var lastStringValue: String? = nil
            
            while i < chars.count {
                let char = chars[i]
                let atCursor = i >= position
                
                if inString {
                    if char == "\"" {
                        var backslashCount = 0
                        var j = i - 1
                        while j >= 0 && chars[j] == "\\" {
                            backslashCount += 1
                            j -= 1
                        }
                        
                        if backslashCount % 2 == 0 {
                            inString = false
                            let stringContent = String(chars[stringStart..<i])
                            
                            if position >= stringStart - 1 && position <= i {
                                var lookAhead = i + 1
                                while lookAhead < chars.count && chars[lookAhead].isWhitespace {
                                    lookAhead += 1
                                }
                                let isKey = lookAhead < chars.count && chars[lookAhead] == ":"
                                
                                if isKey {
                                    return path + [stringContent]
                                } else {
                                    if let key = pendingKey {
                                        return path + [key]
                                    } else if let last = stack.last, last.type == "[" {
                                        return path + ["[\(last.arrayIndex)]"]
                                    }
                                    return path
                                }
                            }
                            lastStringValue = stringContent
                        }
                    }
                } else {
                    switch char {
                    case "\"":
                        inString = true
                        stringStart = i + 1
                        
                    case ":":
                        pendingKey = lastStringValue
                        lastStringValue = nil
                        
                    case "{":
                        if atCursor {
                            if let key = pendingKey {
                                return path + [key]
                            } else if let last = stack.last, last.type == "[" {
                                return path + ["[\(last.arrayIndex)]"]
                            }
                            return path
                        }
                        if let key = pendingKey {
                            path.append(key)
                            stack.append((type: "{", objectKey: key, arrayIndex: -1))
                            pendingKey = nil
                        } else if let last = stack.last, last.type == "[" {
                            let idx = "[\(last.arrayIndex)]"
                            path.append(idx)
                            stack.append((type: "{", objectKey: nil, arrayIndex: -1))
                        } else {
                            stack.append((type: "{", objectKey: nil, arrayIndex: -1))
                        }
                        lastStringValue = nil
                        
                    case "}":
                        if atCursor { return path }
                        if !stack.isEmpty && stack.last?.type == "{" {
                            let popped = stack.removeLast()
                            if popped.objectKey != nil || (stack.last?.type == "[") {
                                if !path.isEmpty && path.count > 1 {
                                    path.removeLast()
                                }
                            }
                        }
                        pendingKey = nil
                        lastStringValue = nil
                        
                    case "[":
                        if atCursor {
                            if let key = pendingKey {
                                return path + [key]
                            } else if let last = stack.last, last.type == "[" {
                                return path + ["[\(last.arrayIndex)]"]
                            }
                            return path
                        }
                        if let key = pendingKey {
                            path.append(key)
                            stack.append((type: "[", objectKey: key, arrayIndex: 0))
                            pendingKey = nil
                        } else if let last = stack.last, last.type == "[" {
                            let idx = "[\(last.arrayIndex)]"
                            path.append(idx)
                            stack.append((type: "[", objectKey: nil, arrayIndex: 0))
                        } else {
                            stack.append((type: "[", objectKey: nil, arrayIndex: 0))
                        }
                        lastStringValue = nil
                        
                    case "]":
                        if atCursor { return path }
                        if !stack.isEmpty && stack.last?.type == "[" {
                            stack.removeLast()
                            if !path.isEmpty && path.count > 1 {
                                path.removeLast()
                            }
                        }
                        pendingKey = nil
                        lastStringValue = nil
                        
                    case ",":
                        if atCursor {
                            if let key = pendingKey {
                                return path + [key]
                            }
                            return path
                        }
                        if let last = stack.last, last.type == "[" {
                            stack[stack.count - 1].arrayIndex += 1
                        }
                        pendingKey = nil
                        lastStringValue = nil
                        
                    case " ", "\t", "\n", "\r":
                        if atCursor {
                            if let key = pendingKey {
                                return path + [key]
                            } else if let last = stack.last, last.type == "[" {
                                return path + ["[\(last.arrayIndex)]"]
                            }
                            return path
                        }
                        
                    default:
                        if atCursor {
                            if let key = pendingKey {
                                return path + [key]
                            } else if let last = stack.last, last.type == "[" {
                                return path + ["[\(last.arrayIndex)]"]
                            }
                            return path
                        }
                    }
                }
                i += 1
            }
            
            if let key = pendingKey {
                return path + [key]
            }
            return path
        }
        
        private func applyHighlighting(to textView: NSTextView) {
            guard !isUpdating else { return }
            isUpdating = true
            
            let selectedRanges = textView.selectedRanges
            let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
            let highlighted = JSONSyntaxHighlighter.highlight(textView.string, font: font)
            
            textView.textStorage?.setAttributedString(highlighted)
            textView.selectedRanges = selectedRanges
            
            isUpdating = false
        }
        
        func navigateToPath(_ path: [String], in textView: NSTextView) {
            let text = textView.string
            guard !path.isEmpty else { return }
            
            let searchPath = path.first == "root" ? Array(path.dropFirst()) : path
            guard let targetKey = searchPath.last else {
                textView.setSelectedRange(NSRange(location: 0, length: 0))
                textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
                return
            }
            
            if let range = findKeyRange(targetKey, in: text, path: searchPath) {
                textView.setSelectedRange(range)
                textView.scrollRangeToVisible(range)
                textView.showFindIndicator(for: range)
            }
        }
        
        private func findKeyRange(_ key: String, in text: String, path: [String]) -> NSRange? {
            let nsText = text as NSString
            
            if key.hasPrefix("[") && key.hasSuffix("]") {
                let indexStr = String(key.dropFirst().dropLast())
                guard let index = Int(indexStr) else { return nil }
                
                if path.count >= 2 {
                    let parentKey = path[path.count - 2]
                    if !parentKey.hasPrefix("[") {
                        let parentPattern = "\"\(NSRegularExpression.escapedPattern(for: parentKey))\"\\s*:\\s*\\["
                        if let parentRegex = try? NSRegularExpression(pattern: parentPattern),
                           let parentMatch = parentRegex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) {
                            let arrayStart = parentMatch.range.location + parentMatch.range.length
                            var elementCount = 0
                            var searchPos = arrayStart
                            var braceDepth = 0
                            var bracketDepth = 1
                            var inString = false
                            var elementStart = arrayStart
                            
                            while searchPos < nsText.length && bracketDepth > 0 {
                                let char = nsText.character(at: searchPos)
                                let c = Character(UnicodeScalar(char)!)
                                
                                if inString {
                                    if c == "\"" && (searchPos == 0 || nsText.character(at: searchPos - 1) != Character("\\").asciiValue!) {
                                        inString = false
                                    }
                                } else {
                                    switch c {
                                    case "\"": inString = true
                                    case "{": braceDepth += 1
                                    case "}": braceDepth -= 1
                                    case "[": bracketDepth += 1
                                    case "]": bracketDepth -= 1
                                    case ",":
                                        if braceDepth == 0 && bracketDepth == 1 {
                                            if elementCount == index {
                                                return NSRange(location: elementStart, length: searchPos - elementStart)
                                            }
                                            elementCount += 1
                                            elementStart = searchPos + 1
                                        }
                                    default: break
                                    }
                                }
                                searchPos += 1
                            }
                            
                            if elementCount == index && bracketDepth == 0 {
                                return NSRange(location: elementStart, length: searchPos - elementStart - 1)
                            }
                        }
                    }
                }
                return nil
            }
            
            let pattern = "\"\(NSRegularExpression.escapedPattern(for: key))\""
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            
            if matches.count == 1 {
                return matches[0].range
            }
            
            if let firstMatch = matches.first {
                return firstMatch.range
            }
            
            return nil
        }
    }
}
