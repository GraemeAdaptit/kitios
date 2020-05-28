//
//  Chapter.swift
//  KIT05
//
//  Created by Graeme Costin on 8/1/20.
//  Copyright © 2020 Costin Computing Services. All rights reserved.
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
	
	var currItOfst: Int = -1// offset to current item in BibItems[] and row in the TableView

//	var chDirty = false		// Whenever a verse of the chapter is edited chDirty is set true (use in UI)

	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	
	var dao: KITDAO?		// access to the KITDAO instance for using kdb.sqlite
	var bibInst: Bible? 	// access to the instance of Bible for updating BibBooks[]
	var bkInst: Book?		// access to the instance for the current Book

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

	}
	
// Create a VerseItem record in kdb.sqlite for each VerseItem in this Chapter
// If this is a Psalm and it has an ascription then numIt will be 1 greater than numVs.
// For all other VerseItems numIt will equal numVs at this early stage of building the app's data

	func createItemRecords() {
		// If there is a Psalm ascription then create it first.
		if numIt > numVs {
			let vsNum = 1
			let itTyp = "Ascription"
			let itOrd = 99
			let itText = ""
			let intSeq = 0
			let isBrid = false
			if dao!.verseItemsInsertRec (chID, vsNum, itTyp, itOrd, itText, intSeq, isBrid) {
//				print("Chapter:createItemRecords Created Verse record for chap \(chNum) vs \(vsNum)")
			} else {
				print("ERROR: Book:createItemRecords: Creating Verse record failed for chap \(chNum) vs \(vsNum)")
			}
		}
		for vsNum in 1...numVs {
			let itTyp = "Verse"
			let itOrd = 100*vsNum
			let itText = ""
			let intSeq = 0
			let isBrid = false
			if dao!.verseItemsInsertRec (chID, vsNum, itTyp, itOrd, itText, intSeq, isBrid) {
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

// Go to the current BibItem
// This function is called by the VersesTableViewController to find out which VerseItem
// in the current Chapter is the current VerseItem, and to create the Chapter instance and
// to make the Chapter record remember that selection.
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
		}
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

		// Update the database Chapter record
		if dao!.chaptersUpdateRec (chID, itRCr, currIt) {
//			print ("Chapter:goCurrentItem updated \(bkInst!.bkName) \(chNum) Chapter record")
		} else {
			print ("Chapter:goCurrentItem ERROR updating \(bkInst!.bkName) \(chNum) Chapter record")
		}
	}

	func setupCurrentItemFromTableRow(_ tableRow: Int) {
		currItOfst = tableRow
		currIt = BibItems[tableRow].itID
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
	
//	// Function saveCurrentBibItemText() assumes that the ItemText has been copied from the cell
//	// in the TableView to the BibItems[] element.
//	func saveCurrentBibItemText () {
//		if dao!.itemsUpdateRecText (BibItems[currItOfst].itID, BibItems[currItOfst].itTxt) {
//			print ("Chapter:saveCurrentItemText text of current item saved to kdb.sqlite")
//		} else {
//			print ("Chapter:saveCurrentItemText save of current item text to kdb.sqlite FAILED")
//		}
//	}

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
			case "Para", "ParaCont":
				s = "\n\\p "
			case "Heading":
				s = "\n\\s " + tx
			case "ParlRef":
				s = "\n\\r " + tx
			case "Title":
				s = "\n\\mt " + tx
			case "InTitle":
				s = "\n\\imt " + tx
			case "InSubj":
				s = "\n\\ims " + tx
			case "InPara":
				s = "\n\\ip " + tx
			case "DesTitle":
				s = "\n\\d " + tx
			case "Ascription":
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
