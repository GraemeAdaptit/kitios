//
//  KIT02DAO.swift
//  KIT02
//
//  Created by Graeme Costin on 16/9/19.
//  Copyright © 2019 Costin Computing Services. All rights reserved.
//
//	All interaction between the running app and the SQLite database is handled by this class.
//	The rest of the app can treat the SQLite database as a software object with interaction
//	directed through the member functions of the KITDAO class which is named from the phrase
//	KIT Data Access Object.
//
//	Parameters passed to KITDAO's functions are in the natural types for the programming
//	language of the rest of the app; any conversion to or from data types that SQLite requires
//	is handled within this class.
//
//	This class is instantiated at the launching of the app and it opens a connection to the
//	database, keeps that connection in the class variable db and retains it until the app
//	terminates. Only one instance of the class is used.
//
//	TODO: Check whether interruption of the app (such as by a phone call coming to the
//	smartphone) needs the database connection to be closed and then reopened when the app
//	returns to the foreground.

import UIKit

public class KITDAO:NSObject {

	let dbName = "kdb.sqlite"
	let dirManager = FileManager.default
	var db: OpaquePointer?
	
	internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

	override init() {

		do {
			print("Entering init() of KITDAO object")
			let directoryURL = try! dirManager.url(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: true)

			let dbPath = directoryURL.appendingPathComponent(dbName)
			if sqlite3_open(dbPath.absoluteString.cString(using: String.Encoding.utf8)!, &db) == SQLITE_OK {
				print("kdb.sqlite has been opened")
			} else {
				print("kdb.sqlite could not be opened")
			}
		}
		// The FileManager function will always find a Documents directory for the app and
		// thus there will be no error thrown
		//catch let err as NSError {
			//print("Error: \(err.domain)")
			// What should happen after this extremely unlikely error???
		//}
		print("The KITDAO instance has been created")

	}

	// Ensure that the kdb.sqlite database is closed
	deinit {
		if sqlite3_close(db) == SQLITE_BUSY {
			print ("kdb.sqlite close result was SQLITE_BUSY")
		} else {
			print ("kdb.sqlite database has been closed")
		}
	}

	//--------------------------------------------------------------------------------------------
	//	Bibles data table

	// The single record in the Bibles table needs to be read when the app launches to find out
	//	* whether the Books records need to be created (on first launch) or
	//	* what is the current Book (on subsequent launches)
	
	func bibleGetRec () -> (bibID:Int, bibName:String, bkRCr:Bool, currBk:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT bibleID, name, bookRecsCreated, currBook FROM Bibles;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_step(sqlite3_stmt)
		let bID = Int(sqlite3_column_int(sqlite3_stmt, 0))
		let bNamep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 1)
		let bNamen = Int(sqlite3_column_bytes(sqlite3_stmt,1))
		let data = Data(bytes: bNamep!, count: Int(bNamen))
		let str = String(data: data, encoding: String.Encoding.utf8)
		let bkC = Int(sqlite3_column_int(sqlite3_stmt, 2))
		let cBk = Int(sqlite3_column_int(sqlite3_stmt, 3))
		return (bID, str!, (bkC > 0 ? true : false), cBk)
	}

	// The single record needs to be updated
	//  * to set a new name for the Bible at the user's command
	//	* to set the flag that indicates that the Books records have been created (on first launch)
	//	* to change the current Book whenever the user selects a different Book to work on

	// This function needs a String parameter for the revised Bible name
	func bibleUpdateName (_ bibName:String) -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Bibles SET name = ?1 WHERE bibleID = 1;"
		let nByte:Int32 = Int32(sql.utf8.count)
				
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_text(sqlite3_stmt, 1, bibName.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	// The bookRecsCreated flag starts as false and is changed to true during the first launch;
	// it is never changed back to false, and so this function does not need any parameters.
	func bibleUpdateRecsCreated () -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Bibles SET bookRecsCreated = 1 WHERE bibleID = 1;"
		let nByte:Int32 = Int32(sql.utf8.count)
		
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	// This function needs an Integer parameter for the current Book
	func bibleUpdateCurrBook (_ bookID: Int) -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Bibles SET currBook = ?1 WHERE bibleID = 1;"
		let nByte:Int32 = Int32(sql.utf8.count)
		
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bookID))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	//--------------------------------------------------------------------------------------------
	//	Books data table

	// The 66 records for the Books table need to be created and populated on the initial launch of the app
	// This function will be called 66 times by the KIT software
	
	func booksInsertRec (_ bkID:Int,_ bibID:Int, _ bkCode:String, _ bkName:String, _ chRCr:Bool, _ numCh:Int, _ currChap:Int) -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "INSERT INTO Books(bookID, bibleID, bookCode, bookName, chapRecsCreated, numChaps, currChapter) VALUES(?, ?, ?, ?, ?, ?, ?);"
		let nByte:Int32 = Int32(sql.utf8.count)
		
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bkID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bibID))
		sqlite3_bind_text(sqlite3_stmt, 3, bkCode.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_bind_text(sqlite3_stmt, 4, bkName.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_bind_int(sqlite3_stmt, 5, Int32((chRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 6, Int32(numCh))
		sqlite3_bind_int(sqlite3_stmt, 7, Int32(currChap))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	// The Books records need to be read to populate the array of books for the Bible bib
	// that the user can choose from. They need to be sorted in ascending order of the UBS
	// assigned bookID.
	func readBooksRecs (bibInst: Bible) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT bookID, bibleID, bookCode, bookName, chapRecsCreated, numChaps, currChapter FROM Books ORDER BY bookID;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		while (sqlite3_step(sqlite3_stmt) == SQLITE_ROW) {
			// convert fields as needed
			let bkID = Int(sqlite3_column_int(sqlite3_stmt, 0))
			let bibID = Int(sqlite3_column_int(sqlite3_stmt, 1))
			let bCodep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 2)
			let bCoden = Int(sqlite3_column_bytes(sqlite3_stmt,2))
			let dCode = Data(bytes: bCodep!, count: Int(bCoden))
			let sCode = String(data: dCode, encoding: String.Encoding.utf8)
			let bNamep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 3)
			let bNamen = Int(sqlite3_column_bytes(sqlite3_stmt,3))
			let dName = Data(bytes: bNamep!, count: Int(bNamen))
			let sName = String(data: dName, encoding: String.Encoding.utf8)
			let cRC = Int(sqlite3_column_int(sqlite3_stmt, 4))
			let chRCr = (cRC == 0 ? false : true)
			let numCh = Int(sqlite3_column_int(sqlite3_stmt, 5))
			let curCh = Int(sqlite3_column_int(sqlite3_stmt, 6))

			bibInst.appendBibBookToArray(bkID, bibID, sCode!, sName!, chRCr, numCh, curCh)
		}
		sqlite3_finalize(sqlite3_stmt)
	}
	
	// The Books record for the current Book needs to be read when the user selects that Book
	//	* to find out whether the current Book's Chapters records have been created
	//	* to find out whether there is a current Chapter to go to
	// TODO: Check whether this function is needed; these data items are already there and
	//	are updated as they change during running of the app?
	
	func booksGetRec () -> Bool {
		return true
	}

	// The Books record for the current Book needs to be updated
	//	* to set the flag that indicates that the Chapter records have been created (on first edit of that Book)
	//	* to set the number of Chapters in the Book (on first edit of that Book)
	//	* to change the current Chapter when the user selects a different Chapter to work on

	func booksUpdateRec (_ bibID:Int, _ bkID:Int, _ chRCr:Bool, _ numCh:Int, _ currCh:Int) -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Books SET chapRecsCreated = ?3, numChaps = ?4, currChapter = ?5 WHERE bibleID = ?1 AND bookID = ?2;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bkID))
		sqlite3_bind_int(sqlite3_stmt, 3, Int32((chRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 4, Int32(numCh))
		sqlite3_bind_int(sqlite3_stmt, 5, Int32(currCh))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	//--------------------------------------------------------------------------------------------
	//	Chapters data table

	// The Chapters records for the current Book need to be created when the user first selects that Book to edit
	// This function will be called once by the KIT software for every Chapter in the current Book; it will be
	// called before any VerseItem Records have been created for the Chapter

	func chaptersInsertRec (_ bibID:Int, _ bkID:Int, _ chNum:Int, _ itRCr:Bool, _ numVs:Int, _ numIt:Int, _ currIt:Int) -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "INSERT INTO Chapters(bibleID, bookID, chapterNumber, itemRecsCreated, numVerses, numItems, currItem) VALUES(?, ?, ?, ?, ?, ?, ?);"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bkID))
		sqlite3_bind_int(sqlite3_stmt, 3, Int32(chNum))
		sqlite3_bind_int(sqlite3_stmt, 4, Int32((itRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 5, Int32(numVs))
		sqlite3_bind_int(sqlite3_stmt, 6, Int32(numIt))
		sqlite3_bind_int(sqlite3_stmt, 7, Int32(currIt))

		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	// The Chapters records for the currently selected Book need to be read to populate the array
	// of Chapters for the Book bkInst that the user can choose from. The records need to be sorted
	// in ascending order of chapterNumber
	func readChaptersRecs (_ bibID:Int,_ bkInst:Book) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT chapterID, bibleID, bookID, chapterNumber, itemRecsCreated, numVerses, numItems, currItem FROM Chapters WHERE bibleID = ?1 AND bookID = ?2 ORDER BY chapterNumber;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bkInst.bkID))
		while (sqlite3_step(sqlite3_stmt) == SQLITE_ROW) {
			// convert fields as needed
			let chapID = Int(sqlite3_column_int(sqlite3_stmt, 0))
			let bibID = Int(sqlite3_column_int(sqlite3_stmt, 1))
			let bookID = Int(sqlite3_column_int(sqlite3_stmt, 2))
			let chNum = Int(sqlite3_column_int(sqlite3_stmt, 3))
			let itRC = Int(sqlite3_column_int(sqlite3_stmt, 4))
			let itRCr = (itRC == 0 ? false : true)
			let numVs = Int(sqlite3_column_int(sqlite3_stmt, 5))
			let numIt = Int(sqlite3_column_int(sqlite3_stmt, 6))
			let curIt = Int(sqlite3_column_int(sqlite3_stmt, 7))

			bkInst.appendChapterToArray(chapID, bibID, bookID, chNum, itRCr, numVs, numIt, curIt)
		}
		sqlite3_finalize(sqlite3_stmt)
	}

	// The Chapters record for the current Chapter needs to be read when the user selects that Chapter
	//	* to find out whether the current Chapter's VerseItems records have been created (on first edit of that Chapter)
	//	* to find out whether there is a current VerseItem to go to
	// TODO: Check whether this function is needed; these data items are already there and
	//	are updated as they change during running of the app?

	func chaptersGetRec() -> Bool {
		return true
	}

	// The Chapters record for the current Chapter needs to be updated
	//	* to set the flag that indicates that the VerseItem records have been created (on first edit of that Chapter)
	//	* to change the current VerseItem when the user selects a different VerseItem to work on

	func chaptersUpdateRec (_ chID:Int, _ itRCr:Bool, _ currIt:Int) -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Chapters SET itemRecsCreated = ?2, currItem = ?3 WHERE chapterID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(chID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32((itRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 3, Int32(currIt))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	// TODO: Implement a functions to set the value of the field USFMText when the Export scene is used
	// TODO: Implement a function to retrieve the value of the USFMText field when needed

	//--------------------------------------------------------------------------------------------
	//	VerseItems data table

	// The VerseItems records for the current Chapter need to be created when the user first selects that Chapter
	// This function will be called once by the KIT software for every VerseItem in the current Chapter
	// It will also be called
	//	* when the user chooses to insert a publication VerseItem
	//	* when the user chooses to undo a verse bridge

	func verseItemsInsertRec (_ chID:Int, _ vsNum:Int, _ itTyp:String, _ itOrd:Int, _ itText:String, _ intSeq:Int, _ isBrid:Bool) -> Bool {
			var sqlite3_stmt:OpaquePointer?=nil
			let sql:String = "INSERT INTO VerseItems(chapterID, verseNumber, itemType, itemOrder, itemText, intSeq, isBridge) VALUES(?, ?, ?, ?, ?, ?, ?);"
			let nByte:Int32 = Int32(sql.utf8.count)

			sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
			sqlite3_bind_int(sqlite3_stmt, 1, Int32(chID))
			sqlite3_bind_int(sqlite3_stmt, 2, Int32(vsNum))
			sqlite3_bind_text(sqlite3_stmt, 3, itTyp.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
			sqlite3_bind_int(sqlite3_stmt, 4, Int32(itOrd))
			sqlite3_bind_text(sqlite3_stmt, 5, itText.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
			sqlite3_bind_int(sqlite3_stmt, 6, Int32(intSeq))
			sqlite3_bind_int(sqlite3_stmt, 7, Int32((isBrid ? 1 : 0)))
			sqlite3_step(sqlite3_stmt)
			let result = sqlite3_finalize(sqlite3_stmt)
			return (result == 0 ? true : false)
		}

	// The VerseItems records for the current Chapter needs to be read in order to set up the scrolling display of
	// VerseItem records that the user interacts with. These records need to be sorted in ascending order of itemOrder.

	func readVerseItemsRecs (_ chInst:Chapter) -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT itemID, chapterID, verseNumber, itemType, itemOrder, itemText, intSeq, isBridge FROM VerseItems WHERE chapterID = ?1 ORDER BY itemOrder;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(chInst.chID))
		while (sqlite3_step(sqlite3_stmt) == SQLITE_ROW) {
			// convert fields as needed
			let itID = Int(sqlite3_column_int(sqlite3_stmt, 0))
			let chID = Int(sqlite3_column_int(sqlite3_stmt, 1))
			let vsNum = Int(sqlite3_column_int(sqlite3_stmt, 2))
			let bCodep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 3)
			let bCoden = Int(sqlite3_column_bytes(sqlite3_stmt,3))
			let dCode = Data(bytes: bCodep!, count: Int(bCoden))
			let itTyp = String(data: dCode, encoding: String.Encoding.utf8)!
			let itOrd = Int(sqlite3_column_int(sqlite3_stmt, 4))
			let cCodep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 5)
			let cCoden = Int(sqlite3_column_bytes(sqlite3_stmt,5))
			let cCode = Data(bytes: cCodep!, count: Int(cCoden))
			let itText = String(data: cCode, encoding: String.Encoding.utf8)!
			let intSeq = Int(sqlite3_column_int(sqlite3_stmt, 6))
			let isBr = Int(sqlite3_column_int(sqlite3_stmt, 7))
			let isBrg = (isBr == 0 ? false : true)

			chInst.appendItemToArray(itID, chID, vsNum, itTyp, itOrd, itText, intSeq, isBrg, 0)
		}
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	// The text of a VerseItem record in the UITableView needs to be updated
	//	* when the user selects a different VerseItem to work on
	//	* when the VerseItem cell scrolls outside the visible range

	func itemsUpdateRecText (_ itID:Int, _ itTxt:String) -> Bool {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE VerseItems SET itemText = ?2 WHERE itemID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(itID))
		sqlite3_bind_text(sqlite3_stmt, 2, itTxt.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		return (result == 0 ? true : false)
	}

	// The VerseItem record for a publication VerseItem needs to be deleted when the user chooses to delete a publication item
	// This function will also be called when the user chooses to bridge two verses (the contents of the second verse is
	//	appended to the first verse, the second verse text is put into a new BridgeItem, and then the second VerseItem is
	//	deleted. Unbridging follows the reverse procedure and the original second verse is re-created and the BridgeItem
	//	is deleted

	func itemsDeleteRec () -> Bool {
		return true
	}

	//--------------------------------------------------------------------------------------------
	// BridgeItems data table

	// When a bridge is created a BridgeItem record is created to hold the following verse that is being appended
	// to the bridge. This is needed only if the user later undoes the bridge and the original following verse is
	// restored; otherwise the BridgeItem record just sits there out of the way of normal operations.

	func bridgeInsertRec() -> Bool {
		return true
	}

	// When a bridge is being undone it is necessary to retrieve the record containing the original following verse
	// that is about to be restored.

	func bridgeGetRec() -> Bool {
		return true
	}

	// When a bridge has been undone the BridgeItem record involved needs to be deleted

	func bridgeDeleteRec() -> Bool {
		return true
	}

}
