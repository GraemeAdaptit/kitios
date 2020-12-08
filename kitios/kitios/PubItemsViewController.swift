//
//  PubItemsViewController.swift
//	kitios
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

//	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	var chInst: Chapter?
	var VTVCtrl: VersesTableViewController?
	var popMenu: VIMenu?

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		print("KeyItSetupController:init")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		// Get access to the AppDelegate
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		chInst = appDelegate.chapInst
		popMenu = chInst!.curPoMenu
		VTVCtrl = appDelegate.VTVCtrl

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "popOverCell", for: indexPath)
		let pMenu = popMenu!.VIMenuItems[indexPath.row]
		let textLabel = cell.textLabel
		textLabel?.text = pMenu.VIMenuLabel
		textLabel?.numberOfLines = 1
		textLabel?.adjustsFontSizeToFitWidth = true
		textLabel?.minimumScaleFactor = 9
		if pMenu.VIMenuHLight == "B" {
			cell.textLabel?.textColor = .blue
		} else {
			cell.textLabel?.textColor = .red
		}
        return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let popRow = indexPath.row
		let menuItem = popMenu!.VIMenuItems[popRow]
		// Perform the necessary actions, including adjusting the kdb.sqlite database
		// and the BibItems[] array
		chInst!.popMenuAction(menuItem.VIMenuAction)
		// Dismiss the popover menu and rework the TableView of VerseItems
		VTVCtrl!.refreshDisplayAfterPopoverMenuActions()
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
