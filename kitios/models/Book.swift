//
//  Book.swift
//
//  Created by Graeme Costin on 25/10/19.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

// There will be one instance of this class for the currently selected Book.
// This instance will have a lifetime of the current book selection; its life
// will be terminated when the user selects a different Book to keyboard, at
// which time a new Book instance will be created for the newly selected Book.

import UIKit

public class Book:NSObject {
	
	var dao: KITDAO?		// access to the KITDAO instance for using kdb.sqlite
	var bibInst: Bible?		// access to the instance of Bible for updating BibBooks[]
	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate

// Properties of a Book instance (dummy values to avoid having optional variables)
	var bkID: Int = 0			// bookID INTEGER
	var bibID: Int = 0			// bibleID INTEGER
	var bkCode: String = "BCD"	// bookCode TEXT
	var bkName: String = "Book"	// bookName TEXT
	var chapRCr: Bool = false	// chapRecsCreated INTEGER
	var numChap: Int = 0		// numChaps INTEGER
	var currChap: Int = 0		// currChapter INTEGER (the ID assigned by SQLite when the Chapter was created)
	
	var currChapOfst: Int = 0	// offset to the current Chapter in BibChaps[] array
	
	// TODO: Eliminate the need for bibInst by using a setter function in Bible?
	var chapInst: Chapter?	// instance in memory of the current Chapter

// This struct and the BibChaps array are used for letting the user select the
// Chapter to keyboard in the current selected Book.

	struct BibChap {
		var chID: Int		// chapterID INTEGER PRIMARY KEY
		var bibID: Int		// bibleID INTEGER
		var bkID: Int		// bookID INTEGER
		var chNum: Int		// chapterNumber INTEGER
		var itRCr: Bool		// itemRecsCreated INTEGER
		var numVs: Int		// numVerses INTEGER
		var numIt: Int		// numItems INTEGER
		var curIt: Int		// currItem INTEGER
		init (_ chID:Int, _ bibID:Int, _ bkID:Int, _ chNum:Int, _ itRCr:Bool, _ numVs:Int, _ numIt:Int, _ curIt:Int) {
			self.chID = chID
			self.bibID = bibID
			self.bkID = bkID
			self.chNum = chNum
			self.itRCr = itRCr
			self.numVs = numVs
			self.numIt = numIt
			self.curIt = curIt
		}
	}

var BibChaps: [BibChap] = []

// When the instance of Bible creates the instance for the current Book it supplies the values for the
// currently selected book from the BibBooks array
	// Initialisation of an instance of class Book with an array of Chapters to select from
	// But the array of Chapters cannot be produced until a current Book is chosen, so this
	// action needs to be avoided until after there is a current Book. Thus Book.init() must
	// not be called before a current Book is chosen or has been read from kdb.sqlite.

	init(_ bkID: Int, _ bibID: Int, _ bkCode: String, _ bkName: String, _ chapRCr: Bool, _ numChaps: Int, _ currChap: Int) {
		super.init()
		print("start of Book.init() for \(bkName)")
		
		self.bkID = bkID			// bookID INTEGER
		self.bibID = bibID			// bibleID INTEGER
		self.bkCode = bkCode		// bookCode TEXT
		self.bkName = bkName		// bookName TEXT
		self.chapRCr = chapRCr		// chapRecsCreated INTEGER
		self.numChap = numChaps		// numChaps INTEGER
		self.currChap = currChap	// currChapter INTEGER

		// Access to the KITDAO instance for dealing with kdb.sqlite
		dao = appDelegate.dao
		// Access to the instance of Bible for dealing with BibInst[]
		bibInst = appDelegate.bibInst

		// First time this Book has been selected the Chapter records must be created
		if !chapRCr {
			createChapterRecords(bkID, bibID, bkCode)
		}

		// Every time this Book is selected: The Chapters records in kdb.sqlite will have been
		// created at this point (either during this occasion or on a previous occasion),
		// so we set up the array BibChaps of Chapters by reading the records from kdb.sqlite.
		//
		// This array will last while this Book is the currently selected Book and will
		// be used whenever the user is allowed to select a Chapter; it will also be updated
		// when VerseItem records for this Chapter are created, and when the user chooses
		// a different Chapter to edit.
		// Its life will end when the user chooses a different Book to edit.
		
		dao!.readChaptersRecs (bibID, self)
		// calls readChaptersRecs() in KITDAO.swift to read the kdb.sqlite database Books table
		// readChaptersRecs() calls appendChapterToArray() in this file for each ROW read from kdb.sqlite
		print("Chapter records for \(bkName) have been read from kdb.sqlite")
	}

// When the user chooses a different Book, the in-memory instance of the previous current Book and
// any instances owned by it need to be deleted
	deinit {
		// TODO: deinit any owned class instances - Chapters and VerseItems ??
		print("Book deinit() The previous current Book and its Chapters and VerseItems have been deleted from memory")
	}

	func createChapterRecords (_ book:Int, _ bib:Int, _ code:String) {
		
		var specLines:[String] = []

		// Open KIT_BooksSpec.txt and read its data
		let booksSpec:URL = Bundle.main.url (forResource: "KIT_BooksSpec", withExtension: "txt")!
		do {
			let string = try String.init(contentsOf: booksSpec)
			specLines = string.components(separatedBy: .newlines)
		} catch  {
			print(error);
		}
		// Find the line containing the String code
		var i: Int = 0
		while !specLines[i].contains(code) {
			i = i + 1
		}
		// Process that line to create the Chapter records for this Book
		var elements:[String] = specLines[i].components(separatedBy: ", ")
		elements.remove(at: 1)	// we already have the Book three letter code
		elements.remove(at: 0)	// we already have the Book ID
		numChap = elements.count

		// Create a Chapters record in kdb.sqlite for each Chapter in this Book
		var chNum = 1	// Start at Chapter 1
		let currIt = 0	// No current VerseItem yet
		for elem in elements {
			var numIt = 0
			var elemTr = elem		// for some Psalms a preceding "A" will be removed
			if elem.prefix(1) == "A" {
				numIt = 1	// 1 for the Psalm ascription
				elemTr = String(elem.suffix(elem.count - 1))	// remove the "A"
			}
			let numVs = Int(elemTr)!
			numIt = numIt + numVs	// for some Psalms numIt will include the ascription VerseItem
			if dao!.chaptersInsertRec (bib, book, chNum, false, numVs, numIt, currIt) {
				print("Book:createChapterRecords Created Chapter record for \(String(describing: bkName)) chapter \(chNum)")
			} else {
				print("Book:createChapterRecords: Creating Chapter record failed for \(String(describing: bkName)) chapter \(chNum)")
			}
			chNum = chNum + 1
		}
		// Update in-memory record of current Book to indicate that its Chapter records have been created
		chapRCr = true
		// numChap = numChap This was done when the count of elements in the chapters string was found
		
		// Update kdb.sqlite Books record of current Book to indicate that its Chapter records have been
		// created, the number of Chapters has been found, but there is not yet a current Chapter
		if dao!.booksUpdateRec (bibID, bkID, chapRCr, numChap, currChap) {
			print("Book:createChapterRecords updated the record for this Book")
		} else {
			print("Book:createChapterRecords updating the record for this Book failed")
		}
	
		// Update the entry in BibBooks[] for the current Book to show that its Chapter records have
		// been created and that its number of Chapters has been found
		bibInst!.setBibBooksNumChap(numChap)
	}

// dao.readChaptersRecs() calls appendChapterToArray() for each row it reads from the kdb.sqlite database
	func appendChapterToArray(_ chapID:Int, _ bibID:Int, _ bookID:Int,
							  _ chNum:Int, _ itRCr:Bool, _ numVs:Int, _ numIt:Int, _ curIt:Int) {
		let chRec = BibChap(chapID, bibID, bookID, chNum, itRCr, numVs, numIt, curIt)
		BibChaps.append(chRec)
	}

// Find the offset in BibChaps[] to the element having ChapterID withID.
// If out of range returns offset zero (first item in the array).

	func offsetToBibChap(withID: Int) -> Int {
		for i in 0...numChap-1 {
			if BibChaps[i].chID == withID {
				return i
			}
		}
		return 0
	}

// If, from kdb.sqlite, there is already a current Chapter for the current Book then go to it
// Go to the current BibChap
// This function is called by the ChaptersTableViewController to find out which Chapter
// in the current Book is the current Chapter, and to make the Book instance and
// the Book record remember that selection.
	func goCurrentChapter() {
		currChapOfst = offsetToBibChap(withID: currChap)
		print("Going to the current Chapter \(currChapOfst+1)")
		
		// delete any previous in-memory instance of Chapter
		chapInst = nil

		// create a Chapter instance for the current Chapter of the current Book
		let chap = BibChaps[currChapOfst]
		chapInst = Chapter(chap.chID, chap.bibID, chap.bkID, chap.chNum, chap.itRCr, chap.numVs, chap.numIt, chap.curIt)
		// Keep a reference in the AppDelegate
		appDelegate.chapInst = self.chapInst
		print("KIT has created an instance of class Chapter for the old current Chapter \(currChapOfst+1)")
	}

// When the user selects a Chapter from the UITableView of Chapters it needs to be recorded as the
// current Chapter and initialisation of data structures in a new Chapter instance must happen.
	
	func setupCurrentChapter(withOffset chapOfst: Int, _ diffChap:Bool) {
		let chap = BibChaps[chapOfst]
		print("Making chapter \(chap.chNum) the current Chapter")
		currChap = chap.chID
		currChapOfst = chapOfst
		// update Book record in kdb.sqlite to show this current Chapter
		if dao!.booksUpdateRec(bibID, bkID, chapRCr, numChap, currChap) {
			print("The currChap for \(bkName) in kdb.sqlite was updated to \(chap.chNum)")
			} else {
				print("ERROR: The currChap for \(bkName) in kdb.sqlite was not updated to \(chap.chNum)")
			}

		// If the user has changed to a different Chapter then
		// delete any previous in-memory instance of Chapter and create a new one
		if diffChap {
			chapInst = nil

			// create a Chapter instance for the current Chapter of the current Book
			chapInst = Chapter(chap.chID, chap.bibID, chap.bkID, chap.chNum, chap.itRCr, chap.numVs, chap.numIt, chap.curIt)
		}
		// Keep a reference in the AppDelegate
		appDelegate.chapInst = self.chapInst
		print("KIT has created an instance of class Chapter for the new current Chapter \(chap.chNum)")
	}

}
