import XCTest
@testable import OpenGlasses

/// Headless tests for Teleprompter Phase 4 (vision/OCR capture). The OCR step is an
/// injectable seam, so the scan → buffer → script flow is exercised without a camera or
/// Vision. The live `scanPage()` camera capture is the only device-pending part.
@MainActor
final class TeleprompterVisionTests: XCTestCase {

    private func makeService() -> TeleprompterService {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("tp-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return TeleprompterService(store: TeleprompterScriptStore(directory: dir))
    }

    func testIngestAccumulatesPages() async {
        let service = makeService()
        service.ocr = { _ in "line one of the speech" }
        _ = await service.ingestScannedImage(Data())
        XCTAssertEqual(service.scanPages, 1)
        XCTAssertTrue(service.hasScannedPages)

        service.ocr = { _ in "line two of the speech" }
        _ = await service.ingestScannedImage(Data())
        XCTAssertEqual(service.scanPages, 2)
        XCTAssertEqual(service.scanBuffer, "line one of the speech\n\nline two of the speech")
    }

    func testIngestEmptyOCRDoesNotCount() async {
        let service = makeService()
        service.ocr = { _ in "   \n  " }
        let status = await service.ingestScannedImage(Data())
        XCTAssertEqual(service.scanPages, 0)
        XCTAssertFalse(service.hasScannedPages)
        XCTAssertTrue(status.lowercased().contains("couldn't read"))
    }

    func testStartScannedScriptBuildsStartsAndClears() async {
        let service = makeService()
        service.ocr = { _ in "alpha bravo charlie\ndelta echo foxtrot" }
        _ = await service.ingestScannedImage(Data())

        XCTAssertTrue(service.startScannedScript(mode: .voice))
        XCTAssertTrue(service.isActive)
        XCTAssertEqual(service.script?.title, "alpha bravo charlie")   // derived from first line
        XCTAssertNotNil(service.currentScreen)
        XCTAssertFalse(service.hasScannedPages)                        // buffer cleared after start
        XCTAssertEqual(service.scanPages, 0)
    }

    func testStartScannedScriptEmptyReturnsFalse() {
        let service = makeService()
        XCTAssertFalse(service.startScannedScript())
        XCTAssertFalse(service.isActive)
    }

    func testSaveScannedScriptPersistsAndClears() async {
        let service = makeService()
        service.ocr = { _ in "the saved scanned script body" }
        _ = await service.ingestScannedImage(Data())

        let saved = service.saveScannedScript(title: "Captured")
        XCTAssertEqual(saved?.title, "Captured")
        XCTAssertEqual(service.store.scripts.first?.title, "Captured")
        XCTAssertFalse(service.hasScannedPages)                        // buffer cleared after save
    }

    func testClearScanResets() async {
        let service = makeService()
        service.ocr = { _ in "something" }
        _ = await service.ingestScannedImage(Data())
        XCTAssertTrue(service.hasScannedPages)
        service.clearScan()
        XCTAssertFalse(service.hasScannedPages)
        XCTAssertEqual(service.scanBuffer, "")
    }
}
