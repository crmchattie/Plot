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

let setupCell = "SetupCell"

class SetupController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ObjectDetailShowing {
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let collectionView:UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout.init())
    let layout:UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    
    var customType: CustomType!
    let networkController: NetworkController
    var participants: [String : [User]] = [:]
    var footerTitle = "Continue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set-up interface with the help of OnboardingContainerView file
        view.backgroundColor = .systemGroupedBackground
        collectionView.indicatorStyle = .default
        collectionView.backgroundColor = .systemGroupedBackground
        
        definesPresentationContext = true
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        collectionView.setCollectionViewLayout(layout, animated: true)
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        collectionView.fillSuperview()
        
        collectionView.register(SetupCell.self, forCellWithReuseIdentifier: setupCell)
        collectionView.register(SetupFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: setupFooter)
        
    }
    
    @objc func nextButtonDidTap() {
        
    }
    
    @objc func new() {
        if customType == .time {
            newCalendar()
        } else if customType == .health {
            networkController.healthService.regrabHealth {}
        } else {
            openMXConnect(current_member_guid: nil, delegate: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: setupCell, for: indexPath) as! SetupCell
        cell.customType = customType
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width - 30, height: 240)
            
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        new()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 70)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let setupFooter = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: setupFooter, for: indexPath) as! SetupFooter
            setupFooter.footerTitle = footerTitle
            setupFooter.button.addTarget(self, action: #selector(new), for: .touchUpInside)
            setupFooter.nextView.addTarget(self, action: #selector(nextButtonDidTap), for: .touchUpInside)
            return setupFooter
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
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
