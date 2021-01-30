//
//  VItem.swift
//  kitios
//
//  Created by Graeme Costin on 7/4/20.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.
//
//	NOTE: This is what I planned back in April 2020 but the class VItem has not yet been used!
//	The TableView's custom cells together with the BibItems[] array in the Chapter instance
//	were all that was needed. But now that I look at the computations involved in generating
//	the items for use in the popovers of the class PubItemsViewController I almost wish I had
//	used the class VItem!
//
//	There will be one instance at a time of the class VItem and it will be for the current
//	VerseItem that the user has selected for keyboarding. When the user switches to keyboarding
//	a different VerseItem the current instance of VItem will be deleted and a new instance
//	created for the newly selected VerseItem.
//
//	Prior to deletion of a VItem instance the edited state of the VItem will be saved to the
//	matching VerseItems record of kdb.sqlite. The current state may also be saved at various
//	times prior to the deletion of this VItem
//
//	The VItem instance will maintain contact with its corresponding cell of the TableView in
//	the VersesTableViewController.
//

import UIKit

class VItem: NSObject {

// Properties of a VItem instance (dummy values to avoid having optional variables)
	var itID: Int = 0		// itemID INTEGER PRIMARY KEY
	var chID: Int = 0		// chapterID INTEGER
	var vNum: Int = 0		// verseNumber INTEGER
	var itTyp: String = ""	// itemType TEXT
	var itOrd: Int = 0		// itemOrder INTEGER
	var itTxt: String = ""	// itemText TEXT
	var intSeq: Int = 0		// intSeq INTEGER
	var isBrg: Bool = false	// isBridge INTEGER

	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate

	init(_ itID:Int, _ chID: Int, _ vNum: Int, _ itTyp: String, _ itOrd:Int, _ itTxt: String, _ intSeq: Int, _ isBrg: Bool) {
		self.itID = itID
		self.chID = chID
		self.vNum = vNum
		self.itTyp = itTyp
		self.itOrd = itOrd
		self.itTxt = itTxt
		self.intSeq = intSeq
		self.isBrg = isBrg
	}
}
