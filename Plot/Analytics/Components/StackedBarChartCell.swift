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

protocol StackedBarChartCellDelegate: AnyObject {
    func nextTouched(on cell: StackedBarChartCell)
    func previousTouched(on cell: StackedBarChartCell)
}

class StackedBarChartCell: UITableViewCell {

    weak var delegate: StackedBarChartCellDelegate?
    
    private(set) var viewModel: StackedBarChartViewModel?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.addTarget(self, action: #selector(nextTouched), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    
    private lazy var previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.addTarget(self, action: #selector(previousTouched), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    
    lazy var prevNextStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [previousButton, nextButton])
        stackView.isHidden = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    lazy var chartContainer: UIView = {
        UIView()
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

    func initUI() {
        selectionStyle = .none
        backgroundColor = .tertiarySystemBackground

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel, chartContainer, categoriesStackView])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(0, after: titleLabel)
        contentView.addSubview(stack)
        
        contentView.addSubview(prevNextStackView)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            chartContainer.heightAnchor.constraint(equalToConstant: 150),
            prevNextStackView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            prevNextStackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
    }
    
    func updateData() {
        categoriesStackView.arrangedSubviews.forEach {
            categoriesStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        guard let viewModel = viewModel else { return }
        
        titleLabel.text = viewModel.rangeDescription
        valueLabel.text = viewModel.rangeAverageValue

        viewModel.categories.forEach { category in
            let categoryView = CategoryTimeView()
            categoryView.titleLabel.text = category.title
            categoryView.titleLabel.textColor = category.color
            categoryView.subtitleLabel.text = category.formattedValue
            categoriesStackView.addArrangedSubview(categoryView)
        }
    }
    
    // MARK: - Actios
    
    @objc private func nextTouched() {
        delegate?.nextTouched(on: self)
    }
    
    @objc private func previousTouched() {
        delegate?.previousTouched(on: self)
    }
}

// MARK: - Private

private class CategoryTimeView: UIStackView {

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
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
