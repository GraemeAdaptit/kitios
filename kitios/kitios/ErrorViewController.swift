//
//  ErrorViewController.swift
//  kitios
//
//  Created by Graeme Costin on 1/8/21.
//  Copyright © 2021 Costin Computing Services. All rights reserved.
//

import UIKit

class ErrorViewController: UIViewController {

	@IBOutlet weak var errorNum: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		errorNum.text = "Error No. = ReportError param"
		
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
