//
//  SelectActivityMembersViewController.swift
//  Pigeon-project
//
//  Created by Cory McHattie on 4/29/19.
//  Copyright © 2019 Immature Creations. All rights reserved.
//

import UIKit

protocol UpdateInvitees: AnyObject {
    func updateInvitees(selectedFalconUsers : [User])
}

class SelectActivityMembersViewController: SelectParticipantsViewController {
    
    weak var delegate : UpdateInvitees?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRightBarButton(with: "Done")
        setupNavigationItemTitle(title: "Participants")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    override func rightBarButtonTapped() {
        super.rightBarButtonTapped()
        delegate?.updateInvitees(selectedFalconUsers: selectedFalconUsers)
        self.navigationController?.popViewController(animated: true)
    }
}
