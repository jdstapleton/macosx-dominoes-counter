//
//  main.swift
//  dominoe-counter
//
//  Created by James Stapleton on 2019/1/26.
//  Copyright © 2019 James Stapleton. All rights reserved.
//

import Foundation
import Cocoa

func ensureExistAsDirectory(file: URL) throws -> URL {
    if !FileManager.default.fileExists(atPath: file.path) {
        try FileManager.default.createDirectory(at: file, withIntermediateDirectories: true)
    }

    return file
}

print("Starting");

if (CommandLine.arguments.count < 2) {
    print("Usage: inputFilePath outputFileDirectory")
    exit(1)
}

let fileName = CommandLine.arguments[1];
let outdir = try ensureExistAsDirectory(file: URL(fileURLWithPath: CommandLine.arguments[2]))
let image = NSImage(contentsOfFile: fileName)!

func methodOne() {
    let settings = DominoeDectorSettings();
    let i = 3;
    let dc: DominoeDetector = DominoeDetector(uiImage: image, andSettings: settings)

    _ = dc.modifiedImage.save(as: "modified_cannyLowThreshold_\(i)", fileType: .png, at: outdir)
    _ = dc.contourImage.save(as: "contour_cannyLowThreshold_\(i)", fileType: .png, at: outdir)
    //for i: Int32 in stride(from: 0, to: 100, by: 12) {
    //    settings.cannyLowThreshold = i;
    //
    //}
}

func methodTwo() {
    let pc = PipDetector(uiImage: image)

    _ = pc.modifiedImage.save(as: "pip_modified", fileType: .png, at: outdir)
    _ = pc.contourImage.save(as: "pip_contour", fileType: .png, at: outdir)
}

methodTwo()
exit(0)
