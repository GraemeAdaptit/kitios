//
//  VIMenu.swift
//
//	VIMenu gathers the data necessary for populating a popover TableView when the user
//	taps the VerseItem label. The action of tapping a VerseItem label makes that VerseItem
//	the current one even if it were not before the user tapped its label.
//
//	The UI design of KIT aims to show only valid possibilities to users. This requires a
//	fair bit of logic in the init() of VIMenu. The rules for this logic are listed in the
//	spreadsheet KIT Design Document Popovers.ods.
//
//	The init() of VIMenu also calculates the width in points needed for the popover menu.
//
//	As of 27SEP21, a VIMenu is created every time there is a new current VerseItem. This means
//	that many VIMenu instances are created but never used. To reduce the amount of memory
//	allocation and deallocation, this will later be changed so that a VIMenu is created
//	only when it is needed, i.e. only when the user taps the popover button in a VerseItem.
//
//  Created by Graeme Costin on 23NOV20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

extension String {
	   func size(OfFont font: UIFont) -> CGSize {
		return (self as NSString).size(withAttributes: [NSAttributedString.Key.font: font])
	   }
   }

class VIMenuItem : NSObject {
	var VIMenuLabel : String	// Menu label displayed to users
	var VIMenuAction : String	// Menu action to be done if chosen by user
	var VIMenuIcon : String		// C = Create, D = Delete, B = Bridge, U = Unbridge
	
	init(_ label:String, _ action: String, _ highLight: String) {
		self.VIMenuLabel = label
		self.VIMenuAction = action
		self.VIMenuIcon = highLight
	}
}

class VIMenu : NSObject {

	// Properties of a VIMenu instance (dummy values to avoid having optional variables)
	var VIType = "Verse"				// the type of the VerseItem this menu is for
	var numRows: Int = 0				// number of rows needed for the popover menu
	var VIMenuItems: [VIMenuItem] = []	// array of the menu items
	var menuLabelLength: CGFloat = 50	// Minimum length of the menu label in points
										// (for calculating popover menu width)
	let font = UIFont.systemFont(ofSize: 14)

	let appDelegate = UIApplication.shared.delegate as! AppDelegate

	init(_ curItOfst: Int) {
		let chInst = appDelegate.chapInst
		let bibItem = chInst!.BibItems[curItOfst]
		VIType = bibItem.itTyp
		let chNum = chInst!.chNum
		switch VIType {
		case "Ascription":		// Ascriptions before verse 1 of some Psalms
			let viMI = VIMenuItem("Ascription", "delAsc", "D")
			VIMenuItems.append(viMI)
		case "Title":			// Title for a Book
			if (bibItem.vsNum == 1) && (chNum == 1) && (!chInst!.hasInTitle) {
				let viMI1 = VIMenuItem("Intro Title", "crInTit", "C")
			    VIMenuItems.append(viMI1)
			}
			let viMI2 = VIMenuItem("Heading After", "crHdAft", "C")
			VIMenuItems.append(viMI2)
			let viMI3 = VIMenuItem("Title", "delTitle", "D")
			VIMenuItems.append(viMI3)
		case "InTitle":			// Title within Book introductory matter
			let viMI1 = VIMenuItem("Intro Heading", "crInHed", "C")
			VIMenuItems.append(viMI1)
			let viMI2 = VIMenuItem("Intro Paragraph", "crInPar", "C")
			VIMenuItems.append(viMI2)
			let viMI3 = VIMenuItem("Intro Title", "delInTit", "D")
			VIMenuItems.append(viMI3)
		case "InSubj":			// Subject heading within Book introductory matter
			if (bibItem.vsNum == 1) && (chNum == 1) && (!chInst!.hasInTitle) {
				let viMI1 = VIMenuItem("Intro Title", "crInTit", "C")
				VIMenuItems.append(viMI1)
			}
			let viMI2 = VIMenuItem("Intro Paragraph", "crInPar", "C")
			VIMenuItems.append(viMI2)
			let viMI3 = VIMenuItem("Intro Subject", "delInHed", "D")
			VIMenuItems.append(viMI3)
		case "InPara":			// Paragraph within Book introductory matter
			let viMI1 = VIMenuItem("Intro Paragraph", "crInPar", "C")
			VIMenuItems.append(viMI1)
			let viMI2 = VIMenuItem("Intro Heading", "crInHed", "C")
			VIMenuItems.append(viMI2)
			if (bibItem.vsNum == 1) && (chNum == 1) && (!chInst!.hasTitle) {
				let viMI3 = VIMenuItem("Title", "crTitle", "C")
				VIMenuItems.append(viMI3)
			}
			let viMI4 = VIMenuItem("Intro Paragraph", "delInPar", "D")
			VIMenuItems.append(viMI4)
		case "Heading":			// Heading/Subject Heading
			if (bibItem.vsNum == 1) && (chNum == 1) && (!chInst!.hasTitle) {
				let viMI1 = VIMenuItem("Title", "crTitle", "C")
				VIMenuItems.append(viMI1)
			}
			let viMI2 = VIMenuItem("Parallel Ref", "crPalRef", "C")
			VIMenuItems.append(viMI2)
			let viMI3 = VIMenuItem("Heading", "delHead", "D")
			VIMenuItems.append(viMI3)
		case "Para":			// Paragraph before a verse
			let viMI1 = VIMenuItem("Heading", "crHdBef", "C")
			VIMenuItems.append(viMI1)
			let viMI2 = VIMenuItem("Paragraph", "delPara", "D")
			VIMenuItems.append(viMI2)
		case "ParaCont":		// Paragraph within a verse
			let viMI1 = VIMenuItem("Paragraph", "delPCon", "D")
			VIMenuItems.append(viMI1)
		case "VerseCont":		// Verse continuation after paragraph break
			let viMI1 = VIMenuItem("Paragraph", "delVCon", "D")
			VIMenuItems.append(viMI1)
		case "ParlRef":			// Parallel Reference
			let viMI1 = VIMenuItem("Parallel Ref", "delPalRef", "D")
			VIMenuItems.append(viMI1)
		case "Verse":
			if (chInst!.bkID == 19) && (bibItem.vsNum == 1) && (!chInst!.hasAscription) {
				let viMI1 = VIMenuItem("Ascription", "crAsc", "C")
				VIMenuItems.append(viMI1)
			}
			if (bibItem.vsNum == 1) {
				if ( (chNum == 1) && (!chInst!.hasInTitle) ) {
					let viMI2 = VIMenuItem("Intro Title", "crInTit", "C")
					VIMenuItems.append(viMI2)
				}
			}
			if (bibItem.vsNum == 1) {
				if (chNum == 1) && (!chInst!.hasTitle) {
					let viMI3 = VIMenuItem("Title", "crTitle", "C")
					VIMenuItems.append(viMI3)
				}
			}
			let viMI4 = VIMenuItem("Heading Before", "crHdBef", "C")
			VIMenuItems.append(viMI4)
			let viMI5 = VIMenuItem("Paragraph Before", "crParaBef", "C")
			VIMenuItems.append(viMI5)
			if !bibItem.isBrg {
				let viMI6 = VIMenuItem("Paragraph In", "crParaCont", "C")
				VIMenuItems.append(viMI6)
			}
			let viMI7 = VIMenuItem("Parallel Ref", "crPalRef", "C")
				VIMenuItems.append(viMI7)
			var brgPossible:Bool
			if bibItem.isBrg {
				brgPossible = (bibItem.lvBrg < chInst!.numVs)
			} else {
				brgPossible = (bibItem.vsNum < chInst!.numVs)
			}
			if brgPossible {
			// GDLC 24AUG21 Don't let a verse be bridged with a following bridge
			let nextVI = chInst!.BibItems[curItOfst + 1]
			if (nextVI.itTyp == "Verse" && !nextVI.isBrg) {
				let viMI8 = VIMenuItem("Bridge Next", "brid", "B")
				VIMenuItems.append(viMI8)
				}
			}
			if bibItem.isBrg {
				let viMI9 = VIMenuItem("Unbridge", "unBrid", "U")
				VIMenuItems.append(viMI9)
			}
		default:
			let viMI1 = VIMenuItem("***MENU ERROR***", "NOOP", "D")
			VIMenuItems.append(viMI1)
		}
		numRows = VIMenuItems.count
		// Calculate max popover menu label width
		for v in VIMenuItems {
			let width = v.VIMenuLabel.size(OfFont: font).width
			if width > menuLabelLength {menuLabelLength = width}
		}
	}
}
