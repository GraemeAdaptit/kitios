//
//  VersesTableViewController.swift
//	kitios
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

class VersesTableViewController: UITableViewController, UITextViewDelegate {

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
			cell.pubBut.setTitle(vsItem.itTyp, for: .normal)
		} else {
			cell.pubBut.setTitle(vsItem.itTyp + " " + String(vsItem.vsNum), for: .normal)
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
//		cell.cellDelegate = self
        return cell
    }

	// Called by the custom verse item cell when UIKit wants to reuse the cell
	// Save itText before actual reuse unless there are no changes to itText

	func saveCellText(_ tableRow: Int, _ textSrc: String) {
		chInst!.copyAndSaveVItem(tableRow, textSrc)
	}

	// Called by the custom verse item cell when the user taps on the cell's label
	func userTappedOnCellLabel (_ tableRow: Int) {
		changeCurrentCell(tableRow)
	}
	
	// Called by the custom verse item cell when the user taps inside the cell's editable text
	func userTappedInTextOfCell(_ tableRow: Int) {
		changeCurrentCell(tableRow)
		let cell = tableView.cellForRow(at: IndexPath(row: tableRow, section: 0)) as! UIVerseItemCell
		cell.itText.becomeFirstResponder()
	}

	// Called by iOS when the user selects a table row
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		changeCurrentCell(indexPath.row)
	}

	func changeCurrentCell (_ newOfst: Int) {
		if newOfst != currItOfst {
			// Save the text in the current BibItem before changing to the new one
			saveCurrentItemText()

			// Go to the newly selected VerseItem
			let bibItem = chInst!.getBibItem(at: newOfst)
			print("VersesTableViewController:tableView:didSelectRowAt Tap selected verse \(bibItem.vsNum)")

			// Set up the selected Item as the current VerseItem
			chInst!.setupCurrentItem(bibItem.itID)
			currIt = bibItem.itID
			currItOfst = newOfst
			// Scroll to make this VerseItem visible <- already visible because the user has just tapped in it
			tableView.selectRow(at: IndexPath(row: currItOfst, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.middle)
//		let cell = tableView.cellForRow(at: IndexPath(row: newOfst, section: 0)) as! UIVerseItemCell
//		cell.itText.becomeFirstResponder()
		}
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

	// Action for the itType button in the VerseItem cell
	func pubItemsPopoverAction(_ button: UIButton, _ tableRow:Int, _ showRect:CGRect) {
		print ("\(String(describing: button.title(for: .normal))) pressed")
		userTappedOnCellLabel(tableRow)
		var anchorRect    = tableView.convert(showRect, to: tableView)
		anchorRect        = tableView.convert(anchorRect, to: view)
//		anchorRect.origin.x += 105
		let vc: PubItemsViewController = self.storyboard?.instantiateViewController(withIdentifier: "PubItemsViewController") as! PubItemsViewController
		// Preferred Size
		let screenWidth = UIScreen.main.bounds.size.width
		let popoverWidth = Int(screenWidth * 0.85)
		anchorRect.origin.x = screenWidth - CGFloat(popoverWidth)
		let numRows = chInst?.curPoMenu?.numRows ?? 5
		let popoverHeight = (numRows * 50) + 10
		vc.preferredContentSize = CGSize(width: popoverWidth, height: popoverHeight)
		vc.modalPresentationStyle = .popover
		let popover: UIPopoverPresentationController = vc.popoverPresentationController!
		popover.delegate = self
		popover.sourceView = view
		popover.sourceRect = showRect
		popover.permittedArrowDirections = .left
		present(vc, animated: true, completion:nil)
	}

	// Action for the Pub button in the Navigation Bar - will soon be removed
	@IBAction func publItems(_ sender: UIBarButtonItem) {
		let vc: PubItemsViewController = self.storyboard?.instantiateViewController(withIdentifier: "PubItemsViewController") as! PubItemsViewController
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
