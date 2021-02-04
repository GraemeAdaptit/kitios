//
//  Chapter.swift
//  kitios
//
//  Created by Graeme Costin on 8/1/20.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.
//
//	There will be one instance of the class Chapter and it will be for the current Chapter
//	that the user has selected for keyboarding. When the user switches to keyboarding
//	a different Chapter the current instance of Chapter will be deleted and a new instance
//	created for the newly selected Chapter.

import UIKit

public class Chapter: NSObject {

// Properties of a Chapter instance (dummy values to avoid having optional variables)
	var chID: Int = 0		// chapterID INTEGER PRIMARY KEY
	var bibID: Int = 0		// bibleID INTEGER
	var bkID: Int = 0		// bookID INTEGER,
	var chNum: Int = 0		// chapterNumber INTEGER
	var itRCr: Bool = false	// itemRecsCreated INTEGER
	var numVs: Int = 0		// numVerses INTEGER
	var numIt: Int = 0		// numItems INTEGER
	var currIt: Int = 0		// currItem INTEGER (the ID assigned by SQLite when the VerseItem was created)
	
	// currItOfst has custom getter and setter in order to ensure that a VIMenu is created for the
	// current VerseItem whenever the VerseItem is selected. This avoids putting the logic in the
	// setter in several places throughout the source code.
	//
	// The initial value of -1 means that there is not yet a current VerseItem
	// (the offsets for all actual VerseItems are >= zero)
	var field: Int = -1	// offset to current item in BibItems[] and row in the TableView
	var currItOfst: Int {
		get {
			return field
		}
		set (ofst) {
			if (curPoMenu == nil) {
				curPoMenu = VIMenu(ofst)
			} else if ((ofst != field) || (BibItems[ofst].itID != currIt)) {
				// Delete previous popover menu
				curPoMenu = nil
				curPoMenu = VIMenu(ofst)
			}
			field = ofst
			currIt = BibItems[ofst].itID
		}
	}
	
	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	
	var dao: KITDAO?		// access to the KITDAO instance for using kdb.sqlite
	var bibInst: Bible? 	// access to the instance of Bible for updating BibBooks[]
	var bkInst: Book?		// access to the instance for the current Book

//	Probably don't need this
//	var USFMText:String = ""

// This struct and the BibItems array are used for letting the user select the
// VerseItem to edit in the current Chapter of the current Book.

	struct BibItem {
		var itID: Int		// itemID INTEGER PRIMARY KEY
		var chID: Int		// chapterID INTEGER
		var vsNum: Int		// verseNumber INTEGER
		var itTyp: String	// itemType TEXT
		var itOrd: Int		// itemOrder INTEGER
		var itTxt: String	// itemText TEXT
		var intSeq: Int		// intSeq INTEGER
		var isBrg: Bool		// isBridge INTEGER
		var lvBrg: Int		// last verse of bridge

		init (_ itID:Int, _ chID:Int, _ vsNum:Int, _ itTyp:String, _ itOrd:Int, _ itTxt:String, _ itSeq:Int, _ isBrg:Bool, _ lvBrg:Int) {
			self.itID = itID
			self.chID = chID
			self.vsNum = vsNum
			self.itTyp = itTyp
			self.itOrd = itOrd
			self.itTxt = itTxt
			self.intSeq = itSeq
			self.isBrg = isBrg
			self.lvBrg = lvBrg
		}
	}

	var BibItems: [BibItem] = []

	// Properties of the Chapter instance related to popover menus
	var curPoMenu: VIMenu?		// instance in memory of the current popover menu
	var hasAscription = false	// true if the Psalm has an Ascription
	var hasTitle = false		// true if Chapter 1 has a Book Title
	
// When the instance of current Book creates the instance for the current Chapter it supplies the values
// for the currently selected Chapter from the BibChaps array
		
	init(_ chID: Int, _ bibID: Int, _ bkID: Int, _ chNum: Int, _ itRCr: Bool, _ numVs:Int, _ numIt: Int, _ currIt: Int) {
		super.init()
		print("Chapter:init instantiating current Chapter instance")
		self.chID = chID		// chapterID INTEGER PRIMARY KEY
		self.bibID = bibID		// bibleID INTEGER
		self.bkID = bkID		// bookID INTEGER,
		self.chNum = chNum		// chapterNumber INTEGER
		self.itRCr = itRCr		// itemRecsCreated INTEGER
		self.numVs = numVs		// numVerses INTEGER
		self.numIt = numIt		// numItems INTEGER
		self.currIt = currIt	// currItem INTEGER (ID of the current VerseItem)

		self.dao = appDelegate.dao			// access to the KITDAO instance for using kdb.sqlite
		self.bibInst = appDelegate.bibInst 	// access to the instance of Bible for updating BibBooks[]
		self.bkInst = appDelegate.bookInst
		
		// First time this Chapter has been selected the Item records must be created
		if !itRCr {
			createItemRecords()
		}

		// Every time this Chapter is selected: The VerseItems records in kdb.sqlite will have been
		// created at this point (either during this occasion or on a previous occasion),
		// so we set up the array BibItems of VerseItems by reading the records from kdb.sqlite.
		//
		// This array will last while this Chapter is the currently selected Chapter and will
		// be used whenever the user is allowed to select a VerseItem for editing;
		// it will also be updated when VerseItem records for this Chapter are created,
		// and when the user chooses a different VerseItem to edit.
		// Its life will end when the user chooses a different Chapter or Book to edit.
		
		// Calls readVerseItemsRecs() in KITDAO.swift to read the kdb.sqlite database VerseItems table
		// readVerseItemsRecs() calls appendItemToArray() in this file for each ROW read from kdb.sqlite
		let result = dao!.readVerseItemsRecs (self)
		if result {
			print("VerseItems records for chapter \(chNum) have been read from kdb.sqlite")
		} else {
			print("ERROR: VerseItems records for chapter \(chNum) have not been read from kdb.sqlite")
		}
		// Ensure that numIt is correct (to guard against any accumulated data errors)
		self.numIt = BibItems.count
		if dao!.chaptersUpdateRecPub (chID, self.numIt, self.currIt) {
			print("Chapter init(): numIt updated in kdb.sqlite")
		}
	}
	
// Create a VerseItem record in kdb.sqlite for each VerseItem in this Chapter
// If this is a Psalm and it has an ascription then numIt will be 1 greater than numVs.
// For all other VerseItems numIt will equal numVs at this early stage of building the app's data

	func createItemRecords() {
		// If there is a Psalm ascription then create it first.
		if numIt > numVs {
			let vsNum = 1
			let itTyp = "Ascription"
			let itOrd = 70	// 100 * VerseNumber - 30
			let itText = ""
			let intSeq = 0
			let isBrid = false
			let lastVsBridge = 0
			if dao!.verseItemsInsertRec (chID, vsNum, itTyp, itOrd, itText, intSeq, isBrid, lastVsBridge) != -1 {
//				print("Chapter:createItemRecords Created Ascription record for Psalm \(chNum)")
			} else {
				print("ERROR: Book:createItemRecords: Creating Ascription record failed for Psalm \(chNum)")
			}
		}
		for vsNum in 1...numVs {
			let itTyp = "Verse"
			let itOrd = 100*vsNum
			let itText = ""
			let intSeq = 0
			let isBrid = false
			let lastVsBridge = 0
			if dao!.verseItemsInsertRec (chID, vsNum, itTyp, itOrd, itText, intSeq, isBrid, lastVsBridge) != -1 {
//				print("Chapter:createItemRecords Created Verse record for chap \(chNum) vs \(vsNum)")
			} else {
				print("ERROR: Book:createItemRecords: Creating Verse record failed for chap \(chNum) vs \(vsNum)")
			}
		}
		// Update in-memory record of current Chapter to indicate that its VerseItem records have been created
		itRCr = true
		// Also update the BibChap struct to show itRCr true
		bibInst!.bookInst!.BibChaps[chNum - 1].itRCr = true
		// Update Chapter record to show that VerseItems have been created
		if dao!.chaptersUpdateRec (chID, itRCr, currIt) {
//			print("Chapter:createItemRecords update Chapter record for chap \(chNum) succeeded")
		} else {
			print("Chapter:createItemRecords update Chapter record for chap \(chNum) failed")
		}
	}
	
// dao.readVerseItemRecs() calls appendItemToArray() for each row it reads from the kdb.sqlite database

	func appendItemToArray(_ itID:Int, _ chID:Int, _ vsNum:Int, _ itTyp:String, _ itOrd:Int, _ itTxt:String, _ intSeq:Int, _ isBrg:Bool, _ lvBrg:Int) {
		let itRec = BibItem(itID, chID, vsNum, itTyp, itOrd, itTxt, intSeq, isBrg, lvBrg)
		BibItems.append(itRec)
		if itTyp == "Ascription" {hasAscription = true}
		if itTyp == "Title" {hasTitle = true}
	}

// Find the offset in BibItems[] to the element having VerseItemID withID
// If out of range returns offset zero (first item in the array)

	func offsetToBibItem(withID:Int) -> Int {
		for i in 0...numIt-1 {
			if BibItems[i].itID == withID {
				return i
			}
		}
		return 0
	}

	// Return the BibItem at an index
	
	func getBibItem(at index:Int) -> BibItem {
		return BibItems[index]
	}
	
// Go to the current BibItem
// This function is called by the VersesTableViewController to find out which VerseItem
// in the current Chapter is the current VerseItem, and to make the Chapter record
// remember that selection.
//
// Returns the current Item offset in BibItems[] array to the VersesTableViewController
// because this equals the row number in the TableView.

	func goCurrentItem() -> Int {
		if currIt == 0 {
			// Make the first VerseItem the current one
			currItOfst = 0		// Take first item in BibItems[] array
			currIt = BibItems[currItOfst].itID	// Get its itemID
		} else {
			// Already have the itemID of the current item so need to get
			// the offset into the BibItems[] array
			currItOfst = offsetToBibItem(withID: currIt)
			// Setting currItOfst ensures that there is a VIMenu for the current VerseItem
		}
//		createPopoverMenu (currItOfst)
		// Update the database Chapter record
		if dao!.chaptersUpdateRec (chID, itRCr, currIt) {
			print ("Chapter:goCurrentItem updated \(bkInst!.bkName) \(chNum) Chapter record")
		} else {
			print ("Chapter:goCurrentItem ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
		}
		return currItOfst
	}

	// Set up the new current BibItem given the VerseItem's ID
	// (as assigned by SQLite when the database's VerseItem record was created)

	func setupCurrentItem(_ currIt:Int) {
		self.currIt = currIt
		currItOfst = offsetToBibItem(withID: currIt)
		// Setting currItOfst ensures that there is a VIMenu for the current VerseItem
//		createPopoverMenu (currItOfst)
		// Update the BibChap record for this Chapter
		bkInst!.setCurVItem (currIt)
		// Update the database Chapter record
		if dao!.chaptersUpdateRec (chID, itRCr, currIt) {
//			print ("Chapter:goCurrentItem updated \(bkInst!.bkName) \(chNum) Chapter record")
		} else {
			print ("Chapter:goCurrentItem ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
		}
	}

	// TODO: This function is not currently used - delete it???
	func setupCurrentItemFromTableRow(_ tableRow: Int) {
		currItOfst = tableRow
		currIt = BibItems[tableRow].itID
		// Setting currItOfst ensures that there is a VIMenu for the current VerseItem
//		createPopoverMenu (currItOfst)
		// Update the database Chapter record
		if dao!.chaptersUpdateRec (chID, itRCr, currIt) {
//			print ("Chapter:goCurrentItem updated \(bkInst!.bkName) \(chNum) Chapter record")
		} else {
			print ("Chapter:goCurrentItem ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
		}
	}

	// Copy and save the current VerseItem's text
	func copyAndSaveVItem(_ ofSt: Int, _ text: String) {
		BibItems[ofSt].itTxt = text
		if dao!.itemsUpdateRecText (BibItems[currItOfst].itID, BibItems[currItOfst].itTxt) {
//			print ("Chapter:saveCurrentItemText text of current item saved to kdb.sqlite")
		} else {
			print ("Chapter:saveCurrentItemText save of current item text to kdb.sqlite FAILED")
		}
//		chDirty = true	// An item in this chapter has been edited (used in UI)
	}

//	// Create the popover menu for the current VerseItem
//	func createPopoverMenu () {
//		// Delete previous popover menu
//		curPoMenu = nil
//		curPoMenu = VIMenu(currItOfst)
//	}

	// Function to carry out on the data model the actions required for the popover menu items
	// All of the possible actions change the BibItems[] array so, after carrying out the
	// specific action, this function clears BibItems[] and reloads it from the database;
	// following this the VersesTableViewController needs to reload the TableView.
	func popMenuAction(_ act: String) {
		switch act {
		case "crAsc":
			createAscription()
		case "delAsc":
			deleteAscription()
		case "crTitle":
			createTitle()
		case "delTitle":
			deleteTitle()
		case "crParaBef":
			createParagraphBefore()
		case "delPara":
			deleteParagraphBefore()
		case "crParaCont":
			createParagraphCont()
		case "delPCon":
			deleteParagraphCont()
		case "crHdBef":
			createSubjHeading()	// Pass crHdBef as parameter???
		case "delHead":
			deleteSubjHeading()
		case "brid":
			bridgeNextVerse()
		case "unBrid":
			unbridgeLastVerse()
		default:
			print("BUG! Unknown action code")
		}

		// GDLC 12JAN21 BUG10 The logic in the setter for currItOfst works for moving from one VerseItem
		// to another but it fails in some situations where a new VerseItem is created or deleted
		// (on creation because the new VerseItem may have the same offset as the one whose menu action
		// was used). So destroying the current popover menu once an action from it has been used
		// ensures that a new popover menu will be created.
		//
		// Delete the popover menu now that it has been used
		curPoMenu = nil
		// Clear the current BibItems[] array
		BibItems.removeAll()
		// Reload the BibItems[] array of VerseItems
		let result = dao!.readVerseItemsRecs (self)
		if result {
			print("VerseItems records for chapter \(chNum) have been read from kdb.sqlite")
		} else {
			print("ERROR: VerseItems records for chapter \(chNum) have not been read from kdb.sqlite")
		}
	}

	// Can be called when the current VerseItem is Verse 1 of a Psalm
	func createAscription () {
		let newitemID = dao!.verseItemsInsertRec (chID, 1, "Ascription", 70, "", 0, false, 0)
		if newitemID != -1 {
			print ("Ascription created")
			// Note that the Psalm now has an Ascription
			hasAscription = true
			// Increment number of items
			numIt = numIt + 1
			// Make the new Ascription the current VerseItem
			currIt = newitemID
			// Update the database Chapter record so that the new Ascription item becomes the current item
			if dao!.chaptersUpdateRecPub (chID, numIt, newitemID) {
//				print ("Chapter:createAscription updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:createAscription ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		} else {
			print ("Chapter:createAscription ERROR inserting into database")
		}
	}

	// Can be called when the current VerseItem is an Ascription
	func deleteAscription () {
		if dao!.itemsDeleteRec(currIt) {
			print("Ascription deleted")
			// Note that the Psalm no longer has an Ascription
			hasAscription = false
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			if dao!.chaptersUpdateRecPub (chID, numIt, currIt) {
//				print ("Chapter:deleteAscription updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:deleteAscription ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		}
	}

	// Create Book title
	func createTitle() {
		let newitemID = dao!.verseItemsInsertRec (chID, 1, "Title", 10, "", 0, false, 0)
		if newitemID != -1 {
			print ("Title for Book created")
			// Note that the Book now has a Title
			hasTitle = true
			// Increment number of items
			numIt = numIt + 1
			// Make the new Title the current VerseItem
			currIt = newitemID
			// Update the database Chapter record so that the new Title item becomes the current item
			if dao!.chaptersUpdateRecPub (chID, numIt, newitemID) {
//				print ("Chapter:createTitle updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:createTitle ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		} else {
			print ("Chapter:createTitle ERROR inserting into database")
		}
	}

	// Can be called when the current VerseItem is a Title
	func deleteTitle () {
		if dao!.itemsDeleteRec(currIt) {
			print("Title deleted")
			// Note that the Psalm no longer has a Title
			hasTitle = false
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			if dao!.chaptersUpdateRecPub (chID, numIt, currIt) {
//				print ("Chapter:deleteTitle updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:deleteTitle ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		}
	}


	// Create a paragraph break before a verse.
	func createParagraphBefore () {
		let vsNum = BibItems[currItOfst].vsNum
		let newitemID = dao!.verseItemsInsertRec (chID, vsNum, "Para", vsNum * 100 - 10, "", 0, false, 0)
		if newitemID != -1 {
			print ("Para Before created")
			// Increment number of items
			numIt = numIt + 1
			// Leave the Verse as the current VerseItem (there is nothing to keyboard in the Para record)
			// but increment the number of VerseItems
			if dao!.chaptersUpdateRecPub (chID, numIt, currIt) {
//				print ("Chapter:createParagraphBefore updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:createParagraphBefore ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		} else {
			print ("Chapter:createParagraphBefore ERROR inserting into database")
		}
	}

	// Can be called when the current VerseItem is a Para
	func deleteParagraphBefore () {
		if dao!.itemsDeleteRec(currIt) {
			print("Para deleted")
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			if dao!.chaptersUpdateRecPub (chID, numIt, currIt) {
//				print ("Chapter:deleteParagraphBefore updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:deleteParagraphBefore ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		}
	}

	// Create a paragraph break inside a verse
	func createParagraphCont() {
		let result = appDelegate.VTVCtrl!.currTextSplit()
		let txtBef = result.txtBef
		let txtAft = result.txtAft
		let vsNum = BibItems[currItOfst].vsNum
		// Remove text after cursor from Verse
		dao!.itemsUpdateRecText(BibItems[currItOfst].itID, txtBef)
		// Create the ParaCont record
		let newPContID = dao!.verseItemsInsertRec (chID, vsNum, "ParaCont", vsNum * 100 + 10, "", 0, false, 0)
		if newPContID != -1 {
			print ("ParaCont created")
			// Increment number of items
			numIt = numIt + 1
		} else {
			print ("Chapter:createParagraphCont ERROR inserting ParaCont into database")
		}
		// Create the VerseCont record and insert the txtAft from the original Verse
		let newVCont = dao!.verseItemsInsertRec (chID, vsNum, "VerseCont", vsNum * 100 + 20, txtAft, 0, false, 0)
		if newVCont != -1 {
			print ("VerseCont created")
			// Increment number of items
			numIt = numIt + 1
			// Update the database Chapter record so that the new VerseCont becomes the current item
			if dao!.chaptersUpdateRecPub (chID, numIt, newVCont) {
//				print ("Chapter:createParagraphCont updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:createParagraphCont ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		} else {
			print ("Chapter:createParagraphCont ERROR inserting VerseCont into database")
		}
	}

	func deleteParagraphCont() {
		let prevItem = BibItems[currItOfst - 1]
		let nextItem = BibItems[currItOfst + 1]
		let prevItID = prevItem.itID
		// Delete ParaCont record
		dao!.itemsDeleteRec(currIt)
		numIt = numIt - 1
		// Append continuation text to original Verse
		let txtBef = prevItem.itTxt
		let txtAft = nextItem.itTxt
		dao!.itemsUpdateRecText(prevItem.itID, txtBef + txtAft)
		// Delete VerseCont record
		dao!.itemsDeleteRec(nextItem.itID)
		numIt = numIt - 1
		// Update the database Chapter record so that the original VerseItem becomes the current item
		if dao!.chaptersUpdateRecPub (chID, numIt, prevItID) {
//				print ("Chapter:deleteParagraphCont updated \(bkInst!.bkName) \(chNum) Chapter record")
		} else {
			print ("Chapter:deleteParagraphCont ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
		}
	}

	func createSubjHeading() {
		let vsNum = BibItems[currItOfst].vsNum
		let newitemID = dao!.verseItemsInsertRec (chID, vsNum, "Heading", vsNum * 100 - 20, "", 0, false, 0)
		if newitemID != -1 {
			print ("Subject Heading created")
			// Increment number of items
			numIt = numIt + 1
			// Make the new Subject Heading the current VerseItem
			currIt = newitemID
			// Update the database Chapter record so that the new Subject Heading item becomes the current item
			if dao!.chaptersUpdateRecPub (chID, numIt, newitemID) {
//				print ("Chapter:createSubjHeading updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:createSubjHeading ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		} else {
			print ("Chapter:createSubjHeading ERROR inserting into database")
		}
	}

	// Can be called when the current VerseItem is a Subject Heading
	func deleteSubjHeading () {
		if dao!.itemsDeleteRec(currIt) {
			print("Subj Heading deleted")
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			if dao!.chaptersUpdateRecPub (chID, numIt, currIt) {
//				print ("Chapter:deleteSubjHeading updated \(bkInst!.bkName) \(chNum) Chapter record")
			} else {
				print ("Chapter:deleteSubjHeading ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
			}
		}
	}

	// This function uses the current values in BibItems[] but makes changes in
	// the database via KITDAO. After the database changes have been made,
	//  BibItems[] will be refreshed from KITDAO.
	func bridgeNextVerse() {
		// Get the vsNum and iTxt from  the verse to be added to the bridge
		let nexVsNum = BibItems[currItOfst + 1].vsNum
		let nexVsTxt = BibItems[currItOfst + 1].itTxt
		// Delete the verse record being added to the bridge
		dao!.itemsDeleteRec(BibItems[currItOfst + 1].itID)
		numIt = numIt - 1
		// Create related BridgeItems record
		let curVsItID = BibItems[currItOfst].itID
		let curVsTxt = BibItems[currItOfst].itTxt
		let bridID = dao!.bridgeInsertRec(curVsItID, curVsTxt, nexVsTxt)
		// Copy text of next verse into the bridge head verse
		let newBridHdTxt = curVsTxt + " " + nexVsTxt
		dao!.itemsUpdateForBridge(curVsItID, newBridHdTxt, true, nexVsNum)
		// Update the database Chapter record so that the bridge head VerseItem remains the current item
		// and the number of items is updated
		if dao!.chaptersUpdateRecPub (chID, numIt, curVsItID) {
//				print ("Chapter:bridgeNextVerse updated \(bkInst!.bkName) \(chNum) Chapter record")
		} else {
			print ("Chapter:bridgeNextVerse ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
		}
	}

	struct BridItem {
		var BridgeID: Int			// ID of the BridgeItems record
		var textCurrBridge: String	// text of current Verse or bridge
		var textExtraVerse: String	// text of extra verse added to bridge

		init (_ BridgeID:Int, _ textCurrBridge:String, _ textExtraVerse:String) {
			self.BridgeID = BridgeID
			self.textCurrBridge = textCurrBridge
			self.textExtraVerse = textExtraVerse
		}
	}
	
	var BridItems: [BridItem] = []

	// dao.bridgeGetRecs() calls appendItemToBridArray() for each row it reads from
	// the BridgeItems table in the kdb.sqlite database

	func appendItemToBridArray(_ BridgeID:Int, _ textCurrBridge:String, _ textExtraVerse:String) {
			let bridRec = BridItem(BridgeID, textCurrBridge, textExtraVerse)
			BridItems.append(bridRec)
		}

	// This function uses the current values in BibItems[] but makes changes in
	// the database via KITDAO. After the database changes have been made,
	//  BibItems[] will be refreshed from KITDAO.
	func unbridgeLastVerse() {
		// Get the most recent BridgeItems record for this verse
		let result = dao!.bridgeGetRecs(BibItems[currItOfst].itID, self)
		if result {
			print("BridgeItems records for verse \(BibItems[currItOfst].vsNum) have been read from kdb.sqlite")
		} else {
			print("ERROR: BridgeItems records for verse \(BibItems[currItOfst].vsNum) have not been read from kdb.sqlite")
		}
		// The most recent bridge item will be the last in the list
		let curBridItem = BridItems.last
		// Create the verse record being removed from the bridge
		let nextVsNum = BibItems[currItOfst].lvBrg
		if dao!.verseItemsInsertRec (chID, nextVsNum, "Verse", 100 * nextVsNum, curBridItem!.textExtraVerse, 0, false, 0) != -1 {
//				print("Chapter:createItemRecords Created Verse record for chap \(chNum) vs \(nextVsNum)")
		} else {
			print("ERROR: Book:createItemRecords: Creating Verse record failed for chap \(chNum) vs \(nextVsNum)")
		}
		numIt = numIt + 1
		// Copy text of the previous bridge head into the new bridge head
		var isBrid: Bool
		var lastVsBr = BibItems[currItOfst].lvBrg - 1
		if lastVsBr == BibItems[currItOfst].vsNum {
			// The head of the bridge will become a normal verse
			isBrid = false; lastVsBr = 0
		} else {
			// The head of the bridge will still be a bridge head
			isBrid = true
		}
		dao!.itemsUpdateForBridge(BibItems[currItOfst].itID, curBridItem!.textCurrBridge, isBrid, lastVsBr)
		// Delete this BridgeItems record
		dao!.bridgeDeleteRec(curBridItem!.BridgeID)
		// Update the database Chapter record so that the bridge head VerseItem remains the current item
		// and the number of items is updated
		if dao!.chaptersUpdateRecPub (chID, numIt, BibItems[currItOfst].itID) {
//				print ("Chapter:unbridgeLastVerse updated \(bkInst!.bkName) \(chNum) Chapter record")
		} else {
			print ("Chapter:unbridgeLastVerse ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
		}
	}
	
	// Generate USFM export string for this Chapter
	func calcUSFMExportText() -> String {
		var USFM = "\\id " + bkInst!.bkCode + " " + bibInst!.bibName + "\n\\c " + String(chNum)
		for i in 0...(BibItems.count - 1) {
			var s: String
			var vn: String
			let item = BibItems[i]
			let tx: String = item.itTxt
			switch item.itTyp {
			case "Verse":
				if item.isBrg {
					vn = String(item.vsNum) + "-" + String(item.lvBrg)
				} else {
					vn = String(item.vsNum)
				}
				s = "\n\\v " + vn + " " + tx
			case "VerseCont":
				s = "\n" + tx
			case "Para", "ParaCont":		// Paragraph before or within a verse
				s = "\n\\p"
			case "Heading":			// Heading/Subject Heading
				s = "\n\\s " + tx
			case "ParlRef":			// Parallel Reference
				s = "\n\\r " + tx
			case "Title":			// Title for a Book
				s = "\n\\mt " + tx
			case "InTitle":			// Title within Book introductory matter
				s = "\n\\imt " + tx
			case "InSubj":			// Subject heading within Book introductory matter
				s = "\n\\ims " + tx
			case "InPara":			// Paragraph within Book introductory matter
				s = "\n\\ip " + tx
			case "Ascription":		// Ascriptions before verse 1 of some Psalms
				s = "\n\\d " + tx
			default:
				s = ""
			}
			USFM = USFM + s
		}
		return USFM
	}

	func saveUSFMText (_ chID:Int, _ text:String) -> Bool {
		return dao!.updateUSFMText (chID, text)
	}
}
