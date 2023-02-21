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
fileprivate let chartViewHeight: CGFloat = 300
fileprivate let chartViewTopMargin: CGFloat = 10

class HealthDetailViewController: UIViewController, ObjectDetailShowing {
    private var viewModel: HealthDetailViewModelInterface
    var dayAxisValueFormatter: DayAxisValueFormatter?
    var backgroundChartViewHeightAnchor: NSLayoutConstraint?
    var backgroundChartViewTopAnchor: NSLayoutConstraint?
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
        
    lazy var backgroundChartView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var bufferView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
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
    
    lazy var participants = [String : [User]]()
        
    init(viewModel: HealthDetailViewModelInterface, networkController: NetworkController) {
        self.viewModel = viewModel
        self.networkController = networkController
        super.init(nibName: nil, bundle: nil)
        //self.viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .never
        
        extendedLayoutIncludesOpaqueBars = true
        
//        barButton = UIBarButtonItem(title: "Hide Chart", style: .plain, target: self, action: #selector(hideUnhideTapped))
//        navigationItem.rightBarButtonItem = barButton
        
        if case HealthMetricType.workout = viewModel.healthMetric.type, let hkWorkout = viewModel.healthMetric.hkSample as? HKWorkout {
            title = hkWorkout.workoutActivityType.name
        }
        else if case HealthMetricType.nutrition(let name) = viewModel.healthMetric.type {
            title = name
        }
        else {
            self.title = viewModel.healthMetric.type.name
        }
        
        view.backgroundColor = .systemGroupedBackground
        containerView.backgroundColor = .systemBackground
        backgroundChartView.backgroundColor = .systemBackground
        chartView.backgroundColor = .systemBackground
        bufferView.backgroundColor = .systemGroupedBackground
        
        view.addSubview(activityIndicator)
        
        containerView.addSubview(segmentedControl)
        containerView.addSubview(backgroundChartView)
        containerView.addSubview(bufferView)
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
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        segmentedControl.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10).isActive = true
        segmentedControl.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 16).isActive = true
        segmentedControl.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: -16).isActive = true
        
        backgroundChartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10).isActive = true
        backgroundChartView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 0).isActive = true
        backgroundChartView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0).isActive = true
        backgroundChartView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10).isActive = true
        
        chartView.topAnchor.constraint(equalTo: backgroundChartView.topAnchor, constant: 10).isActive = true
        chartView.leftAnchor.constraint(equalTo: backgroundChartView.leftAnchor, constant: 10).isActive = true
        chartView.rightAnchor.constraint(equalTo: backgroundChartView.rightAnchor, constant: -5).isActive = true
        chartView.bottomAnchor.constraint(equalTo: backgroundChartView.bottomAnchor, constant: -10).isActive = true
        
        bufferView.topAnchor.constraint(equalTo: backgroundChartView.bottomAnchor, constant: 0).isActive = true
        bufferView.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 0).isActive = true
        bufferView.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0).isActive = true
        bufferView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0).isActive = true
        
        containerView.constrainHeight(340)
        tableView.tableHeaderView = containerView
        containerView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor).isActive = true
        containerView.widthAnchor.constraint(equalTo: tableView.widthAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: tableView.topAnchor).isActive = true
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView = tableView.tableHeaderView
        
        tableView.separatorStyle = .none
        tableView.register(HealthDetailSampleCell.self, forCellReuseIdentifier: healthDetailSampleCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = .default
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
    }
    
    func configureChart() {
        dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
        chartView.xAxis.valueFormatter = dayAxisValueFormatter
        chartView.xAxis.labelFont = UIFont.caption1.with(weight: .regular)
        chartView.leftAxis.enabled = false
        
        let rightAxisFormatter = NumberFormatter()
        rightAxisFormatter.numberStyle = .decimal
        let rightAxis = chartView.rightAxis
        rightAxis.enabled = true
        rightAxis.labelFont = UIFont.caption1.with(weight: .regular)
        rightAxis.valueFormatter = DefaultAxisValueFormatter(formatter: rightAxisFormatter)
        
        let marker = XYMarkerView(color: .systemGroupedBackground,
                                  font: UIFont.body.with(weight: .regular),
                                  textColor: .label,
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
        
        viewModel.fetchChartData(for: segmentType) { [weak self] (data) in
            guard let weakSelf = self else { return }
            weakSelf.backgroundChartView.isHidden = false
            weakSelf.tableView.isHidden = false
            weakSelf.chartView.data = data
            weakSelf.chartView.rightAxis.axisMinimum = 0
            weakSelf.dayAxisValueFormatter?.formatType = weakSelf.segmentedControl.selectedSegmentIndex
            weakSelf.chartView.highlightValue(nil)
            weakSelf.chartView.resetZoom()
            weakSelf.chartView.notifyDataSetChanged()
            weakSelf.tableView.setContentOffset(weakSelf.tableView.contentOffset, animated: false)
            weakSelf.activityIndicator.stopAnimating()
            weakSelf.tableView.reloadData()
        }
    }
    
    func openSample(sample: HKSample) {
        if let hkWorkout = sample as? HKWorkout {
            let hkSampleID = hkWorkout.uuid.uuidString
            if let workout = self.networkController.healthService.workouts.first(where: {$0.hkSampleID == hkSampleID }) {
                showWorkoutDetailPresent(workout: workout, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
            }
        }
        else if let hkMindfulness = sample as? HKCategorySample {
            let hkSampleID = hkMindfulness.uuid.uuidString
            if let mindfulness = self.networkController.healthService.mindfulnesses.first(where: {$0.hkSampleID == hkSampleID }) {
                showMindfulnessDetailPresent(mindfulness: mindfulness, updateDiscoverDelegate: nil, delegate: nil, template: nil, users: nil, container: nil, movingBackwards: nil)
            }
        }
    }
}

extension HealthDetailViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let date = entry.data as? Date  else { return }
        viewModel.filterSamples(date: date) {
            tableView.reloadData()
        }
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        viewModel.filterSamples(date: nil) {
            tableView.reloadData()
        }
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
    }
}

extension HealthDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        cell.backgroundColor = .secondarySystemGroupedBackground
        cell.healthMetric = viewModel.healthMetric
        let sample = viewModel.samples[indexPath.row]
        let segmentType = TimeSegmentType(rawValue: segmentedControl.selectedSegmentIndex)
        cell.configure(sample, segmentType: segmentType ?? .year)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sample = viewModel.samples[indexPath.row]
        openSample(sample: sample)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
