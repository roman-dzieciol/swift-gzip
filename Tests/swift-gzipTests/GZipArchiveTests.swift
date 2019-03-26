import XCTest
@testable import swift_gzip

@available(OSX 10.11, *)
final class GZipArchiveTests: XCTestCase {

    func testDecoding() throws {
        do {
            let url = testResourcesURL().appendingPathComponent("action.xcactivitylog")
            let data = try Data(contentsOf: url)
            let archive = GZipArchive(from: data)
            let _ = try archive.decompress()
        } catch {
            print("\(error)")
            throw error
        }
    }

    static var allTests = [
        ("testDecoding", testDecoding),
    ]
}
