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

fileprivate let sampleCellID = "sampleCellID"

class HealthDetailViewController: UIViewController {
    
    private var viewModel: HealthDetailViewModelInterface
    var dayAxisValueFormatter: DayAxisValueFormatter?
    
    lazy var chartView: LineChartView = {
        let chartView = LineChartView()
        chartView.translatesAutoresizingMaskIntoConstraints = false
        return chartView
    }()
    
    lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["D", "W", "M", "Y"])
        segmentedControl.addTarget(self, action: #selector(changeSegment(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return tableView
    }()
    
    init(viewModel: HealthDetailViewModelInterface) {
        self.viewModel = viewModel
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if viewModel.healthMetric.type == HealthMetricType.workout, let hkWorkout = viewModel.healthMetric.hkWorkout {
            title = hkWorkout.workoutActivityType.name
        } else {
            self.title = viewModel.healthMetric.type.name
        }
        
        addObservers()
        changeTheme()
        
        view.addSubview(chartView)
        chartView.delegate = self
        
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        
        view.addSubview(segmentedControl)
        segmentedControl.selectedSegmentIndex = 0
        
        configureView()
        configureChart()
        
        fetchHealthKitData()
    }
    
    private func configureView() {
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            segmentedControl.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            segmentedControl.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            
            chartView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            chartView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16),
            chartView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: 260),
            
            tableView.topAnchor.constraint(equalTo: chartView.bottomAnchor, constant: 10),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        tableView.separatorStyle = .none
        tableView.register(HealthMetricCell.self, forCellReuseIdentifier: sampleCellID)
        tableView.allowsMultipleSelectionDuringEditing = false
        tableView.indicatorStyle = ThemeManager.currentTheme().scrollBarStyle
        tableView.backgroundColor = view.backgroundColor
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 105
    }
    
    func configureChart() {
        
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelPosition = .bottom
        xAxis.labelFont = .systemFont(ofSize: 10)
        xAxis.granularity = 1
        xAxis.labelCount = 5
        dayAxisValueFormatter = DayAxisValueFormatter(chart: chartView)
        dayAxisValueFormatter?.formatType = segmentedControl.selectedSegmentIndex
        xAxis.valueFormatter = dayAxisValueFormatter

        let rightAxis = chartView.rightAxis
        rightAxis.removeAllLimitLines()
        rightAxis.axisMinimum = 0
        rightAxis.drawLimitLinesBehindDataEnabled = true
        
        chartView.leftAxis.enabled = false

        let marker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                   font: .systemFont(ofSize: 12),
                                   textColor: .white,
                                   insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = chartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chartView.marker = marker
        
        chartView.legend.form = .line
    }
    
    @objc func changeSegment(_ segmentedControl: UISegmentedControl) {        
        fetchHealthKitData()
    }
    
    // MARK: HealthKit Data
    func fetchHealthKitData() {
        guard let segmentType = TimeSegmentType(rawValue: segmentedControl.selectedSegmentIndex) else { return }
        
        viewModel.fetchChartData(for: segmentType) { [weak self] (data, maxValue) in
            guard let weakSelf = self else { return }
            
            weakSelf.chartView.data = data
            weakSelf.chartView.rightAxis.axisMaximum = maxValue
            weakSelf.dayAxisValueFormatter?.formatType = weakSelf.segmentedControl.selectedSegmentIndex
            weakSelf.chartView.resetZoom()
            weakSelf.chartView.animate(xAxisDuration: 1)
            weakSelf.tableView.reloadData()
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.samples.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: sampleCellID, for: indexPath)
        cell.backgroundColor = tableView.backgroundColor
        let sample = viewModel.samples[indexPath.row]
        let interval = NSDateInterval(start: sample.startDate, end: sample.endDate)
        cell.textLabel?.text = interval.duration.stringTime

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyy at hh:mm:ss a"
        
        cell.detailTextLabel?.text = dateFormatter.string(from: sample.startDate)
        return cell
    }
}

enum TimeSegmentType: Int {
    case day = 0
    case week
    case month
    case year
}