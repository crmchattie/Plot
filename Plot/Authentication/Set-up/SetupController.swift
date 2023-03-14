//
//  SetupController.swift
//  Plot
//
//  Created by Cory McHattie on 3/14/23.
//  Copyright © 2023 Immature Creations. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class SetupController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ObjectDetailShowing {
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        return collectionView
    }()
    
    var customType: CustomType!
    let networkController: NetworkController
    var participants: [String : [User]] = [:]
    
    let nextView: UIButton = {
        let nextView = UIButton()
        nextView.translatesAutoresizingMaskIntoConstraints = false
        nextView.titleLabel?.backgroundColor = .clear
        nextView.titleLabel?.font = UIFont.title3.with(weight: .semibold)
        nextView.setTitle("Next", for: .normal)
        nextView.setTitleColor(.systemBlue, for: .normal)
        nextView.backgroundColor = .secondarySystemGroupedBackground
        nextView.layer.cornerRadius = 10
        return nextView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set-up interface with the help of OnboardingContainerView file
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(SetupCell.self, forCellWithReuseIdentifier: setupCell)
        
    }
    
    @objc func nextButtonDidTap() {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.customType = customType
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 300
        let dummyCell = SetupCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
        dummyCell.backgroundColor = .secondarySystemGroupedBackground
        dummyCell.customType = customType
        dummyCell.layoutIfNeeded()
        let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
        height = estimatedSize.height
        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)
            
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if customType == .time {
            newCalendar()
        } else if customType == .health {
            networkController.healthService.regrabHealth {}
        } else {
            openMXConnect(current_member_guid: nil, delegate: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 70)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Footer", for: indexPath)
        footerView.addSubview(nextView)
        nextView.fillSuperview(padding: .init(top: 10, left: 15, bottom: 10, right: 15))
        nextView.addTarget(self, action: #selector(nextButtonDidTap), for: .touchUpInside)
        return footerView
    }
}

extension SetupController: GIDSignInDelegate {
    func newCalendar() {
        let destination = SignInAppleGoogleViewController(networkController: networkController)
        destination.title = "Providers"
        let cancelBarButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: destination, action: nil)
        destination.navigationItem.leftBarButtonItem = cancelBarButton
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: destination, action: nil)
        destination.navigationItem.rightBarButtonItem = doneBarButton
        let navigationViewController = UINavigationController(rootViewController: destination)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let grantedScopes = user?.grantedScopes as? [String]
            if let grantedScopes = grantedScopes {
                if grantedScopes.contains(googleEmailScope) && grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                    self.collectionView.reloadData()
                } else if grantedScopes.contains(googleEmailScope) {
                    self.networkController.activityService.updatePrimaryCalendar(value: CalendarSourceOptions.google.name)
                    self.collectionView.reloadData()
                } else if grantedScopes.contains(googleTaskScope) {
                    self.networkController.activityService.updatePrimaryList(value: ListSourceOptions.google.name)
                    self.collectionView.reloadData()
                }
            }
        } else {
          print("\(error.localizedDescription)")
        }
    }
}

extension SetupController: EndedWebViewDelegate {
    func updateMXMembers() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}
