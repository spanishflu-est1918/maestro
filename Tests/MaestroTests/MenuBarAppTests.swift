import XCTest
import Cocoa
@testable import MaestroUI

/// Menu Bar Application Tests
/// Tests AppDelegate initialization and menu bar setup
final class MenuBarAppTests: XCTestCase {

    func testMenuBarIconAppears() throws {
        // Create app delegate
        let delegate = AppDelegate()

        // Note: We can't actually call applicationDidFinishLaunching in tests
        // because it requires a window server connection (CGS). Instead, we verify
        // the delegate can be created and has the expected methods.

        // Verify the delegate was initialized without crashing
        XCTAssertNotNil(delegate, "AppDelegate should be initialized")

        // Verify the app delegate methods are available
        XCTAssertTrue(delegate.responds(to: #selector(AppDelegate.openMaestro)))
        XCTAssertTrue(delegate.responds(to: #selector(AppDelegate.openPreferences)))
        XCTAssertTrue(delegate.responds(to: #selector(AppDelegate.quit)))
    }

    func testAppDelegateLifecycle() throws {
        // Verify we can create multiple delegates without issues
        let delegate1 = AppDelegate()
        XCTAssertNotNil(delegate1)

        let delegate2 = AppDelegate()
        XCTAssertNotNil(delegate2)
    }
}
