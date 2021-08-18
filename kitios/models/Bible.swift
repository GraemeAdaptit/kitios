//
//  Bible.swift
//
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//	GDLC 12MAR20 Updated for KIT05
//
//  Created by Graeme Costin on 9OCT19.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.
//
// This source file deals with the class Bible of which one instance will be created.
// The initialisation of this single instance will
// 1. Open the kdb.sqlite database
// 2. On first launch create the Books records in the kdb.sqlite database
// 3. On every launch read the Books records from kdb.sqlite and set up the array bibBooks
//    whose life is for the duration of this run of KIT
// 4. Do the other initialisations needed to build the partial in-memory data for the
//    Bible -> curr Book -> curr Chapter -> curr VerseItem data structures.

import UIKit

public class Bible:NSObject {

// The following variables and data structures have lifetimes of the Bible object
// which is also the lifetime of this run of the app
	
	var dao: KITDAO?
	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	
	// MARK: Properties

// Safe initialisations of the four Properties of the Bible record
	var bibID: Int = 1	// Bible ID - always 1 for KIT v1
	var bibName: String = "Bible"	// Bible name
	var bkRCr: Bool = false	// true if the Books records for this Bible have been created
	var currBook: Int = 0	// current Book ID (defined by the Bible Societies 1 to 39 OT and 41 to 67 NT)

	var currBookOfst = -1	// Offset in BibBooks[] to the current book 0 to 38 (OT) 39 to 65 (NT)
	var bookInst: Book?		// Instance in memory of the current Book - this is the strong ref that owns it
	
// BibBooks array (for listing the Books so the user can choose one)
	struct BibBook {
		var bkID: Int		// bookID INTEGER
		var bibID: Int		// bibleID INTEGER
		var bkCode: String	// bookCode TEXT
		var bkName: String	// bookName TEXT
		var chapRCr: Bool	// chapRecsCreated INTEGER
		var numCh: Int		// numChaps INTEGER
		var curChID: Int	// currChID INTEGER  the ChapterID
		var curChNum: Int	// currChNum INTEGER  the Chapter number
		init (_ bkID: Int, _ bibID: Int, _ bkCode: String, _ bkName: String, _ chapRCr: Bool, _ numCh: Int, _ curChID: Int, _ curChNum: Int) {
			self.bkID = bkID
			self.bibID = bibID
			self.bkCode = bkCode
			self.bkName = bkName
			self.chapRCr = chapRCr
			self.numCh = numCh
			self.curChID = curChID
			self.curChNum = curChNum
		}
	}

	var BibBooks: [BibBook] = []

// Initialisation of the single instance of class Bible with an array of Books to select from
//	init()
//		createBooksRecords()
//		appendBibBookToArray()  - called by dao.readBooksRecs()
	
	init(_ bID:Int, _ bName:String, _ bkRCr:Bool, _ currBk:Int) {
		super.init()
		dao = appDelegate.dao!	// Get access to the instance of the Data Access Object
		
		self.bibID = bID
		self.bibName = bName
		self.bkRCr = bkRCr
		self.currBook = currBk
		currBookOfst = (currBook > 39 ? currBook - 2 : currBook - 1 )

		// First launch: the Books records will not have been created so create them
		if !bkRCr {
			// Create the 66 Book records for this Bible
			createBooksRecords(bID)
		}

		// Every launch: the Books records will have been created at this point,
		// so set up the array BibBooks by reading the 66 Books records from kdb.sqlite.
		// This array will last for the current launch of the app and will be used
		// whenever the user is allowed to select a book; it will also be updated
		// when Chapters records for a book are created, and when the user chooses
		// a different Book to edit.
		dao!.readBooksRecs (bibInst: self)
		// calls readBooksRecs() in KITDAO.swift to read the kdb.sqlite database Books table
		// readBooksRecs() calls appendBibBookToArray() in this file for each ROW read from kdb.sqlite
	}
	
// createBooksRecords creates the Books records for every Bible book from the text files in the
// app's resources and stores these records in the database kdb.sqlite
	
	func createBooksRecords (_ bID: Int) {
		// Open KIT_BooksSpec.txt and read its data
		var specLines:[String] = []
		var nameLines:[String] = []
		var bookNames = [Int: String]()
		
		let booksSpec:URL = Bundle.main.url (forResource: "KIT_BooksSpec", withExtension: "txt")!
		do {
			let string = try String.init(contentsOf: booksSpec)
			specLines = string.components(separatedBy: .newlines)
		} catch  {
			print(error);
		}
		// Open KIT_BooksNames.txt and read its data
		let booksNames:URL = Bundle.main.url (forResource: "KIT_BooksNames", withExtension: "txt")!
		do {
			let namesStr = try String.init(contentsOf: booksNames)
			nameLines = namesStr.components(separatedBy: .newlines)
		} catch  {
			print(error);
		}
		// Make a look-up dictionary for book name given book ID number
		for nameItem in nameLines {
			if !nameItem.isEmpty {
				let nmStrs:[String] = nameItem.components(separatedBy: ", ")
				let i = Int(nmStrs[0])!
				let n = nmStrs[1]
				bookNames[i] = n
			}
		}
		
		// Step through the lines of KIT_BooksSpec.txt, creating the Book objects and
		// getting the book names from the look-up dictionary made from KIT_BooksNames.txt
		let hashMark:Character = "#"
		for spec in specLines {
			// Ignore empty lines and line starting with #
			if (!spec.isEmpty && spec[spec.startIndex] != hashMark) {
				// Create the Books record for this Book
				let bkStrs:[String] = spec.components(separatedBy: ", ")
				let bkID = Int(bkStrs[0])!
				let bibID = bID
				let bkCode:String = bkStrs[1]
				let bkName = bookNames[bkID]!
				let chRCr = false
				let numCh = 0
				let curChID = 0
				let curChNum = 0
				// Write Books record to kdb.sqlite
				if !dao!.booksInsertRec (bkID, bibID, bkCode, bkName, chRCr, numCh, curChID, curChNum) {
					appDelegate.ReportError(DBC_BooErr)
				}
			}
		}
		
		// Update the in-memory Bible record to note that Books recs have been created
		bkRCr = true
		
		// Update the kdb.sqlite Bible record to note that Books recs have been created
		do {
			try dao!.bibleUpdateRecsCreated()
		} catch {
			appDelegate.ReportError(DBU_BibRErr)
		}
//		if !dao!.bibleUpdateRecsCreated() {
//			appDelegate.ReportError(DBU_BibRErr)
//		}
	}

// dao.readBooksRecs() calls appendBibBookToArray() for each row it reads from the kdb.sqlite database
	
	func appendBibBookToArray (_ bkID:Int,_ bibID:Int, _ bkCode:String, _ bkName:String,
							   _ chapRCr:Bool, _ numCh:Int, _ curChID:Int, _ curChNum:Int) {
		let bkRec = BibBook(bkID, bibID, bkCode, bkName, chapRCr, numCh, curChID, curChNum)
		BibBooks.append(bkRec)
	}

// Deinitialise (delete) the instance of class Bible
// In v1 of KIT there will be only one Bible instance and it will be needed for the entire
// duration of the run of the app; thus deinit will not be used in v1.0 of KIT.
	
	deinit {
		// Delete the instance of the SQLite data access object
		dao = nil
		// Delete the instance of the Book
		bookInst = nil
		appDelegate.bookInst = nil
	}

// Refresh display of the Bible Books table on return to foreground
	
	func refreshUIAfterReturnToForeground () {
		// TODO: Check whether there anything to do here?
	}

// If there is a current Book (as read from kdb.sqlite) then instantiate that Book.
	func goCurrentBook () {
		let book = BibBooks[currBookOfst]

		// delete any previous in-memory instance of Book
		bookInst = nil
		appDelegate.bookInst = nil

		// Create a Book instance for the currently selected book
		// and copy the reference to the AppDelegate
		bookInst = Book(self, book.bkID, book.bibID, book.bkCode, book.bkName, book.chapRCr, book.numCh, book.curChID, book.curChNum)
		appDelegate.bookInst = bookInst
	}
	
// When the user selects a book from the UITableView of books it needs to be recorded as the
// current book and initialisation of data structures in a new Book instance must happen.
	func setupCurrentBook(_ book: BibBook) {
		currBook = book.bkID
		currBookOfst = (currBook > 39 ? currBook - 2 : currBook - 1 )
		// update Bible record in kdb.sqlite to show this current book
		if !dao!.bibleUpdateCurrBook(currBook) {
			appDelegate.ReportError(DBU_BibCErr)
		}

		// delete any previous in-memory instance of Book
		bookInst = nil
		appDelegate.bookInst = nil

		// Create a Book instance for the currently selected book
		// and copy the reference to the AppDelegate
		bookInst = Book(self, book.bkID, book.bibID, book.bkCode, book.bkName, book.chapRCr, book.numCh, book.curChID, book.curChNum)
		appDelegate.bookInst = bookInst
	}

// When the Chapter records have been created for the current Book, the entry for that Book in
// the Bible's BibBooks[] array must be updated. Once chapRCr is set true it will never go back to false
// (the kdb.sqlite records are not going to be deleted) so no parameter is needed for that,
// but a parameter is needed for the number of Chapters in the Book.

	func setBibBooksNumChap(_ numChap: Int) {
		BibBooks[currBookOfst].chapRCr = true
		BibBooks[currBookOfst].numCh = numChap
	}

	func getCurrBookOfst() -> Int {
		return (currBook > 39 ? currBook - 2 : currBook - 1 )
	}

// When a Chapter is selected as the current Chapter (in ChaptersTableViewController), the entry
// for the current Book in the Bible's BibBooks[] array must be updated.

	func setBibBooksCurChap(_ curChID: Int, _ curChNum: Int) {
		BibBooks[currBookOfst].curChID = curChID
		BibBooks[currBookOfst].curChNum = curChNum
	 }

}
