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
    let healhKitManager = HealthKitManager()
    
    var healthMetricSections: [String] = []
    var healthMetrics: [String: [HealthMetric]] = [:] {
        didSet {
            if oldValue != healthMetrics {
                collectionView.reloadData()
            }
        }
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
        
    let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        return spinner
    }()
    
    let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "close"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleDismiss(button: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    var closeButtonConstraint: CGFloat = 0
    
    override var prefersStatusBarHidden: Bool { return true }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        addObservers()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear - HealthVC \(mode)")
        if mode == .fullscreen {
            closeButton.constrainHeight(50)
            closeButton.constrainWidth(50)
            closeButtonConstraint = 20
            collectionView.isScrollEnabled = true
            collectionView.isUserInteractionEnabled = true
        } else {
            closeButton.constrainHeight(0)
            closeButton.constrainWidth(0)
            closeButtonConstraint = 0
            collectionView.isScrollEnabled = false
            collectionView.isUserInteractionEnabled = false
        }
        configureView()
    }
    
//    override func viewWillDisappear(_ animated: Bool) {
//        print("viewWillDisappear - HealthVC \(mode)")
//        if mode == .fullscreen {
//            closeButton.constrainHeight(0)
//            closeButton.constrainWidth(0)
//            closeButtonConstraint = 0
//            collectionView.isScrollEnabled = false
//            collectionView.isUserInteractionEnabled = false
//        } else {
//            closeButton.constrainHeight(50)
//            closeButton.constrainWidth(50)
//            closeButtonConstraint = 20
//            collectionView.isScrollEnabled = true
//            collectionView.isUserInteractionEnabled = true
//        }
//        configureView()
//    }
    
    func fetchData() {
        HealthKitService.authorizeHealthKit { [weak self] authorized in
            guard authorized else {
                return
            }
            
            DispatchQueue.main.async {
                self?.spinner.startAnimating()
            }
            
            self?.healhKitManager.loadHealthKitActivities { [weak self] metrics, shouldFetchActivities in
                DispatchQueue.main.async {
                    self?.healthMetrics = metrics
                    self?.healthMetricSections = Array(metrics.keys)
                    
                    self?.healthMetricSections.sort(by: { (v1, v2) -> Bool in
                        if let cat1 = HealthMetricCategory(rawValue: v1), let cat2 = HealthMetricCategory(rawValue: v2) {
                            return cat1.rank < cat2.rank
                        }
                        return false
                    })
                    
                    self?.spinner.stopAnimating()
                    self?.collectionView.reloadData()
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(changeTheme), name: .themeUpdated, object: nil)
    }
    
    @objc fileprivate func changeTheme() {
        let theme = ThemeManager.currentTheme()
        view.backgroundColor = theme.cellBackgroundColor
        collectionView.indicatorStyle = theme.scrollBarStyle
        collectionView.backgroundColor = theme.cellBackgroundColor
        collectionView.reloadData()
    }
    
    private func configureView() {
        navigationController?.isNavigationBarHidden = true
        navigationController?.navigationBar.isHidden = true
        
        view.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        
        view.addSubview(closeButton)
        view.addSubview(collectionView)
        view.addSubview(spinner)
        
        closeButton.anchor(top: view.topAnchor, leading: nil, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: closeButtonConstraint, left: 0, bottom: 0, right: closeButtonConstraint))

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 0),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        collectionView.register(HealthMetricCell.self, forCellWithReuseIdentifier: healthMetricCellID)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: healthMetricSectionHeaderID)
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = view.backgroundColor
    }
    
    var mode: Mode

    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HealthViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if mode == .fullscreen {
            return healthMetricSections.count
        } else if !healthMetricSections.isEmpty {
            return 1
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if mode == .fullscreen {
            let key = healthMetricSections[section]
            return healthMetrics[key]?.count ?? 0
        }
        let key = healthMetricSections[section]
        return min(5, healthMetrics[key]?.count ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        let key = healthMetricSections[indexPath.section]
        if let metrics = healthMetrics[key] {
            let metric = metrics[indexPath.row]
            cell.configure(metric)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let key = healthMetricSections[indexPath.section]
        if let metrics = healthMetrics[key] {
            let metric = metrics[indexPath.row]
            let healthDetailViewModel = HealthDetailViewModel(healthMetric: metric, healthDetailService: HealthDetailService())
            let healthDetailViewController = HealthDetailViewController(viewModel: healthDetailViewModel)
            navigationController?.pushViewController(healthDetailViewController, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if mode == .fullscreen {
            return CGSize(width: self.collectionView.frame.size.width, height: 35)
        } else {
            return CGSize(width: 0, height: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let key = healthMetricSections[indexPath.section]
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: healthMetricSectionHeaderID, for: indexPath) as! SectionHeader
            sectionHeader.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            sectionHeader.titleLabel.text = key.capitalized
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
}
