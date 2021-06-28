//
//  UIVerseItemCell.swift
//  kitios
//
//	A custom class for UITableView cells presenting VerseItems for editing.
//
//  Created by Graeme Costin on 26/2/20.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

/* Declare a Delegate Protocol method */
protocol UIVerseItemCellDelegate:AnyObject {
	func customCell(cell:UIVerseItemCell, didTapPub button:UIButton)
}
 

class UIVerseItemCell: UITableViewCell, UITextViewDelegate {

	@IBOutlet weak var itText: UITextView!
	@IBOutlet weak var pubBut: UIButton!

	//Define delegate variable
	weak var cellDelegate:UIVerseItemCellDelegate?

	var textChanged: ((String) -> Void)?
	
	var tableRow = 0			// As each instance of UIVerseItemCell is created its tableRow is set
	var VTVCtrl: VersesTableViewController?	// Link to the ViewController that owns this cell
	var dirty = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		itText.delegate = self
    }

	func textChanged(action: @escaping (String) -> Void) {
		self.textChanged = action
	}

	func textViewDidChange(_ textView: UITextView) {
		dirty = true
		textChanged?(textView.text)
	}

	// Called by iOS when the user taps inside the cell's editable text field
	func textViewDidBeginEditing(_ textView: UITextView) {
		VTVCtrl!.userTappedInTextOfCell(tableRow)
	}

	func cellWentOutOfVisibleRange() {
//		VTVCtrl!.tableView(didEndDisplayingCell: self)
	}
	
	// Called by iOS when the UIKit wants to reuse a cell for a different table row
	override func prepareForReuse() {
		super.prepareForReuse()
		if dirty {
			let textSrc = itText.text as String
			VTVCtrl!.saveCellText(tableRow, textSrc)
		}
		dirty = false
	}

	// Action for the itType button in the VerseItem cell
	@IBAction func pubPopover(_ button: UIButton) {
		print ("\(String(describing: button.title(for: .normal))) pressed")
		let buttonFrame = button.frame
		let showRect    = self.convert(buttonFrame, to: VTVCtrl!.tableView)
		VTVCtrl!.pubItemsPopoverAction(button, tableRow, showRect)
	}
	
//	This function introduces behaviour that looks a little like mutual recursion
//	between parts of the UIKit - looks logical to me, but causes a crash!
//	override func setSelected(_ selected: Bool, animated: Bool) {
//		super.setSelected(selected, animated: animated)
//
//		// Configure the view for the selected state
//		if selected {
//			itText.backgroundColor = .white
//			itText.becomeFirstResponder()
//		} else {
//			itText.backgroundColor = .clear
//		}
//	}

}

extension UIVerseItemCell: UIPopoverPresentationControllerDelegate {
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
}
