//
//  filemanager.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 07/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation

class FileStore {
    
    init(withExtensions: [String]) {
        docRootDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        extensions = withExtensions
        reloadFiles()
    }
    
    var fileManager = FileManager()
    var extensions = [String]()
    var files: [URL] = []
    private var docRootDir :URL
    
    private func reloadFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: docRootDir as URL, includingPropertiesForKeys: [URLResourceKey.creationDateKey, URLResourceKey.localizedNameKey, URLResourceKey.fileSizeKey], options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                print(contents)
                files = contents.filter( { extensions.contains($0.pathExtension) } )
                print (files)
        }
        catch {print(error)}
    }
    
    // adds a file to the internal file storage
    func add(url: URL) {
        let name = url.lastPathComponent
        do {
            try fileManager.moveItem(at: url as URL, to: docRootDir.appendingPathComponent(name))
            print("file \(name) saved to \(docRootDir)")
            reloadFiles()
        } catch { print(error) }
    }
    
    func remove(url: URL) {
        do {
            try fileManager.removeItem(at: url as URL)
            reloadFiles()
        } catch { print(error) }
    }
    
}

extension URL {
    var created: String? {
        var val: AnyObject?
        do {
            val = try self.resourceValues(forKeys: [.creationDateKey]) as AnyObject? //(&val, forKey: )
            if let created = val as? String {
                return created
            }
        }
        catch { print(error) }
        return nil
    }
    
    var fileSize: NSNumber? {
        var val: AnyObject?
        do {
            val = try self.resourceValues(forKeys: [.fileSizeKey]) as AnyObject?
            if let size = val as? NSNumber {
                return size
            }
        }
        catch { print(error) }
        return nil
    }
}
