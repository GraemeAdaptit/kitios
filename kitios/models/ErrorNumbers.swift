//
//  ErrorNumbers.swift
//  kitios
//
//  Created by Graeme Costin on 27JUL21.

// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

//	Error numbers from 100 to 199 are catastrophic and need the app to close
//	Error numbers from 200 to 299 may result in reduced capabilities but app should continue
//	Error numbers from 300 to 399 are minor and need not be reported to the user
//	Error numbers from 400 to 499 require waiting for remote operations; alert user and continue

	let NO_ERROR = 0			// no error

	let DB_crErr = 100			// Cannot create kdb.sqlite
	let DB_opErr = 101			// Cannot open kdb.sqlite
	let DB_clErr = 102			// Cannot close kdb.sqlite (close result was SQLITE_BUSY)
	let DBT_BibErr = 103		// Error creating Bibles table
	let DBT_BooErr = 104		// Error creating Books table
	let DBT_ChaErr = 105		// Error creating Chapters table
	let DBT_VseErr = 106		// Error creating VerseItems table
	let DBT_BrgErr = 107		// Error creating BridgeItems table
	let DBC_BibErr = 108		// Error creating Bible record
	let DBR_BibErr = 109		// Error reading Bible record
	let DBU_BibNErr = 110		// Error updating name of Bible
	let DBU_BibRErr = 111		// Error updating records created flag in Bible record
	let DBU_BibCErr = 112		// Error updating current Book in Bible record
	let DBC_BooErr = 113		// Error creating Book record into database
	let DBR_BooErr = 114		// Error reading Book record from database
	let DBU_BooErr = 115		// Error updating the record for this Book
	let DBC_ChaErr = 116		// Error creating Chapter record into database
	let DBR_ChaErr = 117		// Error reading Chapter record from database
	let DBC_VItErr = 118		// Error creating VerseItem record into database
	let DBR_VItErr = 119		// Error reading VerseItem record from database
	let DBU_ChaNItErr = 120		// Error updating numItems in Chapter record
	let DBU_ChaRcrErr = 121		// Error updating ItRcr in Chapter record
	let DBU_ChaCItGoErr = 122	// Error updating currIt for Go current item
	let DBU_ChaCItSeErr = 123	// Error updating currIt for Set current item
	let DBU_ChaCAscrErr = 124	// Error updating Chapter record for create Ascription
	let DBU_VItTxtErr = 126		// Error updating text of VerseItem record
	let DBC_VItCAscrErr = 127	// Error creating Item record for Ascription
	let DBD_VItDAscrErr = 128	// Error deleting Item record for Ascription
	let DBU_ChaPubErr = 129		// Error updating Chapter record for Pub item change
	let DBC_VItTitErr = 130		// Error creating VerseItem for Title
	let DBD_VItTitErr = 131		// Error deleting VerseItem for Title
	let DBC_VItPBfErr = 132		// Error creating VerseItem for Paragraph before
	let DBD_VItPBfErr = 133		// Error deleting VerseItem for Paragraph before
	let DBC_VItPInErr = 134		// Error creating VerseItem for ParaCont
	let DBD_VItPInErr = 135		// Error deleting VerseItem for ParaCont
	let DBC_VItVcoErr = 136		// Error creating VerseItem for VerseCont
	let DBD_VItVcoErr = 137		// Error deleting VerseItem for VerseCont
	let DBC_VItDBrErr = 138		// Error creating VerseItem during unbridge action
	let DBC_VItSHdErr = 139		// Error creating VerseItem for SubjHead
	let DBD_VItSHdErr = 140		// Error deleting VerseItem for SubjHead
	let DBC_VItPRfErr = 141		// Error creating VerseItem for ParlRef
	let DBD_VItPRfErr = 142		// Error deleting VerseItem for ParlRef
	let DBU_VItBItErr = 143		// Error updating VerseItem for bridging/unbridging
	let DBD_VItBItErr = 144		// Error deleting VerseItem for unbridging

	let DBC_VItITiErr = 145		// Error creating VerseItem for IntroTitle
	let DBD_VItITiErr = 146		// Error deleting VerseItem for IntroTitle
	let DBC_VItIHdErr = 147		// Error creating VerseItem for IntroSubj
	let DBD_VItIHdErr = 148		// Error deleting VerseItem for IntroSubj
	let DBC_VItIPaErr = 149		// Error creating VerseItem for IntroPara
	let DBD_VItIPaErr = 150		// Error deleting VerseItem for IntroPara

	let DBC_BItErr = 151		// Error creating BridgeItem record
	let DBR_BItErr = 152		// Error reading BridgeItem record from database
	let DBD_BItErr = 153		// Error deleting BridgeItem record

	let DBU_ChaUSFMErr = 154	// Error updating USFM text in Chapter record

	let DBC_PopErr = 155		// Error creating a record during popover menu actions
	let DBR_PopErr = 156		// Error reading a record during popover menu actions
	let DBU_PopErr = 157		// Error updating a record during popover menu actions
	let DBD_PopErr = 158		// Error deleting a record during popover menu actions

	let DB_UnexpErr = 199		// Unexpected SQLite database error
