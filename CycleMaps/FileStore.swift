//
//  filemanager.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 07/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import Foundation

protocol FileStoreDelegate: class {
    func reload()
}

class FileStore : NSObject, NSFilePresenter {

    static let sharedInstance = FileStore() // Singleton
    weak var delegate: FileStoreDelegate?
    let settings = UserDefaults.standard
    let query = NSMetadataQuery()
    var fileManager = FileManager()
    var extensions = [String]()
    var files: [URL] = []
    private var docRootDir: URL = DocumentsDirectory.localDocumentsURL!
    lazy var presentedItemOperationQueue = OperationQueue.main
    var presentedItemURL: URL?

    override init() {
        super.init()
        docRootDir = getDocumentDirectoryURL()
        presentedItemURL = docRootDir
        print(docRootDir)
        extensions = ["gpx"]
        reloadFiles()
        //moveFileToCloud(withClear: false)
        startQuery()
        NSFileCoordinator.addFilePresenter(self)
    }
    


    func presentedSubitemDidChange(at url: URL) {
        let pathExtension = url.pathExtension

        if extensions.contains(pathExtension) {
            startQuery()
            reloadFiles()
        }
    }
    

    func reloadFiles() {
        do {
            let contents =
                try fileManager.contentsOfDirectory(at: docRootDir,
                                                    includingPropertiesForKeys: [URLResourceKey.creationDateKey,
                                                                                 URLResourceKey.localizedNameKey,
                                                                                 URLResourceKey.fileSizeKey],
                                                    options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            files = contents.filter({ extensions.contains($0.pathExtension) })
            files.sort(by: {$0.lastPathComponent.lowercased() < $1.lastPathComponent.lowercased()})
            if delegate != nil { delegate?.reload()}
        } catch {print(error)}
    }

    func startQuery() {
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope, NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope]
        query.predicate = NSPredicate(format: "%K.URLByDeletingLastPathComponent.path == %@", argumentArray: [NSMetadataItemURLKey, docRootDir.path])
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.metadataQueryDidUpdate(_:)),
                                               name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                                               object: self.query)
        query.start()
        query.enableUpdates()
    }

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

    private struct DocumentsDirectory {
        static let localDocumentsURL: URL? =
            FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                     in: .userDomainMask).last!
        static let iCloudDocumentsURL: URL? =
            FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
    }

    private func getDocumentDirectoryURL() -> URL {
        if !settings.bool(forKey: Constants.Settings.iCloudDisabled)  && isCloudEnabled() {
            return DocumentsDirectory.iCloudDocumentsURL!
        } else {
            return DocumentsDirectory.localDocumentsURL!
        }
    }

    // Return true if iCloud is enabled
    private func isCloudEnabled() -> Bool {
        if DocumentsDirectory.iCloudDocumentsURL != nil {
            return true
        } else {
            return false
        }
    }

    // Delete All files at URL

    private func deleteFilesInDirectory(url: URL?) {
        let enumerator = fileManager.enumerator(atPath: url!.path)
        while let file = enumerator?.nextObject() as? String {
            do {
                try fileManager.removeItem(at: url!.appendingPathComponent(file))
                print("Files deleted")
            } catch let error as NSError {
                print("Failed deleting files : \(error)")
            }
        }
    }

    func moveFileToCloud(withClear: Bool) {
        if isCloudEnabled() {
            //            if withClear { deleteFilesInDirectory(url: DocumentsDirectory.iCloudDocumentsURL!) } // Clear destination
            let enumerator = fileManager.enumerator(atPath: DocumentsDirectory.localDocumentsURL!.path)
            while let file = enumerator?.nextObject() as? String {
                do {
                    try fileManager.setUbiquitous(true,
                                                  itemAt: DocumentsDirectory.localDocumentsURL!.appendingPathComponent(file),
                                                  destinationURL: DocumentsDirectory.iCloudDocumentsURL!.appendingPathComponent(file))
                    print("Moved to iCloud")
                } catch let error as NSError {
                    print("Failed to move file to Cloud : \(error)")
                }
            }
            docRootDir = getDocumentDirectoryURL()
            reloadFiles()
        }
    }

    func moveFileToLocal() {
        if isCloudEnabled() {
//            deleteFilesInDirectory(url: DocumentsDirectory.localDocumentsURL!)
            let enumerator = fileManager.enumerator(atPath: DocumentsDirectory.iCloudDocumentsURL!.path)
            while let file = enumerator?.nextObject() as? String {
                do {
                    // Copy, don't remove to keep files available for other devices
                    try fileManager.copyItem(at: DocumentsDirectory.iCloudDocumentsURL!.appendingPathComponent(file),
                                             to: DocumentsDirectory.localDocumentsURL!.appendingPathComponent(file))
//                    try fileManager.setUbiquitous(false,
//                                                  itemAt: DocumentsDirectory.iCloudDocumentsURL!.appendingPathComponent(file),
//                                                  destinationURL: DocumentsDirectory.localDocumentsURL!.appendingPathComponent(file))
                    print("Copied to local dir")
                } catch let error as NSError {
                    print("Failed to move file to local dir : \(error)")
                }
            }
            docRootDir = getDocumentDirectoryURL()
            reloadFiles()
        }
    }

    @objc private func metadataQueryDidUpdate(_ notification: Notification) {
        for file in (query.results as? [NSMetadataItem?])! {
            if let fileURL = file!.value(forAttribute: NSMetadataItemURLKey) as? NSURL {
                try? fileManager.startDownloadingUbiquitousItem(at: fileURL as URL)
                print(fileURL)
            }
        }
        reloadFiles()
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
        } catch { print(error) }
        return nil
    }

    var fileSize: NSNumber? {
        var val: AnyObject?
        do {
            val = try self.resourceValues(forKeys: [.fileSizeKey]) as AnyObject?
            if let size = val as? NSNumber {
                return size
            }
        } catch { print(error) }
        return nil
    }
}
