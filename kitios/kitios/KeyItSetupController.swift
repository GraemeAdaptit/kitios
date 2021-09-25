//
//  KeyItSetupController.swift
//	kitios
//
//	The KeyItSetupController allows the user to edit the name of the Bible and then
//	starts the creation of the Bible -> curr Book -> curr Chapter -> curr VerseItem
//	in-memory data structures.
//
//	Once the name of the Bible has been set and its Books records have been created
//	this scene is bypassed on subsequent launches.
//
//	GDLC 30JUL21 No need for local var bInst
//	GDLC 27JUL21 Added better error reporting
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//	GDLC 21SEP20 Removed redundant @IBOutlet for saveBibleName
//
//  Created by Graeme Costin on 3MAR20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class KeyItSetupController: UIViewController, UITextFieldDelegate {

	weak var dao: KITDAO?
//	var bInst: Bible?

	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate

	// MARK: Properties

	// Safe initialisations of the four Properties of the Bible record
	var bibID: Int = 1	// Bible ID - always 1 for KIT v1
	var bibName: String = "Bible"	// Bible name
	var bkRCr: Bool = false	// true when the Books records for this Bible have been created
	var currBook: Int = 0	// current Book ID
		// Bible Book IDs are assigned by the Bible Societies as 1 to 39 OT and 41 to 67 NT)

	@IBOutlet weak var bibleName: UITextField!
	@IBOutlet weak var goButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

		// Get field values from the one and only Bible record
		dao = appDelegate.dao
		do {
			let bibRec = try dao!.bibleGetRec()
			bibID = bibRec.bibID
			bibName = bibRec.bibName
			bkRCr = bibRec.bkRCr
			currBook = bibRec.currBk
		} catch {
			appDelegate.ReportError(DBR_BibErr)		// Bible record could not be read
		}
	}

	//	Once the user has dealt with the Setup scene, subsequent launches skip the Setup scene.
	//	Any future editing of the name of the Bible will be done in a separate scene.
	override func viewDidAppear(_ animated: Bool) {
		if bkRCr {
			createBibleInstance()
			performSegue (withIdentifier: "keyItNav", sender: self)
		} else {
			// Initialise the text field and wait for user to edit Bible name
			bibleName.text = bibName
		}
	}
    
	// MARK: Actions

	// TODO: Check whether this function is still needed.
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		view.endEditing(true)
		super.touchesBegan(touches, with: event)
	}

	@IBAction func goNavController (_ sender: UIButton) {
		saveBibleName()
		createBibleInstance()
		performSegue (withIdentifier: "keyItNav", sender: self)
	}

	func createBibleInstance () {
		// Create an instance of the class Bible whose initialisation will create the array
		// of Bible books and start building the partial in-memory data structures for
		//		Bible -> curr Book -> curr Chapter -> curr VerseItem
		// and save a reference to it in the appDelegate so the rest of the app has access to it.
		// GDLC 30JUL21 No need for local var bInst; the strong ref is appDelegate.bibInst
		appDelegate.bibInst = Bible(bibID, bibName, bkRCr, currBook)
	}

	// Don't need a button for this; when the user taps "Go"
	// goNavController() automatically saves the edited name
	func saveBibleName () {
		// Remove the insertion point from the Name of Bible text field
		self.view.endEditing(true)
		bibName = bibleName.text!
		do {
			try dao!.bibleUpdateName (bibName)
		} catch {
			appDelegate.ReportError(DBU_BibNErr)
		}
	}

}
