//
//  VIMenu.swift
//  kitios
//
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.
//
//  Created by Graeme Costin on 23/11/20.
//  Copyright © 2020 Costin Computing Services. All rights reserved.
//
//	VIMenu gathers the data necessary for populating a popover TableView when the user
//	taps the VerseItem label. The action of tapping a VerseItem label makes that VerseItem
//	the current one even if it were not before the user tapped its label.

import UIKit

class VIMenuItem : NSObject {
	var VIMenuLabel : String	// Menu lebel displayed to users
	var VIMenuAction : String	// Menu action to be done if chosen by user
	var VIMenuHLight : String	// Highlight colour B= blue, R = Red (for delete/dangerous)
	
	init(_ label:String, _ action: String, _ highLight: String) {
		self.VIMenuLabel = label
		self.VIMenuAction = action
		self.VIMenuHLight = highLight
	}
}

class VIMenu : NSObject {

	// Properties of a VIMenu instance (dummy values to avoid having optional variables)
	var VIType = "Verse"				// the type of the VerseItem this menu is for
	var numRows: Int = 0				// number of rows needed for the popover menu
	var VIMenuItems: [VIMenuItem] = []	// array of the menu items
	
	let appDelegate = UIApplication.shared.delegate as! AppDelegate

	init(_ curItOfst: Int) {
		let chInst = appDelegate.chapInst
		let bibItem = chInst!.BibItems[curItOfst]
		VIType = bibItem.itTyp
		let chNum = chInst!.chNum
		switch VIType {
		case "Ascription":		// Ascriptions before verse 1 of some Psalms
			let viMI = VIMenuItem("Delete Ascription", "delAsc", "R")
			VIMenuItems.append(viMI)
		case "Title":			// Title for a Book
			let viMI1 = VIMenuItem("Create Heading After", "crHdAft", "B")
			VIMenuItems.append(viMI1)
			let viMI2 = VIMenuItem("Create Intro Title", "crInTit", "B")
			VIMenuItems.append(viMI2)
			let viMI3 = VIMenuItem("Delete Title", "delTit", "R")
			VIMenuItems.append(viMI3)
		case "InTitle":			// Title within Book introductory matter
			let viMI1 = VIMenuItem("Create Intro Paragraph", "crInPar", "B")
			VIMenuItems.append(viMI1)
			let viMI2 = VIMenuItem("Create Intro Heading", "crInHed", "B")
			VIMenuItems.append(viMI2)
			let viMI3 = VIMenuItem("Delete Intro Title", "delInTit", "R")
			VIMenuItems.append(viMI3)
		case "InSubj":			// Subject heading within Book introductory matter
			let viMI1 = VIMenuItem("Create Intro Paragraph", "crInPar", "B")
			VIMenuItems.append(viMI1)
			let viMI2 = VIMenuItem("Delete Intro Subject", "delInSubj", "R")
			VIMenuItems.append(viMI2)
		case "InPara":			// Paragraph within Book introductory matter
			let viMI1 = VIMenuItem("Create Intro Paragraph", "crInPar", "B")
			VIMenuItems.append(viMI1)
			let viMI2 = VIMenuItem("Create Intro Heading", "crInHed", "B")
			VIMenuItems.append(viMI2)
			if (bibItem.vsNum == 1) && (chNum == 1) {
				let viMI3 = VIMenuItem("Create Title", "crTitle", "B")
				VIMenuItems.append(viMI3)
			}
			let viMI4 = VIMenuItem("Delete Intro Paragraph", "delInPar", "R")
			VIMenuItems.append(viMI4)
		case "Heading":			// Heading/Subject Heading
			let viMI1 = VIMenuItem("Create Parallel Ref", "crPalRef", "B")
			VIMenuItems.append(viMI1)
			if (bibItem.vsNum == 1) && (chNum == 1) {
				let viMI2 = VIMenuItem("Create Title", "crTitle", "B")
				VIMenuItems.append(viMI2)
			}
			let viMI3 = VIMenuItem("Delete Heading", "delHead", "R")
			VIMenuItems.append(viMI3)
		case "Para":			// Paragraph before a verse
			let viMI1 = VIMenuItem("Create Heading", "crHdAft", "B")
			VIMenuItems.append(viMI1)
			let viMI2 = VIMenuItem("Delete Paragraph", "delPara", "R")
			VIMenuItems.append(viMI2)
		case "ParaCont":		// Paragraph within a verse
			let viMI1 = VIMenuItem("Delete Paragraph", "delPCon", "R")
			VIMenuItems.append(viMI1)
		case "ParlRef":			// Parallel Reference
			let viMI1 = VIMenuItem("Delete Parallel Ref", "delPalRef", "R")
			VIMenuItems.append(viMI1)
		case "Verse":
			if (chInst!.bkID == 19) && (bibItem.vsNum == 1) && (!chInst!.hasAscription) {
				let viMI1 = VIMenuItem("Create Ascription", "crAsc", "R")
				VIMenuItems.append(viMI1)
			}
			if (bibItem.vsNum == 1) {
				if (chNum == 1) && (!chInst!.hasTitle) {
					let viMI2 = VIMenuItem("Create Title", "crTitle", "B")
					VIMenuItems.append(viMI2)
				}
			}
			let viMI3 = VIMenuItem("Create Heading Before", "crHdBef", "B")
			VIMenuItems.append(viMI3)
			let viMI4 = VIMenuItem("Create Paragraph Before", "crParaBef", "B")
			VIMenuItems.append(viMI4)
			if !bibItem.isBrg {
				let viMI5 = VIMenuItem("Create Paragraph In", "crParaCont", "B")
				VIMenuItems.append(viMI5)
			}
			if bibItem.vsNum != chInst!.numVs {
				let viMI6 = VIMenuItem("Bridge Next Verse", "brid", "R")
				VIMenuItems.append(viMI6)
			}
			if bibItem.isBrg {
				let viMI7 = VIMenuItem("Unbridge Last Verse", "unBrid", "R")
				VIMenuItems.append(viMI7)
			}
		default:
			let viMI1 = VIMenuItem("***MENU ERROR***", "NOOP", "R")
			VIMenuItems.append(viMI1)
		}
		numRows = VIMenuItems.count

	}
}
