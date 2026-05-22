import SwiftUI
import UIKit

struct ContentView: View {
    @State private var jsonText: String = sampleJSON
    @State private var statusMessage: String = ""
    @State private var statusColor: Color = .secondary
    @State private var indentSize: Int = 2
    @State private var showingShareSheet = false
    @FocusState private var editorFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                toolbar
                Divider()
                editor
                Divider()
                statusBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("JSON Editor")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Menu {
                        Button("サンプル読込", action: loadSample)
                        Button("全消去", role: .destructive, action: clearAll)
                    } label: {
                        Image(systemName: "doc.text")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(jsonText.isEmpty)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [jsonText])
            }
        }
        .navigationViewStyle(.stack)
    }

    private var toolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ToolButton(title: "整形", systemImage: "text.alignleft", action: format)
                ToolButton(title: "圧縮", systemImage: "arrow.down.right.and.arrow.up.left", action: minify)
                ToolButton(title: "検証", systemImage: "checkmark.seal", action: validate)
                ToolButton(title: "コピー", systemImage: "doc.on.doc", action: copyToPasteboard)
                ToolButton(title: "貼付", systemImage: "doc.on.clipboard", action: pasteFromPasteboard)

                Divider().frame(height: 24)

                Menu {
                    Picker("インデント", selection: $indentSize) {
                        Text("2 スペース").tag(2)
                        Text("4 スペース").tag(4)
                        Text("タブ").tag(0)
                    }
                } label: {
                    Label("インデント \(indentLabel)", systemImage: "arrow.right.to.line")
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var indentLabel: String { indentSize == 0 ? "タブ" : "\(indentSize)" }

    private var editor: some View {
        TextEditor(text: $jsonText)
            .focused($editorFocused)
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .padding(8)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("{") { insert("{") }
                    Button("}") { insert("}") }
                    Button("[") { insert("[") }
                    Button("]") { insert("]") }
                    Button("\"") { insert("\"") }
                    Button(":") { insert(":") }
                    Button(",") { insert(",") }
                    Spacer()
                    Button("完了") { editorFocused = false }
                }
            }
    }

    private var statusBar: some View {
        HStack {
            Text(statusMessage.isEmpty ? statsLine : statusMessage)
                .font(.footnote)
                .foregroundColor(statusMessage.isEmpty ? .secondary : statusColor)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
    }

    private var statsLine: String {
        let bytes = jsonText.utf8.count
        let lines = jsonText.isEmpty ? 0 : jsonText.split(separator: "\n", omittingEmptySubsequences: false).count
        return "\(lines) 行 / \(bytes) バイト"
    }

    // MARK: - Actions

    private func format() {
        guard !jsonText.isEmpty else { setStatus("空です", color: .secondary); return }
        do {
            let data = Data(jsonText.utf8)
            let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed, .mutableContainers])
            let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let pretty = try JSONSerialization.data(withJSONObject: obj, options: options)
            var result = String(decoding: pretty, as: UTF8.self)
            if indentSize != 0 && indentSize != 4 {
                result = reindent(result, spaces: indentSize)
            } else if indentSize == 0 {
                result = reindentWithTabs(result)
            }
            jsonText = result
            setStatus("整形完了", color: .green)
        } catch {
            setStatus("エラー: \(humanize(error))", color: .red)
        }
    }

    private func minify() {
        guard !jsonText.isEmpty else { setStatus("空です", color: .secondary); return }
        do {
            let data = Data(jsonText.utf8)
            let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            let minified = try JSONSerialization.data(withJSONObject: obj, options: [.withoutEscapingSlashes])
            jsonText = String(decoding: minified, as: UTF8.self)
            setStatus("圧縮完了 (\(jsonText.utf8.count) バイト)", color: .green)
        } catch {
            setStatus("エラー: \(humanize(error))", color: .red)
        }
    }

    private func validate() {
        guard !jsonText.isEmpty else { setStatus("空です", color: .secondary); return }
        do {
            _ = try JSONSerialization.jsonObject(with: Data(jsonText.utf8), options: [.fragmentsAllowed])
            setStatus("✓ 有効な JSON", color: .green)
        } catch {
            setStatus("✗ 無効: \(humanize(error))", color: .red)
        }
    }

    private func copyToPasteboard() {
        UIPasteboard.general.string = jsonText
        setStatus("コピーしました", color: .blue)
    }

    private func pasteFromPasteboard() {
        if let s = UIPasteboard.general.string {
            jsonText = s
            setStatus("貼り付けました", color: .blue)
        } else {
            setStatus("クリップボードが空です", color: .secondary)
        }
    }

    private func loadSample() {
        jsonText = sampleJSON
        setStatus("サンプル読込", color: .blue)
    }

    private func clearAll() {
        jsonText = ""
        setStatus("全消去", color: .secondary)
    }

    private func insert(_ s: String) { jsonText.append(s) }

    private func setStatus(_ message: String, color: Color) {
        statusMessage = message
        statusColor = color
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            if statusMessage == message { statusMessage = "" }
        }
    }

    private func humanize(_ error: Error) -> String {
        let ns = error as NSError
        if let debug = ns.userInfo["NSDebugDescription"] as? String { return debug }
        return ns.localizedDescription
    }

    private func reindent(_ text: String, spaces: Int) -> String {
        let unit = String(repeating: " ", count: spaces)
        return text.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
            var count = 0
            for ch in line { if ch == " " { count += 1 } else { break } }
            let levels = count / 2
            return String(repeating: unit, count: levels) + line.dropFirst(count)
        }.joined(separator: "\n")
    }

    private func reindentWithTabs(_ text: String) -> String {
        return text.split(separator: "\n", omittingEmptySubsequences: false).map { line -> String in
            var count = 0
            for ch in line { if ch == " " { count += 1 } else { break } }
            let levels = count / 2
            return String(repeating: "\t", count: levels) + line.dropFirst(count)
        }.joined(separator: "\n")
    }
}

struct ToolButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

private let sampleJSON = """
{
  "name": "JSON Editor",
  "version": "1.0.0",
  "features": ["format", "minify", "validate"],
  "config": {
    "indent": 2,
    "sortKeys": true,
    "escapeSlashes": false
  },
  "active": true,
  "count": 42
}
"""
