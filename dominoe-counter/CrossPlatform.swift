//
// Created by James Stapleton on 2019-01-27.
// Copyright (c) 2019 James Stapleton. All rights reserved.
//

import Cocoa

typealias UIImage = NSImage

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

extension NSBitmapImageRep.FileType {
    var pathExtension: String {
        switch self {
        case .bmp:
            return "bmp"
        case .gif:
            return "gif"
        case .jpeg:
            return "jpg"
        case .jpeg2000:
            return "jp2"
        case .png:
            return "png"
        case .tiff:
            return "tif"
        }
    }
}

extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)

        return cgImage(forProposedRect: &proposedRect,
                context: nil,
                hints: nil)
    }
    
    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    func save(as fileName: String, fileType: NSBitmapImageRep.FileType = .png, at directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> Bool {
        guard let tiffRepresentation = tiffRepresentation, directory.isDirectory, !fileName.isEmpty else { return false }
        do {
            let outputFile = directory.appendingPathComponent(fileName).appendingPathExtension(fileType.pathExtension)

            if FileManager.default.fileExists(atPath: outputFile.path) {
                do {
                    try FileManager.default.removeItem(at: outputFile)
                    print("Removed old image")
                } catch let removeError {
                    print("couldn't remove file at path", removeError)
                }
            }

            try NSBitmapImageRep(data: tiffRepresentation)?
                    .representation(using: fileType, properties: [:])?
                    .write(to: outputFile)
            print("Saved image at \(outputFile)")
            return true
        } catch {
            print(error)
            return false
        }
    }
}
