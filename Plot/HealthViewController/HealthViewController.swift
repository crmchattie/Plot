//
//  HealthViewController.swift
//  Plot
//
//  Created by Cory McHattie on 8/21/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit

fileprivate let healthMetricCellID = "HealthMetricCellID"
fileprivate let healthMetricSectionHeaderID = "HealthMetricSectionHeaderID"

protocol HealthViewControllerActivitiesDelegate: class {
    func update(_ healthViewController: HealthViewController, _ shouldFetchActivities: Bool)
}

class HealthViewController: UIViewController {
    var networkController: NetworkController
    
    init(networkController: NetworkController) {
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let healhKitManager = HealthKitManager()
    
    var healthMetricSections: [String] {
        return networkController.healthService.healthMetricSections
    }
    var healthMetrics: [String: [HealthMetric]] {
        return networkController.healthService.healthMetrics
    }
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset.bottom = 0
        return collectionView
    }()
    
    @objc fileprivate func handleDismiss(button: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    var closeButtonConstraint: CGFloat = 0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = "Health"
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        configureView()
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.generalBackgroundColor
        collectionView.indicatorStyle = theme.scrollBarStyle
        collectionView.backgroundColor = theme.generalBackgroundColor
        collectionView.reloadData()
    }
    
    private func configureView() {
        let newItemBarButton =  UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newItem))
        navigationItem.rightBarButtonItem = newItemBarButton
        
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
        
        collectionView.register(HealthMetricCell.self, forCellWithReuseIdentifier: healthMetricCellID)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: healthMetricSectionHeaderID)
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = view.backgroundColor
        
    }
    
    @objc fileprivate func newItem() {
        self.tabBarController?.selectedIndex = 0
        self.navigationController?.popViewController(animated: true)
    }
    
    func openMetric(metric: HealthMetric) {
        let healthDetailService = HealthDetailService()
        healthDetailService.workouts = networkController.healthService.workouts
        healthDetailService.mindfulnesses = networkController.healthService.mindfulnesses
        healthDetailService.nutrition = networkController.healthService.nutrition
        let healthDetailViewModel = HealthDetailViewModel(healthMetric: metric, healthDetailService: healthDetailService)
        let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel)
        navigationController?.pushViewController(healthDetailViewController, animated: true)
    }
}

extension HealthViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return healthMetricSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let key = healthMetricSections[section]
        return healthMetrics[key]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
        cell.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        let key = healthMetricSections[indexPath.section]
        if let metrics = healthMetrics[key] {
            let metric = metrics[indexPath.row]
            cell.configure(metric)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let key = healthMetricSections[indexPath.section]
        print("healthMetricSections \(key)")
        if let metrics = healthMetrics[key] {
            let metric = metrics[indexPath.row]
            print("metric \(metric)")
            openMetric(metric: metric)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 75)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 35)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let key = healthMetricSections[indexPath.section]
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: healthMetricSectionHeaderID, for: indexPath) as! SectionHeader
            sectionHeader.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            sectionHeader.titleLabel.text = key.capitalized
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
}
