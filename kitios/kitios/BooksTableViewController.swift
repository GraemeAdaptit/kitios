//
//  BooksTableViewController.swift
//  kitios
//
//	This is the UITableViewController for the Select Book scene. This scene will be entered
//	after the Bible instance is created and so it will always have available the array of
//	Bible Books. But it will not always have a current Book:
//	*	During app launch a current Book may have been read from kdb.sqlite and so this
//		current Book can be set, and then control passed to the Select Chapter scene.
//	*	During app use the user may want to change to a different Book and so control
//		will be passed back to this Select Book scene to allow this to happen.
//
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//	GDLC 12MAR20 Updated for KIT05
//
//  Created by Graeme Costin on 26OCT19.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class BooksTableViewController: UITableViewController {

	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	weak var bInst: Bible?		// The strong ref is on AppDelegate

	// Boolean for detecting when Back button has been pressed
	var goingForwards = false
	// Boolean for whether the let the user choose a Book
	var letUserChooseBook = false
	// tableRow of the selected Book
	var bkRow = 0

	override func viewDidLoad() {
		super.viewDidLoad()
		// Get access to the instance of Bible
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		bInst = appDelegate.bibInst
		navigationItem.title = bInst!.bibName
		navigationItem.prompt = "Choose book"
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		goingForwards = false
		// Added reloadData() to catch changes to the current Chapter in a book
		// TODO: Call this only when a flag on the Bible instance says is is needed?
		tableView.reloadData()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		// Most launches will have a current Book and will go straight to it
		if !letUserChooseBook && bInst!.currBook > 0 {
			bInst!.goCurrentBook()	// Creates an instance for the current Book (from kdb.sqlite)
			// The user is going forwards to the next scene
			goingForwards = true
			// If the user comes back to the Choose Book scene we need to let him choose again
			letUserChooseBook = true
			performSegue(withIdentifier: "selectChapter", sender: self)	// Go to Select Chapter scene
		}
		// On first launch, and when user wants to choose another book,
		// do nothing and wait for the user to choose a Book.
		// When user wants to choose another Book, scroll so that the previously chosen Book
		// is near the middle of the TableView
		let curBkOfst = bInst!.getCurrBookOfst()
		if curBkOfst > 0 {
			tableView.scrollToRow(at: IndexPath(row: curBkOfst, section: 0), at: UITableView.ScrollPosition.middle, animated: true)
		}
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView (_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return bInst!.BibBooks.count
		} else {
			return 0
		}
	}

	override func tableView (_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell", for: indexPath)
		let book = bInst!.BibBooks[indexPath.row]
		cell.textLabel?.text = book.bkName
		if book.chapRCr {
			cell.textLabel!.textColor = UIColor.blue
			cell.detailTextLabel!.textColor = UIColor.blue
		} else {
			cell.textLabel!.textColor = UIColor.black
			cell.detailTextLabel!.textColor = UIColor.black
		}
		let numCh = book.numCh
		let curChapID = bInst!.BibBooks[indexPath.row].curChID
		let curChNum = bInst!.BibBooks[indexPath.row].curChNum
		var numChText = ""
		if book.chapRCr {
			if curChapID > 0 {
				numChText = "Ch " + String(curChNum) + " "
			}
			numChText += "(" + String(numCh) + " chs)"
		}
		cell.detailTextLabel?.text = numChText
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedBook = bInst!.BibBooks[indexPath.row]
		// Set up the selected Book as the current Book (this updates kdb.sqlite with the currBook)
		bInst!.setupCurrentBook(selectedBook)
		bkRow = indexPath.row
		// Update the TableView row for this Book
		let cell = tableView.cellForRow(at: indexPath)
		let nChap = bInst!.BibBooks[indexPath.row].numCh
		let curChapID = bInst!.BibBooks[indexPath.row].curChID
		var curChNum = 0
		if appDelegate.bookInst != nil {
			curChNum = appDelegate.bookInst!.offsetToBibChap(withID: curChapID) + 1
		}
		var numChText = ""
		if selectedBook.chapRCr {
			if curChapID > 0 {
				numChText = "Ch " + String(curChNum) + " "
			}
			numChText += "(" + String(nChap) + " chs)"
		}
		cell!.detailTextLabel?.text = numChText
		cell!.textLabel!.textColor = UIColor.blue
		// Current Book is selected so segue to Select Chapter scene
		// The user is going forwards to the next scene
		goingForwards = true
		// If the user comes back to the Choose Book scene we need to let him choose again
		letUserChooseBook = true
		performSegue(withIdentifier: "selectChapter", sender: self)
	}
}

