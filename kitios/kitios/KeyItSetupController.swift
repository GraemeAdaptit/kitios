//
//  KeyItSetupController.swift
//
//	GDLC 21SEP20	Removed redundant @IBOutlet for saveBibleName
//
//	The KeyItSetupController allows the user to edit the name of the Bible and then
//	starts the creation of the Bible -> curr Book -> curr Chapter -> curr VerseItem
//	in-memory data structures.
//
//	Once the name of the Bible has been set and its Books records have been created
//	this scene is bypassed on subsequent launches.
//
//  Created by Graeme Costin on 3/3/20.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class KeyItSetupController: UIViewController, UITextFieldDelegate {

	var dao: KITDAO?
	var bInst: Bible?

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

//	required init?(coder aDecoder: NSCoder) {
//		super.init(coder: aDecoder)
//		print("KeyItSetupController:init")
//	}

    override func viewDidLoad() {
        super.viewDidLoad()

		// Get field values from the one and only Bible record
		dao = appDelegate.dao
		let bibRec = dao!.bibleGetRec()
		bibID = bibRec.bibID
		bibName = bibRec.bibName
		bkRCr = bibRec.bkRCr
		currBook = bibRec.currBk

		print("The Bible record for \(bibName) has been read from kdb.sqlite")
		print("The currBook read from kdb.sqlite is \(currBook)")
	}

	override func viewDidAppear(_ animated: Bool) {
//	We can allow subsequent editing of the name of the Bible
//		if bkRCr {
//			performSegue (withIdentifier: "keyItNav", sender: self)
//		} else {
			// Initialise the text field
			bibleName.text = bibName
//		}
	}
    
	// MARK: Actions

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		view.endEditing(true)
		super.touchesBegan(touches, with: event)
	}

	@IBAction func goNavController (_ sender: UIButton) {
		saveBibleName()
		createBibleInstance()
		performSegue (withIdentifier: "keyItNav", sender: self)
	}

//	Don't need a button for this; when the user taps "Go" segueToNavController() automatically saves the edited name
	func saveBibleName () {
		// Remove the insertion point from the Name of Bible text field
		self.view.endEditing(true)
		bibName = bibleName.text!
		if !dao!.bibleUpdateName (bibName) {
			print("KeyItSetupController:saveBibleName failed")
		} else {
			print("KeyItSetupController:saveBibleName \(bibName) succeeded")
		}
		
	}

	func createBibleInstance () {
		print("KeyItSetupController:segueToNavController create Bible instance")
		// Create an instance of the class Bible whose initialisation will create the array
		// of Bible books and start building the partial in-memory data structures for
		//		Bible -> curr Book -> curr Chapter -> curr VerseItem.
		bInst = Bible(bibID, bibName, bkRCr, currBook)
		// Ensure rest of app has access to the Bible instance
		appDelegate.bibInst = bInst
		print("KeyItSetupController:createBibleInstance KIT has created an instance of class Bible")
	}

	/*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
