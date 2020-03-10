//
//  WorkoutDetailViewController.swift
//  Plot
//
//  Created by Cory McHattie on 3/9/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

class WorkoutDetailViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private let kActivityDetailCell = "ActivityDetailCell"
    private let kWorkoutDetailCell = "WorkoutDetailCell"
    
    var sections = [String]()
    
    var users = [User]()
    var filteredUsers = [User]()
    var conversations = [Conversation]()
    
    var workout: Workout?
    var intColor: Int = 0
            
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = true
        
        title = "Workout"
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        collectionView.register(ActivityDetailCell.self, forCellWithReuseIdentifier: kActivityDetailCell)
        collectionView.register(WorkoutDetailCell.self, forCellWithReuseIdentifier: kWorkoutDetailCell)

                                        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.currentTheme().statusBarStyle
    }

    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kActivityDetailCell, for: indexPath) as! ActivityDetailCell
            cell.delegate = self
            if let workout = workout {
                cell.intColor = intColor
                cell.workout = workout
                return cell
            } else {
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kWorkoutDetailCell, for: indexPath) as! WorkoutDetailCell
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        if indexPath.item == 0 {
            let dummyCell = ActivityDetailCell(frame: .init(x: 0, y: 0, width: view.frame.width, height: 328))
            dummyCell.workout = workout
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: view.frame.width, height: 328))
            height = estimatedSize.height
            print("height: \(height)")
            return CGSize(width: view.frame.width, height: height)
        } else {
            height = 13
            print("height: \(height)")
            return CGSize(width: view.frame.width, height: height)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension WorkoutDetailViewController: ActivityDetailCellDelegate {
    func plusButtonTapped() {
        print("plusButtonTapped")
    }
    
    func shareButtonTapped() {
        print("shareButtonTapped")
    }
    
    func heartButtonTapped() {
        print("heartButtonTapped")
    }

}

extension WorkoutDetailViewController: WorkoutDetailCellDelegate {
    func viewTapped() {
        if let workout = workout, let indentifier = workout.identifier {
            print("view tapped")
            let destination = WebViewController()
            destination.urlString = "https://workoutlabs.com/fit/wkt/\(indentifier)/?app=plot"
            destination.controllerTitle = "Workout"
            let navigationViewController = UINavigationController(rootViewController: destination)
            navigationViewController.modalPresentationStyle = .fullScreen
            self.present(navigationViewController, animated: true, completion: nil)
        }
    }
}

