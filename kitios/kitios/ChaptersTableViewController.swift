//
//  ChaptersTableViewController.swift
//  kitios
//
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//
//	This is the UITableViewController for the Select Chapter scene. This scene will be entered
//	after the current Book is selected and set up, and so it will have available the array of
//	Chapters for the current Book.
//
//  Created by Graeme Costin on 13/11/19.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class ChaptersTableViewController: UITableViewController {

	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	var bInst: Bible?		// Current instance of Bible
	var bkInst: Book?		// Current instance of Book
							// When ChaptersTableViewController is active the user will have selected a Book
							// and it will be the current Book
	var chapName: String?
	
	// Boolean for detecting when Back button has been pressed
	var goingForwards = false
	// Boolean for whether the let the user choose a Chapter
	var letUserChooseChapter = false
	// tableRow of the selected Chapter
	var chRow = 0	// safe value in case a Chapter has not yet been selected
	// Chapter number of the selected Chapter
	var chNum = 0	// safe value in case a Chapter has not yet been selected

	override func viewDidLoad() {
		super.viewDidLoad()
		// Get access to the array Book.BibChaps
		bInst = appDelegate.bibInst
		bkInst = bInst!.bookInst	// Get access to the instance of the current Book
		navigationItem.title = bInst!.bibName
		chapName = bkInst!.chapName
		if bkInst!.bkID == 19 {
			navigationItem.prompt = "Choose \(chapName?.capitalized ?? "Psalm")"
		} else {
			navigationItem.prompt = "Choose \(chapName?.capitalized ?? "Chapter") of " + bkInst!.bkName
		}

    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		goingForwards = false
		// Retrieve current Chapter if one had been selected
		if bkInst!.curChID > 0 {
			chNum = bkInst!.curChNum
			chRow = chNum - 1
		}
		// Added reloadData() to catch changes to the current VerseItem in a book
		// TODO: Perhaps call this only when a flag on the Book instance says is is needed?
		tableView.reloadData()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		// Most launches will have a current Chapter and will go straight to it
		if !letUserChooseChapter && bkInst!.curChID > 0 {
			bkInst!.goCurrentChapter()
			// The user is going forwards to the next scene
			goingForwards = true
			// If the user comes back to the Choose Chapter scene we need to let him choose again
			letUserChooseChapter = true
			performSegue(withIdentifier: "editChapter", sender: self)	// Go to Edit Chapter scene
		}
		// On first launch, do nothing and wait for the user to choose a Chapter.
		// When user wants to choose another chapter, scroll so that the previously chosen chapter
		// is near the middle of the TableView
		tableView.scrollToRow(at: IndexPath(row: chRow, section: 0), at: UITableView.ScrollPosition.middle, animated: true)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		if !goingForwards {
			chRow = 0	// Assume a different book & avoid an out-of-range row
		}
	}
	
	// MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
 		if section == 0 {
			return bkInst!.BibChaps.count
		} else {
			return 0
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterCell", for: indexPath)
		let chapter = bkInst!.BibChaps[indexPath.row]
		let txtLabel = "\(chapName!.capitalized) " + String(chapter.chNum)
		cell.textLabel!.text = txtLabel
		var numVsItText = ""
		let curVsNum = chapter.curVN
		if chapter.itRCr {
			if curVsNum > 0 {
				numVsItText = "Vs " + String(curVsNum) + " "
			}
			numVsItText += "(" + String(chapter.numVs) + " vs)"
		}
		cell.detailTextLabel?.text = numVsItText
		if chapter.itRCr {
			cell.textLabel!.textColor = UIColor.blue
		} else {
			cell.textLabel!.textColor = UIColor.black
		}
        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// Set up the selected Chapter as the current Chapter
		let chRowNew = indexPath.row
		bkInst!.setupCurrentChapter(withOffset: chRowNew)
		chRow = chRowNew	// First Chapter in list is row zero
		chNum = chRow + 1	// Only items in TableView are Chapters starting at 1
		let cell = tableView.cellForRow(at: indexPath)
		cell!.textLabel!.textColor = UIColor.blue
		// Current Chapter is selected so segue to Edit Chapter scene
		// The user is going forwards to the next scene
		goingForwards = true
		// If the user comes back to the Choose Chapter scene we need to let him choose again
		letUserChooseChapter = true
		performSegue(withIdentifier: "editChapter", sender: self)
	}

	@IBAction func unwindToEditChapter(_ segue: UIStoryboardSegue) {
	}

}
