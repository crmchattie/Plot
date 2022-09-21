//
//  SelectParticipantsTableView.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 3/12/18.
//  Copyright © 2018 Roman Mizin. All rights reserved.
//

import UIKit
import SDWebImage

extension SelectParticipantsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sortedFirstLetters[section]
    }
    
//    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
//        if userInvitationStatus.count == 0 {
//            return sortedFirstLetters
//        }
//        return nil
//    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        view.tintColor = .systemGroupedBackground
//        if let headerTitle = view as? UITableViewHeaderFooterView {
//            headerTitle.textLabel?.textColor = .secondaryLabel
//            //      headerTitle.textLabel?.font = UIFont.systemFont(ofSize: 10)
//            headerTitle.textLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
//            headerTitle.textLabel?.adjustsFontForContentSizeCategory = true
//        }
        view.tintColor = .systemGroupedBackground
        if let headerTitle = view as? UITableViewHeaderFooterView {
          headerTitle.textLabel?.textColor = .label
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let user = sections[indexPath.section][indexPath.row]
        cell.isSelected = user.isSelected
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return selectCell(for: indexPath)!
    }
    
    fileprivate func selectCell(for indexPath: IndexPath) -> UITableViewCell? {
        let cell = tableView.dequeueReusableCell(withIdentifier: falconUsersCellID, for: indexPath) as? ParticipantTableViewCell ?? ParticipantTableViewCell()
        cell.selectParticipantsViewController = self
        
        cell.backgroundColor = .secondarySystemGroupedBackground
        let backgroundView = UIView()
        backgroundView.backgroundColor = cell.backgroundColor
        cell.selectedBackgroundView = backgroundView
        
        let user = sections[indexPath.section][indexPath.row]

        cell.isSelected = user.isSelected
        
        if let name = user.name {
            cell.title.text = name
        }
        
        if let statusString = user.onlineStatus as? String {
            if statusString == statusOnline {
                cell.subtitle.textColor = FalconPalette.defaultBlue
                cell.subtitle.text = statusString
            } else {
                cell.subtitle.textColor = .secondaryLabel
                let date = Date(timeIntervalSince1970: TimeInterval(statusString)!)
                let subtitle = "Last seen " + timeAgoSinceDate(date)
                cell.subtitle.text = subtitle
            }
        } else if let statusTimeinterval = user.onlineStatus as? TimeInterval {
            cell.subtitle.textColor = .secondaryLabel
            let date = Date(timeIntervalSince1970: statusTimeinterval/1000)
            let subtitle = "Last seen " + timeAgoSinceDate(date)
            cell.subtitle.text = subtitle
        }
        
        cell.allowSelection = true
        
        if self.ownerID == user.id {
            cell.allowSelection = false
        }
        
        guard let url = user.thumbnailPhotoURL else { return cell }
        cell.icon.sd_setImage(with: URL(string: url), placeholderImage:  UIImage(named: "UserpicIcon"), options: [.progressiveLoad, .continueInBackground], completed: { (image, error, cacheType, url) in
            guard image != nil else { return }
            guard cacheType != SDImageCacheType.memory, cacheType != SDImageCacheType.disk else {
                cell.icon.alpha = 1
                return
            }
            cell.icon.alpha = 0
            UIView.animate(withDuration: 0.25, animations: { cell.icon.alpha = 1 })
        })
        
        return cell
    }
}
