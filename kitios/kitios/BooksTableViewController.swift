//
//  BooksTableViewController.swift
//  kitios
//
//	GDLC 12MAR20 Updated for KIT05
//
//	This is the UITableViewController for the Select Book scene. This scene will be entered
//	after the Bible instance is created and so it will always have available the array of
//	Bible Books. But it will not always have a current Book:
//	*	During app launch a current Book may have been read from kdb.sqlite and so this
//		current Book can be set, and then control passed to the Select Chapter scene.
//	*	During app use the user may want to change to a different Book and so control
//		will be passed back to this Select Book scene to allow this to happen.
//	The member variable hasCurrBook will be initialised to false and subsequently set to true
//	or false as the above actions happen.
//
//  Created by Graeme Costin on 26/10/19.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class BooksTableViewController: UITableViewController {

	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	var bInst: Bible?

	// Boolean for detecting when Back button has been pressed
	var goingForwards = false
	// Boolean for whether the let the user choose a Book
	var letUserChooseBook = false
	// tableRow of the selected Book
	var bkRow = 0


//	required init?(coder aDecoder: NSCoder) {
//		super.init(coder: aDecoder)
//		print("BooksTableViewController:init")
//	}
//
//	deinit {
//		print("BooksTableViewController:deinit")
//	}
	
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
		print("BooksTableViewController:viewWillAppear")
		goingForwards = false
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		print("BooksTableViewController:viewDidAppear")
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
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		print("BooksTableViewController:viewWillDisappear")
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		print("BooksTableViewController:viewDidDisappear")
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
		} else {
			cell.textLabel!.textColor = UIColor.black
		}
		let numChText = (book.numCh > 0 ? String(book.numCh) + " ch " : "" )
		cell.detailTextLabel?.text = numChText
		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selectedBook = bInst!.BibBooks[indexPath.row]
		print("BooksTableViewController:tableView:didSelectRowAt Tap selected \(selectedBook.bkName)")
		// Set up the selected Book as the current Book (this updates kdb.sqlite with the currBook)
		bInst!.setupCurrentBook(selectedBook)
		// Update the TableView row for this Book
		let cell = tableView.cellForRow(at: indexPath)
		let nChap = bInst!.BibBooks[indexPath.row].numCh
		let numChText = (nChap > 0 ? String(nChap) + " ch " : "" )
		cell!.detailTextLabel?.text = numChText
		cell!.textLabel!.textColor = UIColor.blue
		// Current Book is selected so segue to Select Chapter scene
		// The user is going forwards to the next scene
		goingForwards = true
		// If the user comes back to the Choose Book scene we need to let him choose again
		letUserChooseBook = true
		performSegue(withIdentifier: "selectChapter", sender: self)
	}
	
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
