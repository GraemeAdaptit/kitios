//
//  Book.swift
//
// There will be one instance of this class for the currently selected Book.
// This instance will have a lifetime of the current book selection; its life
// will be terminated when the user selects a different Book to keyboard, at
// which time a new Book instance will be created for the newly selected Book.
// Data changes made by the user are always saved directly to the database as
// well as held in this instance for further use while the user continues to
// work on this Book.

//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//	GDLC 1JUL21 Added currVsNum to Chapter records
//
//  Created by Graeme Costin on 25/10/19.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.


import UIKit

public class Book:NSObject {
	
	var dao: KITDAO?		// access to the KITDAO instance for using kdb.sqlite
	weak var bibInst: Bible?		// access to the instance of Bible for updating BibBooks[]
									// Passed as a parameter to Book's init()
	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate

// Properties of a Book instance (dummy values to avoid having optional variables)
	var bkID: Int = 0			// bookID INTEGER
	var bibID: Int = 0			// bibleID INTEGER
	var bkCode: String = "BCD"	// bookCode TEXT
	var bkName: String = "Book"	// bookName TEXT
	var chapRCr: Bool = false	// chapRecsCreated INTEGER
	var numChap: Int = 0		// numChaps INTEGER
	var curChID: Int = 0		// currChID INTEGER (the ID assigned by SQLite when the Chapter was created)
	var curChNum: Int = 0		// currChNum INTEGER
	var currChapOfst: Int = -1	// offset to the current Chapter in BibChaps[] array (-1 means not yet set)
	
	var chapInst: Chapter?	// instance in memory of the current Chapter
	var chapName: String?	// Name used for chapters (most books have "chapter", Psalms have "psalm")

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
		var curIt: Int		// currItem INTEGER (ID of current VerseItem
		var curVN: Int		// currVsNum INTEGER (verse number for curIt)
		init (_ chID:Int, _ bibID:Int, _ bkID:Int, _ chNum:Int, _ itRCr:Bool, _ numVs:Int, _ numIt:Int, _ curIt:Int, _ curVN:Int) {
			self.chID = chID
			self.bibID = bibID
			self.bkID = bkID
			self.chNum = chNum
			self.itRCr = itRCr
			self.numVs = numVs
			self.numIt = numIt
			self.curIt = curIt
			self.curVN = curVN
		}
	}

var BibChaps: [BibChap] = []

// When the instance of Bible creates the instance for the current Book it supplies the values for the
// currently selected book from the BibBooks array
	// Initialisation of an instance of class Book with an array of Chapters to select from
	// But the array of Chapters cannot be produced until a current Book is chosen, so this
	// action needs to be avoided until after there is a current Book. Thus Book.init() must
	// not be called before a current Book is chosen or has been read from kdb.sqlite.

	init(_ bInst: Bible, _ bkID: Int, _ bibID: Int, _ bkCode: String, _ bkName: String, _ chapRCr: Bool, _ numChaps: Int, _ curChID: Int, _ curChNum:Int) {
		super.init()
		
		self.bibInst = bInst
		self.bkID = bkID			// bookID INTEGER
		self.bibID = bibID			// bibleID INTEGER
		self.bkCode = bkCode		// bookCode TEXT
		self.bkName = bkName		// bookName TEXT
		self.chapRCr = chapRCr		// chapRecsCreated INTEGER
		self.numChap = numChaps		// numChaps INTEGER
		self.curChID = curChID		// currChID INTEGER
		self.curChNum = curChNum	// currChNum INTEGER
		if bkID == 19 {
			chapName = "psalm"
		} else {
			chapName = "chapter"
		}
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
		
		do {
			try dao!.readChaptersRecs (bibID, self)
		} catch {
			appDelegate.ReportError(DBR_ChaErr)
		}
		// calls readChaptersRecs() in KITDAO.swift to read the kdb.sqlite database Books table
		// readChaptersRecs() calls appendChapterToArray() in this file for each ROW read from kdb.sqlite
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
		let currVN = 0	// No current verse number yet
		for elem in elements {
			var numIt = 0
			var elemTr = elem		// for some Psalms a preceding "A" will be removed
			if elem.prefix(1) == "A" {
				numIt = 1	// 1 for the Psalm ascription
				elemTr = String(elem.suffix(elem.count - 1))	// remove the "A"
			}
			let numVs = Int(elemTr)!
			numIt = numIt + numVs	// for some Psalms numIt will include the ascription VerseItem
			do {
				try dao!.chaptersInsertRec (bib, book, chNum, false, numVs, numIt, currIt, currVN)
			} catch {
				appDelegate.ReportError(DBC_ChaErr)
			}
			chNum = chNum + 1
		}
		// Update in-memory record of current Book to indicate that its Chapter records have been created
		chapRCr = true
		
		// Update kdb.sqlite Books record of current Book to indicate that its Chapter records have been
		// created, the number of Chapters has been found, but there is not yet a current Chapter
		do {
			try dao!.booksUpdateRec (bibID, bkID, chapRCr, numChap, 0, 0)
		} catch {
			appDelegate.ReportError(DBU_BooErr)
		}
	
		// Update the entry in BibBooks[] for the current Book to show that its Chapter records have
		// been created and that its number of Chapters has been found
		bibInst!.setBibBooksNumChap(numChap)
	}

// dao.readChaptersRecs() calls appendChapterToArray() for each row it reads from the kdb.sqlite database
	func appendChapterToArray(_ chapID:Int, _ bibID:Int, _ bookID:Int,
							  _ chNum:Int, _ itRCr:Bool, _ numVs:Int, _ numIt:Int, _ curIt:Int, _ curVNm:Int) {
		let chRec = BibChap(chapID, bibID, bookID, chNum, itRCr, numVs, numIt, curIt, curVNm)
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
		currChapOfst = offsetToBibChap(withID: curChID)
		
		// delete any previous in-memory instance of Chapter
		chapInst = nil
		appDelegate.chapInst = nil

		// create a Chapter instance for the current Chapter of the current Book
		let chap = BibChaps[currChapOfst]
		chapInst = Chapter(self, chap.chID, chap.bibID, chap.bkID, chap.chNum, chap.itRCr, chap.numVs, chap.numIt, chap.curIt, chap.curVN)
		// Keep a reference in the AppDelegate
		appDelegate.chapInst = chapInst
	}

// When the user selects a Chapter from the UITableView of Chapters it needs to be recorded as the
// current Chapter and initialisation of data structures in a new Chapter instance must happen.
	
	func setupCurrentChapter(withOffset chapOfst: Int) {
		let newChap = (chapOfst != currChapOfst) || (curChNum == 0)
		let chap = BibChaps[chapOfst]
		curChNum = chap.chNum
		curChID = chap.chID		// ChapterID
		currChapOfst = chapOfst		// Chapter offset (1 less than Chapter Number seen by users)
		// update Book record in kdb.sqlite to show this current Chapter
		do {
			try dao!.booksUpdateRec(bibID, bkID, chapRCr, numChap, curChID, curChNum)
		} catch {
			appDelegate.ReportError(DBU_BooErr)
		}
		// Update the curChID and curChNum for this book in BibBooks[] in bInst
		bibInst!.setBibBooksCurChap(curChID, curChNum)

		// If the user has changed to a different Chapter then
		// delete any previous in-memory instance of Chapter and create a new one
		if newChap {
			chapInst = nil
			appDelegate.chapInst = nil

			// create a Chapter instance for the current Chapter of the current Book
			chapInst = Chapter(self, chap.chID, chap.bibID, chap.bkID, chap.chNum, chap.itRCr, chap.numVs, chap.numIt, chap.curIt, chap.curVN)
		}
		// Keep a reference in the AppDelegate
		appDelegate.chapInst = self.chapInst
	}

	// Set into Book's BibChaps[] the new value for the current VerseItem
	// Called when the user selects a VerseItem of the current Chapter
	func setCurVItem (_ curIt:Int, _ curVN:Int) {
		BibChaps[currChapOfst].curIt = curIt
		BibChaps[currChapOfst].curVN = curVN
	}

}
