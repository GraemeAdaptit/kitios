//
//  VersesTableViewController.swift
//  KIT05
//
//	This is the UITableViewController for the Edit Chapter scene. This scene will be entered
//	only when a current Book and current Chapter have been chosen.
//
//  Created by Graeme Costin on 8/1/20.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class VersesTableViewController: UITableViewController {

	var bInst: Bible?
	var bkInst: Book?
	var chInst: Chapter?
	// TODO: Check whether currIt is needed by VersesTableViewController?
	var currIt = 0		// Zero until one of the VerseItems is chosen for editing;
						// then it is the ItemID of the VerseItem that is the current one.
	var currItOfst = -1	// -1 until one of the VerseItems is chosen for editing;
						// then it is the offset into the BibItems[] array which equals
						// the offset into the list of cells in the TableView.

	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate

	// Boolean for detecting when Back button has been pressed
	var goingForwards = false

	// The only time that the VersesTableViewController will be loaded is
	// after a Book and Chapter have been selected for editing.

    override func viewDidLoad() {
        super.viewDidLoad()
		print("VersesTableViewController:viewDidLoad")
		// Get access to the current Book and the current Chapter
		bInst = appDelegate.bibInst	// Get access to the instance of the Bible
		bkInst = appDelegate.bookInst	// Get access to the instance of the current Book
		chInst = appDelegate.chapInst	// Get access to the instance of the current Chapter
		appDelegate.VTVCtrl = self		// Allow the AppDelegate to access this controller
		navigationItem.title = bInst!.bibName
		navigationItem.prompt = "Keyboard chapter " + String(chInst!.chNum) + " of " + bkInst!.bkName

		// Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		print("VersesTableViewController:viewWillAppear")
		// Get the offset and ID of the current VerseItem
		currItOfst = chInst!.goCurrentItem()
		currIt = chInst!.BibItems[currItOfst].itID
		// Scroll to make this VerseItem visible
		tableView.selectRow(at: IndexPath(row: currItOfst, section: 0), animated: animated, scrollPosition: UITableView.ScrollPosition.middle)
		tableView.scrollToRow(at: IndexPath(row: currItOfst, section: 0), at: UITableView.ScrollPosition.middle, animated: animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		print("VersesTableViewController:viewDidAppear")
		if let cell = tableView.cellForRow(at: IndexPath(row: currItOfst, section: 0)) as! UIVerseItemCell? {
			cell.itText.becomeFirstResponder()
		} else {
			print("Selected current cell not visible")
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		print("VersesTableViewController:viewWillDisappear")
		// Save the current verse if necessary
		saveCurrentItemText()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		print("VersesTableViewController:viewDidDisappear")
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return chInst!.BibItems.count
		} else {
        	return 0
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UIVerseItemCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! UIVerseItemCell
		let vsItem = chInst!.BibItems[indexPath.row]
		if vsItem.itTyp == "Ascription" {
			cell.itType.text = vsItem.itTyp
		} else {
			cell.itType.text = vsItem.itTyp + " " + String(vsItem.vsNum)
		}
		cell.itText.text = vsItem.itTxt
		cell.tableRow = indexPath.row
		cell.VTVCtrl = self
		cell.textChanged {[weak tableView] (_) in
			DispatchQueue.main.async {
				tableView?.beginUpdates()
				tableView?.endUpdates()
			}
		}
		print("VersesTableViewController:tableView:cellForRowAt Fetched verse \(vsItem.vsNum)")
        return cell
    }

	// Called by the custom verse item cell when UIKit wants to reuse the cell
	// Save itText before actual reuse unless there are no changes to itText

	func saveCellText(_ tableRow: Int, _ textSrc: String) {
		chInst!.copyAndSaveVItem(tableRow, textSrc)
	}

	// Called by the custom verse item cell when the user taps inside the cell's editable text
	func userTappedInTextOfCell(_ tableRow: Int) {
		tableView(self.tableView, didSelectRowAt: IndexPath(row: tableRow, section: 0))
	}

	// Called by iOS when the user selects a table row
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// Save the text in the current BibItem before changing to the new one
		saveCurrentItemText()

		// Go to the newly selected VerseItem
		let bibItem = chInst!.getBibItem(at: (indexPath.row))
		print("VersesTableViewController:tableView:didSelectRowAt Tap selected verse \(bibItem.vsNum)")

		// Set up the selected Item as the current VerseItem
		chInst!.setupCurrentItem(bibItem.itID)
		currIt = bibItem.itID
		currItOfst = indexPath.row
		// Scroll to make this VerseItem visible <- already visible because the user has just tapped in it
		tableView.selectRow(at: IndexPath(row: currItOfst, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.middle)
		let cell = tableView.cellForRow(at: indexPath) as! UIVerseItemCell
// TODO: Is this the proper solution for Bug 2?
//		cell.itText.backgroundColor = .white
		cell.itText.becomeFirstResponder()
//		cell.setSelected(true, animated: false)
	}

	func saveCurrentItemText () {
		print("Current VerseItem Offset: \(currItOfst), ID: \(currIt)")
		let currCell = tableView.cellForRow(at: IndexPath(row: currItOfst, section: 0)) as! UIVerseItemCell?
		if currCell != nil {
			if currCell!.dirty {
				let textSrc = currCell!.itText.text as String
				chInst!.copyAndSaveVItem(currItOfst, textSrc)
				print("VersesTableViewController:saveCurrentItemText Saved current verse \(currCell!.tableRow + 1)")
				currCell!.dirty = false
			}
		}
	}

	override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//		print("VersesTableViewController:didEndDisplaying cell for VerseItem \(indexPath.row)")
		let savCell = cell as! UIVerseItemCell
		if savCell.dirty {
			let textSrc = savCell.itText.text! as String
			saveCellText(savCell.tableRow, textSrc)
			print("VersesTableViewController:saveCurrentItemText Saved current item \(savCell.tableRow)")
			savCell.dirty = false
		}
	}

    // MARK: - Navigation

	@IBAction func publItems(_ sender: UIBarButtonItem) {
		let vc: TableViewController = self.storyboard?.instantiateViewController(withIdentifier: "TableViewController") as! TableViewController
		// Preferred Size
		vc.preferredContentSize = CGSize(width: 200, height: 200)
		vc.modalPresentationStyle = .popover
		let popover: UIPopoverPresentationController = vc.popoverPresentationController!
		popover.delegate = self
		popover.sourceView = self.view
		// RightBarItem
		popover.barButtonItem = sender
		present(vc, animated: true, completion:nil)
	}
	
	@IBAction func exportThisChapter(_ sender: Any) {
		saveCurrentItemText ()
		performSegue(withIdentifier: "exportChapter", sender: nil)
	}
}

extension VersesTableViewController: UIPopoverPresentationControllerDelegate {
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
	
}
