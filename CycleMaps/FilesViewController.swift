//
//  FilesViewController.swift
//  CycleMaps
//
//  Created by Paul Pfeiffer on 07/03/17.
//  Copyright © 2017 Paul Pfeiffer. All rights reserved.
//

import UIKit

protocol FilesViewControllerDelegate: class {
    func selectedFile(name: String, url: URL)
    func deselectedFile(name: String)
    func isSelected(name: String) -> Bool
}

class FilesViewController: UITableViewController, UIDocumentMenuDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    weak var delegate: FilesViewControllerDelegate?
    let fileStore = FileStore(withExtensions: ["gpx"])

    private func handleReceivedGpxUrl(urls: [URL]) {
        for url in urls {
            fileStore.add(url: url)
        }
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
//            navigationItem.largeTitleDisplayMode = .always
        }
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let url = appDelegate.importUrl {
                self.handleReceivedGpxUrl(urls: [url])
                appDelegate.importUrl = nil
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return fileStore.files.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: Constants.Storyboard.gpxCellReuseIdentifier, for: indexPath)
            if indexPath.row < fileStore.files.count { // just to be safe
                let url = fileStore.files[indexPath.row]
                if let size = url.fileSize {
                    cell.detailTextLabel?.text = ByteCountFormatter.string(fromByteCount: Int64(size.intValue), countStyle: ByteCountFormatter.CountStyle.file)
                }
                cell.textLabel?.text = url.lastPathComponent
                cell.accessoryType = .none
                if delegate!.isSelected(name: url.lastPathComponent) {
                    cell.accessoryType = .checkmark
                }
            }
            return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url = fileStore.files[indexPath.row]
        if delegate!.isSelected(name: url.lastPathComponent) {
            delegate?.deselectedFile(name: url.lastPathComponent)
        } else { delegate?.selectedFile(name: url.lastPathComponent, url: url ) }
//        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let url = fileStore.files[indexPath.row]
        delegate?.deselectedFile(name: url.lastPathComponent)
        tableView.reloadData()
        print("deselect")
    }

    @IBAction func importPressed(_ sender: UIBarButtonItem) {
        let importMenu = UIDocumentMenuViewController(documentTypes: ["com.apple.dt.document.gpx", "public.xml"], in: .import)
        importMenu.popoverPresentationController?.barButtonItem = importButton
        importMenu.delegate = self
        present(importMenu, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let url = fileStore.files[indexPath.row]
            fileStore.remove(url: url)
            tableView.deleteRows(at: [indexPath as IndexPath], with: .fade)
        }
    }
    @IBOutlet weak var importButton: UIBarButtonItem!

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        handleReceivedGpxUrl(urls: [url])
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        handleReceivedGpxUrl(urls: urls)
    }

    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
}
