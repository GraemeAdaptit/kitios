//
//  ErrorViewController.swift
//  kitios
//
//  Created by Graeme Costin on 1/8/21.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.
//

import UIKit

class ErrorViewController: UIViewController {

	@IBOutlet weak var errorNum: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		errorNum.text = "Error No. = ReportError param"
		
    }

}
