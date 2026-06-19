import XCTest
@testable import OpenGlasses

/// Tests `SafetyReportPDF` produces a valid, non-empty PDF from a `SafetyReport`. Headless (UIKit PDF
/// rendering works on the simulator).
@MainActor
final class SafetyReportPDFTests: XCTestCase {

    func testGeneratesValidPDFData() throws {
        let report = try SafetyReport.from(json: [
            "summary": "Unshored trench beside a suspended load.",
            "assessments": [
                ["category": "excavation", "is_present": true, "has_indirect_control": true, "indirect_control": "tape"],
                ["category": "suspended_load", "is_present": true, "has_direct_control": true, "direct_control": "rigging"]
            ]
        ])
        let data = SafetyReportPDF.data(for: report)
        XCTAssertGreaterThan(data.count, 500)
        XCTAssertEqual(data.prefix(4), Data("%PDF".utf8))   // valid PDF header
    }

    func testWriteProducesFile() throws {
        let report = try SafetyReport.from(json: ["summary": "Clear site.", "assessments": []])
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("heca-pdf-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = try SafetyReportPDF.write(report, to: dir)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(url.pathExtension, "pdf")
    }
}
