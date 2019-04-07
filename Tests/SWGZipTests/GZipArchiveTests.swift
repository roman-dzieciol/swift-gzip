import XCTest
@testable import SWGZip

final class GZipArchiveTests: XCTestCase {

    func testUnpackXCActivityLog() throws {
        do {
            let url = testResourcesURL().appendingPathComponent("action.xcactivitylog")
            let data = try Data(contentsOf: url)
            let archive = try GZipArchive(from: data)
            let _ = try archive.decompress()
        } catch {
            print("\(error)")
            throw error
        }
    }

    func testUnpackPython3() throws {
        do {
            let url = testResourcesURL().appendingPathComponent("python3 test.gz")
            let data = try Data(contentsOf: url)
            let archive = try GZipArchive(from: data)
            let _ = try archive.decompress()
        } catch {
            print("\(error)")
            throw error
        }
    }

    func testUnpackSystem() throws {
        do {
            let inputString = "test"
            let inputData = inputString.data(using: .utf8)!
            let inputGZipData = try gzip(data: inputData, decompress: false)
            let archive = try GZipArchive(from: inputGZipData)
            let outputData = try archive.decompress()
            let outputString = String(data: outputData, encoding: .utf8)!
            XCTAssertEqual(inputString, outputString)
        } catch {
            print("\(error)")
            throw error
        }
    }

    func testSystemUnpack() throws {
        do {
            let inputString = "test"
            let inputData = inputString.data(using: .utf8)!
            let archive = try GZipArchive(with: inputData)
            let inputGZipData = try archive.compress()
            dump(inputGZipData)
            let outputData = try gzip(data: inputGZipData, decompress: true)
            let outputString = String(data: outputData, encoding: .utf8)!
            XCTAssertEqual(inputString, outputString)
        } catch {
            print("\(error)")
            throw error
        }
    }

    static var allTests = [
        ("testUnpackXCActivityLog", testUnpackXCActivityLog),
        ("testUnpackPython3", testUnpackPython3),
        ("testUnpackSystem", testUnpackSystem),
        ("testSystemUnpack", testSystemUnpack),
    ]
}
