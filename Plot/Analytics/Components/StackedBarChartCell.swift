//
//  StackedBarChartCell.swift
//  Plot
//
//  Created by Botond Magyarosi on 11/03/2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Charts

class StackedBarChartCell: UITableViewCell {

    private let viewModel = StackedBarChartViewModel()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        label.text = "Daily Average"
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.textColor = .label
        label.text = "6h 1m"
        return label
    }()

    private lazy var chartView: BarChartView = {
        let chart = BarChartView()
        chart.legend.enabled = false
        chart.pinchZoomEnabled = false
        chart.doubleTapToZoomEnabled = false
        chart.setScaleEnabled(false)

        chart.leftAxis.enabled = false
        chart.rightAxis.drawAxisLineEnabled = false
        chart.rightAxis.labelTextColor = .secondaryLabel
        chart.minOffset = 0

        chart.xAxis.gridColor = .secondaryLabel
        chart.xAxis.gridLineDashLengths = [2, 2]
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.labelTextColor = .secondaryLabel

        return chart
    }()

    private lazy var categoriesStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fillProportionally
        return stackView
    }()

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
        backgroundColor = .secondarySystemBackground

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
        chartView.data = viewModel.chartData

        #warning("Delete later")
        let social = CategoryTimeView()
        social.titleLabel.text = "Social"
        social.titleLabel.textColor = .blue
        social.subtitleLabel.text = "4h 10m"
        categoriesStackView.addArrangedSubview(social)

        let productivity = CategoryTimeView()
        productivity.titleLabel.text = "Productivity & Finance"
        productivity.titleLabel.textColor = .orange
        productivity.subtitleLabel.text = "3h 5m"
        categoriesStackView.addArrangedSubview(productivity)

        let work = CategoryTimeView()
        work.titleLabel.text = "Work"
        work.titleLabel.textColor = .lightGray
        work.subtitleLabel.text = "6h 30m"
        categoriesStackView.addArrangedSubview(work)
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
//        super.init(arrangedSubviews: [])
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
