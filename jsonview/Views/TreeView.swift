import SwiftUI

struct TreeView: View {
    let nodes: [JSONNode]
    let searchText: String
    let highlightedPath: [String]
    var onNodeTap: ([String]) -> Void
    
    @State private var expandedNodes: Set<String> = []
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(nodes) { node in
                    RecursiveNodeView(
                        node: node,
                        searchText: searchText,
                        highlightedPath: highlightedPath,
                        expandedNodes: $expandedNodes,
                        onNodeTap: onNodeTap
                    )
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color(NSColor.controlBackgroundColor))
            .onChange(of: highlightedPath) { _, newPath in
                expandParentNodes(for: newPath)
                scrollToNode(newPath, proxy: proxy)
            }
        }
    }
    
    private func expandParentNodes(for path: [String]) {
        var currentPath: [String] = []
        for component in path.dropLast() {
            currentPath.append(component)
            expandedNodes.insert(currentPath.joined(separator: "."))
        }
    }
    
    private func scrollToNode(_ path: [String], proxy: ScrollViewProxy) {
        if !path.isEmpty {
            let pathString = path.joined(separator: ".")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(pathString, anchor: .center)
                }
            }
        }
    }
}

struct RecursiveNodeView: View {
    let node: JSONNode
    let searchText: String
    let highlightedPath: [String]
    @Binding var expandedNodes: Set<String>
    var onNodeTap: ([String]) -> Void
    
    private var isExpanded: Bool {
        expandedNodes.contains(node.pathString)
    }
    
    private var isHighlighted: Bool {
        node.path == highlightedPath
    }
    
    private var shouldShow: Bool {
        searchText.isEmpty || nodeMatches(node)
    }
    
    var body: some View {
        if shouldShow {
            nodeContent
        }
    }
    
    @ViewBuilder
    private var nodeContent: some View {
        if node.children.isEmpty {
            leafNode
        } else {
            parentNode
        }
    }
    
    private var leafNode: some View {
        NodeRow(node: node, isHighlighted: isHighlighted)
            .id(node.pathString)
            .contentShape(Rectangle())
            .onTapGesture { onNodeTap(node.path) }
    }
    
    private var parentNode: some View {
        DisclosureGroup(isExpanded: expansionBinding) {
            childNodes
        } label: {
            nodeLabel
        }
    }
    
    private var expansionBinding: Binding<Bool> {
        Binding(
            get: { isExpanded },
            set: { newValue in
                if newValue {
                    expandedNodes.insert(node.pathString)
                } else {
                    expandedNodes.remove(node.pathString)
                }
            }
        )
    }
    
    private var childNodes: some View {
        ForEach(node.children) { child in
            RecursiveNodeView(
                node: child,
                searchText: searchText,
                highlightedPath: highlightedPath,
                expandedNodes: $expandedNodes,
                onNodeTap: onNodeTap
            )
        }
    }
    
    private var nodeLabel: some View {
        NodeRow(node: node, isHighlighted: isHighlighted)
            .id(node.pathString)
            .contentShape(Rectangle())
            .onTapGesture { onNodeTap(node.path) }
    }
    
    private func nodeMatches(_ node: JSONNode) -> Bool {
        if let key = node.key, key.localizedCaseInsensitiveContains(searchText) {
            return true
        }
        return node.children.contains { nodeMatches($0) }
    }
}

struct NodeRow: View {
    let node: JSONNode
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: node.icon)
                .foregroundStyle(node.valueColor)
                .frame(width: 16)
            keyText
            valueText
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(highlightBackground)
    }
    
    @ViewBuilder
    private var keyText: some View {
        if let key = node.key {
            Text(key)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }
    
    @ViewBuilder
    private var valueText: some View {
        if !node.children.isEmpty {
            Text(node.displayValue)
                .foregroundStyle(.secondary)
                .font(.caption)
        } else {
            Text(node.displayValue)
                .foregroundStyle(node.valueColor)
        }
    }
    
    private var highlightBackground: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isHighlighted ? Color.accentColor.opacity(0.2) : Color.clear)
    }
}
