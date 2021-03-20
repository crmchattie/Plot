//
//  StackedBarChartCell.swift
//  Plot
//
//  Created by Botond Magyarosi on 11/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Charts
import Combine

class StackedBarChartCell: UITableViewCell {

    private var viewModel: StackedBarChartViewModel?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.textColor = .label
        return label
    }()

    private lazy var chartView: BarChartView = {
        let chart = BarChartView()
        
        chart.legend.enabled = false
        chart.pinchZoomEnabled = false
        chart.doubleTapToZoomEnabled = false
        chart.setScaleEnabled(false)
        chart.highlightPerTapEnabled = false
        chart.highlightPerDragEnabled = false
        chart.minOffset = 0

        chart.leftAxis.enabled = false
        chart.leftAxis.axisMinimum = 0
        chart.rightAxis.axisMinimum = 0
        chart.rightAxis.drawAxisLineEnabled = false
        chart.rightAxis.labelTextColor = .secondaryLabel
        
        chart.xAxis.yOffset = 1

        chart.xAxis.gridColor = .secondaryLabel
        chart.xAxis.gridLineDashLengths = [2, 2]
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.centerAxisLabelsEnabled = true
        chart.xAxis.labelTextColor = .secondaryLabel
        chart.xAxis.valueFormatter = WeekdayValueFormatter()

        return chart
    }()

    private lazy var categoriesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        return stackView
    }()
    
    private var subscription: AnyCancellable?
    
    func configure(with viewModel: StackedBarChartViewModel) {
        self.viewModel = viewModel
        chartView.rightAxis.valueFormatter = viewModel.verticalAxisValueFormatter
        subscription = viewModel.onChange.sink { _  in
            self.updateData()
        }
        updateData()
    }

    // MARK: - Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initUI() {
        selectionStyle = .none
        backgroundColor = .tertiarySystemBackground

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, chartView, categoriesStackView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(0, after: titleLabel)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            chartView.heightAnchor.constraint(equalToConstant: 150)
        ])
    }
    
    private func updateData() {
        categoriesStackView.arrangedSubviews.forEach {
            categoriesStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard let viewModel = viewModel else {
            chartView.data = nil
            return
        }
        
        chartView.data = viewModel.chartData
        
        titleLabel.text = viewModel.title
        valueLabel.text = viewModel.description

        viewModel.categories.forEach { category in
            let categoryView = CategoryTimeView()
            categoryView.titleLabel.text = category.title
            categoryView.titleLabel.textColor = category.color
            categoryView.subtitleLabel.text = category.formattedValue
            categoriesStackView.addArrangedSubview(categoryView)
        }
    }
}

// MARK: - Private

private class CategoryTimeView: UIStackView {

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        return label
    }()

    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        return label
    }()

    init() {
        super.init(frame: .zero)
        initUI()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private func initUI() {
        axis = .vertical
        addArrangedSubview(titleLabel)
        addArrangedSubview(subtitleLabel)
    }
}
