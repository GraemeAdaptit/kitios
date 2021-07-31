//
//  PubItemsViewController.swift
//
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//
//	This is the TableViewController for the publication items popover menu
//
//  Created by Graeme Costin on 5/11/20.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class PubItemsViewController: UITableViewController {

	weak var chInst: Chapter?
	var VTVCtrl: VersesTableViewController?
	var popMenu: VIMenu?

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		print("PubItemsViewController is being initialised")
	}

	deinit {
		print("PubItemsViewController is being de-initialised")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		// Get access to the AppDelegate
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		chInst = appDelegate.chapInst
		popMenu = chInst!.curPoMenu
		VTVCtrl = appDelegate.VTVCtrl
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Just one section
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// No. of rows
		return popMenu!.numRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UIPubItemCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "popOverCell", for: indexPath) as! UIPubItemCell
		let pMenu = popMenu!.VIMenuItems[indexPath.row]
		let pImage = cell.poImage
		let textLabel = cell.poLabel
		textLabel!.text = pMenu.VIMenuLabel
		textLabel!.numberOfLines = 1
		textLabel!.textAlignment = .left
//		textLabel!.minimumScaleFactor = 9
		switch pMenu.VIMenuIcon {
		case "C":
			cell.textLabel!.textColor = .blue
			pImage?.image = UIImage(named: "CreatePubItem.png")
		case "D":
			cell.textLabel!.textColor = .red
			pImage?.image = UIImage(named: "DeletePubItem.png")
		case "B":
			cell.textLabel!.textColor = .purple
			pImage?.image = UIImage(named: "BridgePubItem.png")
		case "U":
			cell.textLabel!.textColor = .purple
			pImage?.image = UIImage(named: "UnbridgePubItem.png")
		default:
			cell.textLabel!.textColor = .blue
			pImage?.image = UIImage(named: "CreatePubItem.png")
		}
        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let popRow = indexPath.row
		let menuItem = popMenu!.VIMenuItems[popRow]
		// Ensure that the current BibItem is saved prior to changing which one is the current one.
		VTVCtrl!.saveCurrentItemText()
		// Perform the necessary actions, including adjusting the kdb.sqlite database
		// and the BibItems[] array
		chInst!.popMenuAction(menuItem.VIMenuAction)
		// Dismiss the popover menu and rework the TableView of VerseItems
		VTVCtrl!.refreshDisplayAfterPopoverMenuActions()
	}

}
