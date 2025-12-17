import Cocoa
import WebKit

/// Native viewer window with WKWebView
/// Displays the Maestro web dashboard
public class ViewerWindow: NSWindowController {
    private let webView: WKWebView
    private static let windowFrameKey = "MaestroViewerWindowFrame"

    public init() {
        // Configure web view
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        webView = WKWebView(frame: .zero, configuration: config)

        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Maestro"
        window.contentView = webView
        window.center()

        // Restore saved frame if available
        if let frameString = UserDefaults.standard.string(forKey: Self.windowFrameKey) {
            window.setFrame(from: frameString)
        }

        super.init(window: window)

        // Save frame when window moves or resizes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: window
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResize),
            name: NSWindow.didResizeNotification,
            object: window
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Load the web viewer
    public func loadViewer() {
        // Load from Resources/WebViewer/index.html
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Resources/WebViewer") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            NSLog("Failed to find WebViewer resources")
        }
    }

    /// Load from URL (for development)
    public func load(url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
    }

    /// Load HTML string
    public func loadHTML(_ html: String, baseURL: URL? = nil) {
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    @objc private func windowDidMove() {
        saveWindowFrame()
    }

    @objc private func windowDidResize() {
        saveWindowFrame()
    }

    private func saveWindowFrame() {
        guard let window = window else { return }
        let frameDescriptor = window.frameDescriptor
        UserDefaults.standard.set(frameDescriptor, forKey: Self.windowFrameKey)
    }
}
