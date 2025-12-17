import XCTest
import Cocoa
@testable import MaestroUI

/// Native Viewer Window Tests
/// Tests WKWebView wrapper and window management
final class ViewerWindowTests: XCTestCase {

    func testNativeWindowManagement() throws {
        // Create viewer window
        let viewer = ViewerWindow()

        // Verify window was created
        XCTAssertNotNil(viewer.window, "Window should be created")

        // Verify window properties
        let window = try XCTUnwrap(viewer.window)
        XCTAssertEqual(window.title, "Maestro")
        XCTAssertTrue(window.styleMask.contains(.titled))
        XCTAssertTrue(window.styleMask.contains(.closable))
        XCTAssertTrue(window.styleMask.contains(.resizable))
    }

    func testWindowFramePersistence() throws {
        // Clear any saved frame
        UserDefaults.standard.removeObject(forKey: "MaestroViewerWindowFrame")

        // Create first window
        let viewer1 = ViewerWindow()
        let window1 = try XCTUnwrap(viewer1.window)

        // Get initial frame
        let initialFrame = window1.frame

        // Save frame
        let frameDescriptor = window1.frameDescriptor
        UserDefaults.standard.set(frameDescriptor, forKey: "MaestroViewerWindowFrame")

        // Create second window - should restore frame
        let viewer2 = ViewerWindow()
        let window2 = try XCTUnwrap(viewer2.window)

        // Verify frame was restored
        XCTAssertEqual(window2.frame.origin.x, initialFrame.origin.x, accuracy: 1.0)
        XCTAssertEqual(window2.frame.origin.y, initialFrame.origin.y, accuracy: 1.0)
        XCTAssertEqual(window2.frame.size.width, initialFrame.size.width, accuracy: 1.0)
        XCTAssertEqual(window2.frame.size.height, initialFrame.size.height, accuracy: 1.0)

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "MaestroViewerWindowFrame")
    }

    func testLoadHTML() throws {
        let viewer = ViewerWindow()

        // Verify we can load HTML string
        XCTAssertNoThrow(viewer.loadHTML("<html><body>Test</body></html>"))
    }
}
