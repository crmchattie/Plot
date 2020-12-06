//
//  SummaryViewController.swift
//  Plot
//
//  Created by Cory McHattie on 11/26/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Charts
import HealthKit

fileprivate let summaryPieChartCell = "SummaryPieChartCell"
fileprivate let summaryHKChartCell = "SummaryHKChartCell"
fileprivate let healthMetricSectionHeaderID = "HealthMetricSectionHeaderID"

protocol HomeBaseSummary: class {
//    func sendLists(lists: [ListContainer])
}

protocol SummaryViewControllerActivitiesDelegate: class {
    func update(_ summaryViewController: SummaryViewController, _ shouldFetchActivities: Bool)
}

class SummaryViewController: UIViewController {
    var hasViewAppeared = false
    
    weak var delegate: HomeBaseSummary?
    
    private var viewModel: SummaryViewModelInterface
    
    lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["D", "W", "M", "Y"])
        segmentedControl.addTarget(self, action: #selector(changeSegment(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    lazy var customSegmented = CustomSegmentedControl(buttonImages: nil, buttonTitles: ["D","W","M", "Y"], selectedIndex: 3)
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
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
    
    init(viewModel: SummaryViewModelInterface) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        //self.viewModel.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("STORAGE DID DEINIT")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(customSegmented)
        view.addSubview(collectionView)
        customSegmented.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
                
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
            flowLayout.headerReferenceSize = CGSize(width: self.collectionView.frame.size.width, height: 35.0)
        }
        
        addObservers()
        configureView()
        
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
        navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.layoutIfNeeded()
        
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        edgesForExtendedLayout = UIRectEdge.top
        view.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        customSegmented.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        customSegmented.constrainHeight(30)
        customSegmented.delegate = self
                
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = view.backgroundColor
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(SummaryHKChartCell.self, forCellWithReuseIdentifier: summaryHKChartCell)
        collectionView.register(SummaryPieChartCell.self, forCellWithReuseIdentifier: summaryPieChartCell)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: healthMetricSectionHeaderID)
        collectionView.isUserInteractionEnabled = true
        collectionView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        
        view.addSubview(customSegmented)
        view.addSubview(collectionView)
        view.addSubview(activityIndicatorView)
                        
        customSegmented.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: nil, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        collectionView.anchor(top: customSegmented.bottomAnchor, leading: view.safeAreaLayoutGuide.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.safeAreaLayoutGuide.trailingAnchor, padding: .init(top: 10, left: 0, bottom: 0, right: 0))
    }
    
    @objc func changeSegment(_ segmentedControl: UISegmentedControl) {
        fetchData()
    }
    
    func fetchData() {
        guard let selectedIndex = customSegmented.selectedIndex, let segmentType = TimeSegmentType(rawValue: selectedIndex) else { return }
        
        viewModel.fetchChartData(for: segmentType) { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.collectionView.reloadData()
        }
    }
    
}

extension SummaryViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sec = viewModel.sections[section]
        if sec == .health {
            return 1
        }
        return viewModel.groups[sec]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = viewModel.sections[indexPath.section]
        let object = viewModel.groups[section]
        if section == .health {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: summaryHKChartCell, for: indexPath) as! SummaryHKChartCell
            cell.backgroundColor = collectionView.backgroundColor
            if let activitySummary = object as? [HKActivitySummary], !activitySummary.isEmpty {
                cell.summary = activitySummary[0]
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: summaryPieChartCell, for: indexPath) as! SummaryPieChartCell
            cell.backgroundColor = collectionView.backgroundColor
            if let pieChartDataList = object as? [PieChartData] {
                let pieChartData = pieChartDataList[indexPath.item]
                cell.pieChartData = pieChartData
                cell.chartView.delegate = self
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 285)
        
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: healthMetricSectionHeaderID, for: indexPath) as! SectionHeader
            let section = viewModel.sections[indexPath.section]
            sectionHeader.titleLabel.text = section.name
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
}

extension SummaryViewController: CustomSegmentedControlDelegate {
    func changeToIndex(index:Int) {
        fetchData()
    }
}

extension SummaryViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
    }
}

//            let energyUnit = HKUnit.kilocalorie()
//            let standUnit    = HKUnit.count()
//            let exerciseUnit = HKUnit.second()
//
//            let summary = summaries[0]
//
//            let energy   = summary.activeEnergyBurned.doubleValue(for: energyUnit)
//            let stand    = summary.appleStandHours.doubleValue(for: standUnit)
//            let exercise = summary.appleExerciseTime.doubleValue(for: exerciseUnit)
//
//            let energyGoal   = summary.activeEnergyBurnedGoal.doubleValue(for: energyUnit)
//            let standGoal    = summary.appleStandHoursGoal.doubleValue(for: standUnit)
//            let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: exerciseUnit)
//
//            let energyProgress   = energyGoal == 0 ? 0 : energy / energyGoal
//            let standProgress    = standGoal == 0 ? 0 : stand / standGoal
//            let exerciseProgress = exerciseGoal == 0 ? 0 : exercise / exerciseGoal
