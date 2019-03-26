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
}

