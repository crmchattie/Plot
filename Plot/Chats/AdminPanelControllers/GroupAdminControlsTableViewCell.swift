//
//  GroupAdminControlsTableViewCell.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/22/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit

class GroupAdminControlsTableViewCell: UITableViewCell {
  
  var title: UILabel = {
    var title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.font = UIFont.preferredFont(forTextStyle: .body)
    title.adjustsFontForContentSizeCategory = true
    title.textColor = FalconPalette.defaultBlue
    title.text = "Title here"
    title.textAlignment = .center
    
    return title
  }()

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    
    backgroundColor = .systemGroupedBackground
    contentView.layer.cornerRadius = 10
    contentView.backgroundColor = .secondarySystemGroupedBackground
    contentView.translatesAutoresizingMaskIntoConstraints = false

    contentView.topAnchor.constraint(equalTo: topAnchor, constant: 5).isActive = true
    contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5).isActive = true
    
    if #available(iOS 11.0, *) {
      contentView.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
      contentView.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
    } else {
      contentView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
      contentView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
    }
   
    contentView.addSubview(title)
    title.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
    title.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    title.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
    title.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
  }
}
