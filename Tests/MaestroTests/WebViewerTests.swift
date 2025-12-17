import XCTest
@testable import Maestro

/// Web Viewer Tests
/// Tests that the web viewer HTML/CSS/JS files exist and are properly structured
final class WebViewerTests: XCTestCase {

    func testWebViewerFilesExist() throws {
        let resourcesPath = FileManager.default.currentDirectoryPath + "/Resources/WebViewer"

        // Check HTML file exists
        let htmlPath = resourcesPath + "/index.html"
        XCTAssertTrue(FileManager.default.fileExists(atPath: htmlPath), "index.html should exist")

        // Check CSS file exists
        let cssPath = resourcesPath + "/style.css"
        XCTAssertTrue(FileManager.default.fileExists(atPath: cssPath), "style.css should exist")

        // Check JS file exists
        let jsPath = resourcesPath + "/script.js"
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsPath), "script.js should exist")
    }

    func testWebViewerLoadsAndDisplaysData() throws {
        let resourcesPath = FileManager.default.currentDirectoryPath + "/Resources/WebViewer"
        let htmlPath = resourcesPath + "/index.html"

        let htmlContent = try String(contentsOfFile: htmlPath, encoding: .utf8)

        // Verify essential HTML structure
        XCTAssertTrue(htmlContent.contains("Maestro"), "HTML should contain title")
        XCTAssertTrue(htmlContent.contains("spaces-list"), "HTML should have spaces container")
        XCTAssertTrue(htmlContent.contains("tasks-list"), "HTML should have tasks container")
        XCTAssertTrue(htmlContent.contains("documents-list"), "HTML should have documents container")

        // Verify CSS and JS are linked
        XCTAssertTrue(htmlContent.contains("style.css"), "HTML should link to CSS")
        XCTAssertTrue(htmlContent.contains("script.js"), "HTML should link to JS")
    }

    func testWebViewerJavaScriptStructure() throws {
        let resourcesPath = FileManager.default.currentDirectoryPath + "/Resources/WebViewer"
        let jsPath = resourcesPath + "/script.js"

        let jsContent = try String(contentsOfFile: jsPath, encoding: .utf8)

        // Verify essential JavaScript functions exist
        XCTAssertTrue(jsContent.contains("MaestroDashboard"), "JS should define MaestroDashboard class")
        XCTAssertTrue(jsContent.contains("loadSpaces"), "JS should have loadSpaces method")
        XCTAssertTrue(jsContent.contains("loadTasks"), "JS should have loadTasks method")
        XCTAssertTrue(jsContent.contains("loadDocuments"), "JS should have loadDocuments method")
        XCTAssertTrue(jsContent.contains("renderSpaces"), "JS should have renderSpaces method")
        XCTAssertTrue(jsContent.contains("renderTasks"), "JS should have renderTasks method")
        XCTAssertTrue(jsContent.contains("renderDocuments"), "JS should have renderDocuments method")
        XCTAssertTrue(jsContent.contains("startAutoRefresh"), "JS should have auto-refresh functionality")
    }

    func testWebViewerCSSStructure() throws {
        let resourcesPath = FileManager.default.currentDirectoryPath + "/Resources/WebViewer"
        let cssPath = resourcesPath + "/style.css"

        let cssContent = try String(contentsOfFile: cssPath, encoding: .utf8)

        // Verify essential CSS classes exist
        XCTAssertTrue(cssContent.contains(".space-card"), "CSS should style space cards")
        XCTAssertTrue(cssContent.contains(".task-card"), "CSS should style task cards")
        XCTAssertTrue(cssContent.contains(".document-card"), "CSS should style document cards")
        XCTAssertTrue(cssContent.contains(".panel"), "CSS should style panels")
        XCTAssertTrue(cssContent.contains(".loading"), "CSS should style loading state")
    }
}
