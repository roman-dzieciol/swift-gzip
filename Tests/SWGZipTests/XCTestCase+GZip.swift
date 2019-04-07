//
//  XCTestCase+GZip.swift
//  swift-gzipTests
//
//  Created by Roman Dzieciol on 3/26/19.
//

import XCTest

extension XCTestCase {

    func sourceRootURL() -> URL {
        return URL(fileURLWithPath: #file, isDirectory: true)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func testResourcesURL() -> URL {
        return sourceRootURL()
            .appendingPathComponent("Tests")
            .appendingPathComponent("Resources")
    }

    func temporaryDirectoryURL() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        return url
    }

    func gzip(data: Data, decompress: Bool) throws -> Data {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = [
            "gzip",
            "--verbose",
            "--stdout"
        ]

        if decompress {
            process.arguments?.append("--decompress")
        }

        let standardInputPipe = Pipe()
        standardInputPipe.fileHandleForWriting.writeabilityHandler = { handle in

        }
        process.standardInput = standardInputPipe

        var standardOutputData = Data()
        let standardOutputPipe = Pipe()
        standardOutputPipe.fileHandleForReading.readabilityHandler = { handle in
            standardOutputData.append(handle.readDataToEndOfFile())
        }
        process.standardOutput = standardOutputPipe

        process.launch()

        standardInputPipe.fileHandleForWriting.write(data)
        standardInputPipe.fileHandleForWriting.closeFile()

        process.waitUntilExit()
        guard process.terminationStatus == EXIT_SUCCESS else {
            fatalError("Error: \(process) \(process.terminationReason)")
        }
        return standardOutputData
    }

}

