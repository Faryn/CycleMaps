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

class FilesViewController: UITableViewController,
UIDocumentPickerDelegate, UINavigationControllerDelegate, FileStoreDelegate {

    weak var delegate: FilesViewControllerDelegate?
    let fileStore = FileStore.sharedInstance
    let generator = UISelectionFeedbackGenerator()

    private func handleReceivedGpxUrl(urls: [URL]) {
        for url in urls {
            fileStore.add(url: url)
        }
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .always
        }
        fileStore.delegate = self
        initiateImport()
        fileStore.reloadFiles()
        generator.prepare()
    }

    func initiateImport() {
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
        let cell =  tableView.dequeueReusableCell(withIdentifier:
                Constants.Storyboard.gpxCellReuseIdentifier, for: indexPath)
            if indexPath.row < fileStore.files.count { // just to be safe
                let url = fileStore.files[indexPath.row]
                cell.textLabel?.text = url.lastPathComponent
                if delegate!.isSelected(name: url.lastPathComponent) {
                    cell.textLabel?.textColor = UIColor.blue
                }
            }
            return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let url = fileStore.files[indexPath.row]
        generator.selectionChanged()
        generator.prepare()
        if delegate!.isSelected(name: url.lastPathComponent) {
            delegate?.deselectedFile(name: url.lastPathComponent)
            cell?.textLabel?.textColor = UIColor.black
        } else {
            delegate?.selectedFile(name: url.lastPathComponent, url: url )
            cell?.textLabel?.textColor = UIColor.blue
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        generator.selectionChanged()
        generator.prepare()
        let url = fileStore.files[indexPath.row]
        delegate?.deselectedFile(name: url.lastPathComponent)
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        performSegue(withIdentifier: "fileDetailSegue", sender: indexPath)
    }

    @IBAction func importPressed(_ sender: UIBarButtonItem) {
        let importMenu = UIDocumentPickerViewController(documentTypes: ["com.apple.dt.document.gpx", "public.xml"], in: .import)
        importMenu.popoverPresentationController?.barButtonItem = importButton
        importMenu.delegate = self
        present(importMenu, animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let url = fileStore.files[indexPath.row]
//            tableView.deleteRows(at: [indexPath as IndexPath], with: .fade) //Crashes the tableview because the update from file deletion is quicker
            fileStore.remove(url: url)
        }
    }
    @IBOutlet weak var importButton: UIBarButtonItem!

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        handleReceivedGpxUrl(urls: [url])
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        handleReceivedGpxUrl(urls: urls)
    }

    func reload() {
        tableView.reloadData()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "fileDetailSegue" {
            if let fileDetailViewController = segue.destination as? FileDetailViewController {
                if let indexPath = sender as? IndexPath {
                    fileDetailViewController.fileUrl = fileStore.files[indexPath.row]
                }
            }
        }
    }
}
