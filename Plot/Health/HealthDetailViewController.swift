//
//  HealthDetailViewController.swift
//  Plot
//
//  Created by Hafiz Usama on 2020-10-05.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import UIKit
import Charts
import HealthKit
import Firebase

fileprivate let healthDetailSampleCellID = "HealthDetailSampleCellID"
fileprivate let chartViewHeight: CGFloat = 200
fileprivate let chartViewTopMargin: CGFloat = 10

class HealthDetailViewController: UIViewController {
    
    private var viewModel: HealthDetailViewModelInterface
    var dayAxisValueFormatter: DayAxisValueFormatter?
    var backgroundChartViewHeightAnchor: NSLayoutConstraint?
    var backgroundChartViewTopAnchor: NSLayoutConstraint?
        
    lazy var backgroundChartView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    lazy var chartView: BarChartView = {
        let chartView = BarChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        chartView.defaultChartStyle()
        chartView.highlightPerTapEnabled = true
        chartView.highlightPerDragEnabled = true
        return chartView
    }()
    
    lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["D", "W", "M", "Y"])
        segmentedControl.addTarget(self, action: #selector(changeSegment(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.sizeToFit()
        return activityIndicator
    }()
    
    lazy var barButton = UIBarButtonItem()
    
    var networkController: NetworkController
        
    init(viewModel: HealthDetailViewModelInterface, networkController: NetworkController) {
        self.viewModel = viewModel
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
        //self.viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        backgroundChartView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        chartView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        extendedLayoutIncludesOpaqueBars = true
        
        barButton = UIBarButtonItem(title: "Hide Chart", style: .plain, target: self, action: #selector(hideUnhideTapped))
        navigationItem.rightBarButtonItem = barButton
        
        if case HealthMetricType.workout = viewModel.healthMetric.type, let hkWorkout = viewModel.healthMetric.hkSample as? HKWorkout {
            title = hkWorkout.workoutActivityType.name
        }
        else if case HealthMetricType.nutrition(let name) = viewModel.healthMetric.type {
            title = name
        }
        else {
            self.title = viewModel.healthMetric.type.name
        }
        
        addObservers()
        changeTheme()
        
        view.addSubview(activityIndicator)
        
        view.addSubview(segmentedControl)
        
        backgroundChartView.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        view.addSubview(backgroundChartView)
        backgroundChartView.addSubview(chartView)
        chartView.delegate = self
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
                
        configureView()
        configureChart()
        
        fetchHealthKitData()
    }
    
    private func configureView() {
        activityIndicator.center = view.center
        activityIndicator.autoresizingMask = [.flexibleTopMargin,
                                              .flexibleBottomMargin,
                                              .flexibleLeftMargin,
                                              .flexibleRightMargin]
        
        backgroundChartViewHeightAnchor = backgroundChartView.heightAnchor.constraint(equalToConstant: chartViewHeight)
        backgroundChartViewTopAnchor = backgroundChartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: chartViewTopMargin)
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            segmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            
            backgroundChartViewTopAnchor!,
            backgroundChartView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            backgroundChartView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            backgroundChartViewHeightAnchor!,
            
            chartView.topAnchor.constraint(equalTo: backgroundChartView.topAnchor, constant: 16),
            chartView.leftAnchor.constraint(equalTo: backgroundChartView.leftAnchor, constant: 16),
            chartView.rightAnchor.constraint(equalTo: backgroundChartView.rightAnchor, constant: -16),
            chartView.bottomAnchor.constraint(equalTo: backgroundChartView.bottomAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: backgroundChartView.bottomAnchor, constant: 10),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        tableView.separatorStyle = .none
        tableView.register(HealthDetailSampleCell.self, forCellReuseIdentifier: healthDetailSampleCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
    }
    
    func configureChart() {
        dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
        chartView.xAxis.valueFormatter = dayAxisValueFormatter
        chartView.xAxis.granularity = 1
        chartView.xAxis.labelCount = 5

        let rightAxisFormatter = NumberFormatter()
        rightAxisFormatter.numberStyle = .decimal
        let rightAxis = chartView.rightAxis
        rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)
        
        let marker = XYMarkerView(color: ThemeManager.currentTheme().generalSubtitleColor,
                                  font: .systemFont(ofSize: 12),
                                  textColor: .white,
                                  insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8),
                                  xAxisValueFormatter: dayAxisValueFormatter!, units: viewModel.healthMetric.unitName)
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
    }
    
    @objc func changeSegment(_ segmentedControl: UISegmentedControl) {        
        fetchHealthKitData()
    }
    
    @objc private func hideUnhideTapped() {
        if chartView.data != nil {
            updateChartViewAppearance(hidden: !chartView.isHidden)
        }
    }
    
    private func updateChartViewAppearance(hidden: Bool) {
        chartView.isHidden = hidden
        backgroundChartViewHeightAnchor?.constant = hidden ? 0 : chartViewHeight
        backgroundChartViewTopAnchor?.constant = hidden ? 0 : chartViewTopMargin
        barButton.title = chartView.isHidden ? "Show Chart" : "Hide Chart"
    }
    
    // MARK: HealthKit Data
    func fetchHealthKitData() {
        guard let segmentType = TimeSegmentType(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        
        backgroundChartView.isHidden = true
        tableView.isHidden = true
        
        activityIndicator.startAnimating()
        
        viewModel.fetchChartData(for: segmentType) { [weak self] (data, maxValue) in
            guard let weakSelf = self else { return }
            weakSelf.backgroundChartView.isHidden = false
            weakSelf.tableView.isHidden = false
            weakSelf.chartView.data = data
            weakSelf.chartView.rightAxis.axisMinimum = 0
            weakSelf.chartView.rightAxis.axisMaximum = maxValue
            weakSelf.dayAxisValueFormatter?.formatType = weakSelf.segmentedControl.selectedSegmentIndex
            weakSelf.chartView.resetZoom()
            weakSelf.chartView.notifyDataSetChanged()
            weakSelf.tableView.setContentOffset(weakSelf.tableView.contentOffset, animated: false)
            weakSelf.activityIndicator.stopAnimating()
            weakSelf.tableView.reloadData()
        }
    }
    
    func openSample(sample: HKSample, type: HealthMetricType) {
        switch type {
        case .steps:
            print("steps")
        case .nutrition(_):
            print("steps")
        case .workout:
            if let hkWorkout = sample as? HKWorkout {
                let destination = WorkoutViewController(networkController: self.networkController)
                destination.workout = Workout(from: hkWorkout)
                self.navigationController?.pushViewController(destination, animated: true)
            }
        case .heartRate:
            print("steps")
        case .weight:
            print("steps")
        case .sleep:
            print("steps")
        case .mindfulness:
            print("steps")
            if let hkMindfulness = sample as? HKCategorySample {
                let destination = MindfulnessViewController(networkController: self.networkController)
                destination.mindfulness = Mindfulness(from: hkMindfulness)
                self.navigationController?.pushViewController(destination, animated: true)
            }
        case .activeEnergy:
            print("steps")
        case .workoutMinutes:
            if let hkWorkout = sample as? HKWorkout {
                let destination = WorkoutViewController(networkController: self.networkController)
                destination.workout = Workout(from: hkWorkout)
                self.navigationController?.pushViewController(destination, animated: true)
            }
        case .flightsClimbed:
            print("steps")
        }
    }
}

extension HealthDetailViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
    }
}

extension HealthDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.samples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: healthDetailSampleCellID, for: indexPath) as! HealthDetailSampleCell
        if case .workout = viewModel.healthMetric.type {
            cell.selectionStyle = .default
        } else if case .mindfulness = viewModel.healthMetric.type {
            cell.selectionStyle = .default
        } else if case .workoutMinutes = viewModel.healthMetric.type {
            cell.selectionStyle = .default
        } else {
            cell.selectionStyle = .none
        }
        cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        cell.healthMetric = viewModel.healthMetric
        let sample = viewModel.samples[indexPath.row]
        cell.configure(sample)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sample = viewModel.samples[indexPath.row]
        openSample(sample: sample, type: viewModel.healthMetric.type)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
