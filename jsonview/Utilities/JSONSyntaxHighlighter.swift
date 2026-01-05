import AppKit

class JSONSyntaxHighlighter {
    static let stringColor = NSColor.systemGreen
    static let numberColor = NSColor.systemBlue
    static let boolColor = NSColor.systemOrange
    static let nullColor = NSColor.systemGray
    static let keyColor = NSColor.systemPurple
    static let bracketColor = NSColor.systemBrown
    static let colonCommaColor = NSColor.secondaryLabelColor
    
    static func highlight(_ text: String, font: NSFont) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        attributed.addAttribute(.font, value: font, range: fullRange)
        attributed.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
        
        let patterns: [(String, NSColor)] = [
            ("\"(?:[^\"\\\\]|\\\\.)*\"", stringColor),
            ("-?(?:0|[1-9]\\d*)(?:\\.\\d+)?(?:[eE][+-]?\\d+)?(?=[,\\]\\}\\s]|$)", numberColor),
            ("\\b(true|false)\\b", boolColor),
            ("\\bnull\\b", nullColor),
            ("[\\[\\]\\{\\}]", bracketColor),
            ("[,:]", colonCommaColor),
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let matches = regex.matches(in: text, range: fullRange)
                for match in matches {
                    attributed.addAttribute(.foregroundColor, value: color, range: match.range)
                }
            }
        }
        
        if let keyRegex = try? NSRegularExpression(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"(?=\\s*:)") {
            let matches = keyRegex.matches(in: text, range: fullRange)
            for match in matches {
                attributed.addAttribute(.foregroundColor, value: keyColor, range: match.range)
            }
        }
        
        return attributed
    }
}
