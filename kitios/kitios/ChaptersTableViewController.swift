//
//  ChaptersTableViewController.swift
//  KIT05
//
//	This is the UITableViewController for the Select Chapter scene. This scene will be entered
//	after the current Book is selected and set up, and so it will have available the array of
//	Chapters for the current Book.
//
//  Created by Graeme Costin on 13/11/19.
//  Copyright © 2019 Costin Computing Services. All rights reserved.
//

import UIKit

class ChaptersTableViewController: UITableViewController {

	let appDelegate = UIApplication.shared.delegate as! AppDelegate
	var bInst: Bible?
	var bkInst: Book?
	
	// Boolean for detecting when Back button has been pressed
	var goingForwards = false
	// Boolean for whether the let the user choose a Chapter
	var letUserChooseChapter = false
	// tableRow of the selected Chapter
	var chRow = 0

	required init?(coder aDecoder: NSCoder) {
		print("ChaptersTableViewController:init")
		super.init(coder: aDecoder)
	}

	deinit {
		print("ChaptersTableViewController:deinit")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Get access to the array Book.BibChaps
		print("ChaptersTableViewController:viewDidLoad")
		bInst = appDelegate.bibInst
		bkInst = bInst?.bookInst!	// Get access to the instance of the current Book
		navigationItem.title = bInst!.bibName
		navigationItem.prompt = "Choose chapter of " + bkInst!.bkName

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		print("ChaptersTableViewController:viewWillAppear")
		goingForwards = false
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		print("ChaptersTableViewController:viewDidAppear")
		// Most launches will have a current Chapter and will go straight to it
		if !letUserChooseChapter && bkInst!.currChap > 0 {
			bkInst!.goCurrentChapter()
			// The user is going forwards to the next scene
			goingForwards = true
			// If the user comes back to the Choose Chapter scene we need to let him choose again
			letUserChooseChapter = true
			performSegue(withIdentifier: "editChapter", sender: self)	// Go to Edit Chapter scene
		}
		// On first launch, do nothing and wait for the user to choose a Chapter.
		// When user wants to choose another chapter, scroll so that the previously chosen chapter
		// is near the middle of the TableView
		tableView.scrollToRow(at: IndexPath(row: chRow, section: 0), at: UITableView.ScrollPosition.middle, animated: true)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		print("ChaptersTableViewController:viewWillDisappear")
		if !goingForwards {
			chRow = 0	// Assume a different book & avoid an out-of-range row
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		print("ChaptersTableViewController:viewDidDisappear")
	}

	
	// MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
 		if section == 0 {
			print("ChaptersTableViewController:tableView:numberOfRowsInSection")
			return bkInst!.BibChaps.count
		} else {
			return 0
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterCell", for: indexPath)
		let chapter = bkInst!.BibChaps[indexPath.row]
		cell.textLabel?.text = "Chapter " + String(chapter.chNum)
		let numVsItText = (chapter.numVs > 0 ? String(chapter.numVs) + " verses (" + String(chapter.numIt) + " items)" : "" )
		cell.detailTextLabel?.text = numVsItText
//		if chDirty {
//			cell.detailTextLabel?.textColor = UIColor.blue
//		}
        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// Set up the selected Chapter as the current Chapter
		chRow = indexPath.row
		bkInst!.setupCurrentChapter(withOffset: chRow)
		// Current Chapter is selected so segue to Edit Chapter scene
		// The user is going forwards to the next scene
		goingForwards = true
		// If the user comes back to the Choose Chapter scene we need to let him choose again
		letUserChooseChapter = true
		performSegue(withIdentifier: "editChapter", sender: self)
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

	@IBAction func unwindToEditChapter(_ segue: UIStoryboardSegue) {
	}

}
