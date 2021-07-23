//
//  VersesTableViewController.swift
//	kitios
//
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
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
		// Get access to the current Book and the current Chapter
		bInst = appDelegate.bibInst	// Get access to the instance of the Bible
		bkInst = appDelegate.bookInst	// Get access to the instance of the current Book
		chInst = appDelegate.chapInst	// Get access to the instance of the current Chapter
		appDelegate.VTVCtrl = self		// Allow the AppDelegate to access this controller
		navigationItem.title = bInst!.bibName
		if bkInst!.bkID == 19 {
			navigationItem.prompt = "Edit \(bkInst!.chapName?.capitalized ?? "Psalm") " + String(chInst!.chNum)
		} else {
			navigationItem.prompt = "Edit \(bkInst!.chapName?.capitalized ?? "Chapter") " + String(chInst!.chNum) + " of " + bkInst!.bkName
		}
		navigationItem.largeTitleDisplayMode = .always

    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		// Get the offset and ID of the current VerseItem
		currItOfst = chInst!.goCurrentItem()
		// Select this VerseItem and scroll to make it visible
		tableView.selectRow(at: IndexPath(row: currItOfst, section: 0), animated: animated, scrollPosition: UITableView.ScrollPosition.middle)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if let cell = tableView.cellForRow(at: IndexPath(row: currItOfst, section: 0)) as! UIVerseItemCell? {
			cell.itText.becomeFirstResponder()
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		// Save the current verse if necessary
		saveCurrentItemText()
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
		switch vsItem.itTyp {
        case "Title":
            cell.pubBut.setTitle("Main Title", for: .normal)
		case "Para", "ParaCont":
			cell.pubBut.setTitle("Paragraph", for: .normal)
		case "ParlRef":
			cell.pubBut.setTitle("Parallel Ref", for: .normal)
		case "VerseCont":
			cell.pubBut.setTitle("Verse " + String(vsItem.vsNum) + " (cont)", for: .normal)
		case "Verse":
			if vsItem.isBrg {
				cell.pubBut.setTitle("Verses " + String(vsItem.vsNum) + "-" + String(vsItem.lvBrg), for: .normal)
			} else {
				cell.pubBut.setTitle("Verse " + String(vsItem.vsNum), for: .normal)
			}
		case "InTitle":
			cell.pubBut.setTitle("Intro Title", for: .normal)
		case "InSubj":
			cell.pubBut.setTitle("Intro Heading", for: .normal)
		case "InPara":
			cell.pubBut.setTitle("Intro Paragraph", for: .normal)
		default:
			cell.pubBut.setTitle(vsItem.itTyp, for: .normal)
		}
		cell.itText.text = vsItem.itTxt
		// GDLC 19JAN21 BUG9 Simply setting the background colour of itText to white does not make the text edit
		// cursor visible on iOS 11.0.1, so this bug will be documented as a feature that can be avoided by
		// upgrading to iOS 12 or later.
		//cell.itText.backgroundColor = .white
		cell.tableRow = indexPath.row
		cell.VTVCtrl = self
		cell.textChanged {[weak tableView] (_) in
			DispatchQueue.main.async {
				tableView?.beginUpdates()
				tableView?.endUpdates()
			}
		}
        return cell
    }

	// Called by the custom verse item cell when UIKit wants to reuse the cell
	// Save itText before actual reuse unless there are no changes to itText

	func saveCellText(_ tableRow: Int, _ textSrc: String) {
		chInst!.copyAndSaveVItem(tableRow, textSrc)
	}

	// Called by the custom verse item cell when the user taps on the cell's label
	func userTappedOnCellLabel(_ tableRow: Int) {
		changeCurrentCell(tableRow)
	}
	
	// Called by the custom verse item cell when the user taps inside the cell's editable text
	func userTappedInTextOfCell(_ tableRow: Int) {
		changeCurrentCell(tableRow)
		let cell = tableView.cellForRow(at: IndexPath(row: tableRow, section: 0)) as! UIVerseItemCell
		if chInst!.BibItems[tableRow].itTyp != "Para" {
			cell.itText.becomeFirstResponder()
		}
	}

	// Called by iOS when the user selects a table row
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		changeCurrentCell(indexPath.row)
	}

	func changeCurrentCell(_ newOfst: Int) {
		if newOfst != currItOfst {
			// Save the text in the current BibItem before changing to the new one
			saveCurrentItemText()

			// Go to the newly selected VerseItem

			// Set up the selected Item as the current VerseItem
			chInst!.setupCurrentItemFromTableRow(newOfst)
			currItOfst = newOfst
			// Select this VerseItem and ensure that it is visible
			tableView.selectRow(at: IndexPath(row: currItOfst, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.middle)
		}
	}
	
	func saveCurrentItemText() {
		let currCell = tableView.cellForRow(at: IndexPath(row: currItOfst, section: 0)) as! UIVerseItemCell?
		if currCell != nil {
			if currCell!.dirty {
				let textSrc = currCell!.itText.text as String
				chInst!.copyAndSaveVItem(currItOfst, textSrc)
				currCell!.dirty = false
			}
		}
	}

	func currTextSplit() -> (cursPos:Int, txtBef:String, txtAft:String) {
		let currCell = tableView.cellForRow(at: IndexPath(row: currItOfst, section: 0)) as! UIVerseItemCell?
		if currCell != nil {
			let tView = currCell!.itText
			if let selectedRange: UITextRange = tView!.selectedTextRange {
				let cursorPosition = tView!.offset(from: tView!.beginningOfDocument, to: selectedRange.start)
				let currPosition = tView!.position(from: tView!.beginningOfDocument, offset: cursorPosition)!
				let textBefore = tView!.textRange(from: tView!.beginningOfDocument, to: currPosition)
				let befText = tView!.text(in: textBefore!)! as String
				let textAfter = tView!.textRange(from: currPosition, to: tView!.endOfDocument)
				let aftText = tView!.text(in: textAfter!)! as String
				return (cursorPosition, befText, aftText)
			} else {
				return (0, "", "")
			}
		} else {
			return (0, "", "")
		}
	}
	
	override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		let savCell = cell as! UIVerseItemCell
 		if savCell.dirty {
			let textSrc = savCell.itText.text! as String
			saveCellText(savCell.tableRow, textSrc)
			savCell.dirty = false
		}
	}

	// Action for the itType button in the VerseItem cell
	func pubItemsPopoverAction(_ button: UIButton, _ tableRow:Int, _ showRect:CGRect) {
		userTappedOnCellLabel(tableRow)
		var anchorRect    = tableView.convert(showRect, to: tableView)
		anchorRect        = tableView.convert(anchorRect, to: view)
		let vc: PubItemsViewController = self.storyboard?.instantiateViewController(withIdentifier: "PubItemsViewController") as! PubItemsViewController
		// Preferred Size
		let screenWidth = UIScreen.main.bounds.size.width
		let poMenuWidth = chInst?.curPoMenu?.menuLabelLength ?? 120
		let popoverWidth = Int(poMenuWidth + 35)
		anchorRect.origin.x = screenWidth - CGFloat(popoverWidth) - 50
		anchorRect.size.height = 20
		anchorRect.size.width = 20
		let numRows = chInst?.curPoMenu?.numRows ?? 5
		let popoverHeight = (numRows * 44)	// Height of popoverCell = 44
		vc.preferredContentSize = CGSize(width: popoverWidth, height: popoverHeight)
		vc.modalPresentationStyle = .popover
		let popover: UIPopoverPresentationController = vc.popoverPresentationController!
		popover.delegate = self
		popover.sourceView = view
		popover.sourceRect = anchorRect
		popover.permittedArrowDirections = .left
		present(vc, animated: true, completion:nil)
	}

	// Adjust the VerseItems TableView after popover menu changes to the data model
	func refreshDisplayAfterPopoverMenuActions() {
		dismiss(animated: true, completion:nil)
		tableView.reloadData()
		// Get current VerseItem from Chapter instance
		currItOfst = chInst!.goCurrentItem()
		// Select this VerseItem and scroll to make it visible
		tableView.selectRow(at: IndexPath(row: currItOfst, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.middle)
		// Activate it for text input
		let cell = tableView.cellForRow(at: IndexPath(row: currItOfst, section: 0)) as! UIVerseItemCell
		let bibItem = chInst!.getBibItem(at: currItOfst)
		if bibItem.itTyp != "Para" {
			cell.itText.becomeFirstResponder()
		}
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
