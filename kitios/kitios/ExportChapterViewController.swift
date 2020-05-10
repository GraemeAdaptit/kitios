//
//  ExportChapterViewController.swift
//  KIT05
//
//  Created by Graeme Costin on 2/5/20.
//  Copyright © 2020 Costin Computing Services. All rights reserved.
//

import UIKit

class ExportChapterViewController: UIViewController {

	var bInst: Bible?
	var bkInst: Book?
	var chInst: Chapter?
	
	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate

	@IBOutlet weak var ExportUSFM: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		bInst = appDelegate.bibInst	// Get access to the instance of the Bible
		bkInst = appDelegate.bookInst	// Get access to the instance of the current Book
		chInst = appDelegate.chapInst	// Get access to the instance of the current Chapter
		navigationItem.title = bInst!.bibName
		navigationItem.prompt = "Export chapter " + String(chInst!.chNum) + " of " + bkInst!.bkName

		// Generate the USFM text
		let USFMexp = chInst!.calcUSFMExportText()
		// Display it to the user
		ExportUSFM.text = USFMexp
		// Save it into the current Chapter record of kdb.sqlite
		if chInst!.saveUSFMText (chInst!.chID, USFMexp) {
			print("ExportChapterViewController:viewDidLoad saved USFM text to kdb.sqlite")
		} else {
			print("ExportChapterViewController:viewDidLoad save to kdb.sqlite FAILED")
		}
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
