//
//  InvitationsViewController.swift
//  Plot
//
//  Created by Hafiz Usama on 2019-10-25.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

class InvitationsViewController: UIViewController {

    var invitations: [Invitation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension InvitationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return invitations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kInvitationCellIdentifier)!
        return cell
    }
}

extension InvitationsViewController: UITableViewDelegate {
    
}
