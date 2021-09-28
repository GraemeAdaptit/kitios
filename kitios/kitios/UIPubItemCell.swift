//
//  UIPubItemCell.swift
//
//	A custom class for UITableView cells presenting popover menu items.
//
//  Created by Graeme Costin on 2MAR21.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class UIPubItemCell: UITableViewCell {

	@IBOutlet weak var poImage: UIImageView!
	@IBOutlet weak var poLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
