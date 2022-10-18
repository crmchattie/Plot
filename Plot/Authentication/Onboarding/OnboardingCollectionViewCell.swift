//
//  OnboardingCollectionViewCell.swift
//  Plot
//
//  Created by Cory McHattie on 10/11/22.
//  Copyright © 2022 Immature Creations. All rights reserved.
//

import Foundation
import UIKit

class OnboardingCollectionViewCell: UICollectionViewCell, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    var colors : [UIColor] = [FalconPalette.defaultBlue, FalconPalette.defaultRed, FalconPalette.defaultDarkBlue, FalconPalette.defaultOrange, FalconPalette.defaultGreen]
    var intColor: Int = 0
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.itemSize = UICollectionViewFlowLayout.automaticSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    var customType: CustomType! {
        didSet {
            imageView.image = UIImage(named: customType.image)!.withRenderingMode(.alwaysTemplate)
            imageView.tintColor = colors[intColor]
            imageView.contentMode = .scaleAspectFit
            typeLabel.text = customType.categoryText
            descriptionLabel.text = customType.subcategoryText
            setupViews()
        }
    }
    
    var activities: [Activity]! {
        didSet {
            if let _ = activities {
                healthMetrics = nil
                finances = nil
                setupViews()
                collectionView.reloadData()
            }
        }
    }
    var healthMetrics: [HealthMetric]! {
        didSet {
            if let _ = healthMetrics {
                activities = nil
                finances = nil
                setupViews()
                collectionView.reloadData()
            }
        }
    }
    var finances: [AnyHashable]! {
        didSet {
            if let _ = finances {
                activities = nil
                healthMetrics = nil
                setupViews()
                collectionView.reloadData()
            }
        }
    }
    
    let typeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.title1.with(weight: .bold)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.title3.with(weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.adjustsFontForContentSizeCategory = true
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
                
        collectionView.register(TaskCollectionCell.self, forCellWithReuseIdentifier: taskCellID)
        collectionView.register(EventCollectionCell.self, forCellWithReuseIdentifier: eventCellID)
        collectionView.register(HealthMetricCell.self, forCellWithReuseIdentifier: healthMetricCellID)
        collectionView.register(FinanceCollectionViewComparisonCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewComparisonCell)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        typeLabel.textColor = .label
        descriptionLabel.textColor = .label
        
    }
    
    func setupViews() {
        
        addSubview(typeLabel)
        addSubview(descriptionLabel)
        addSubview(containerView)
        
        typeLabel.anchor(top: topAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 30, bottom: 0, right: 30))
        descriptionLabel.anchor(top: typeLabel.bottomAnchor, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 20, left: 30, bottom: 0, right: 30))
        containerView.anchor(top: descriptionLabel.bottomAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 20, left: 0, bottom: 0, right: 0))
        
        containerView.addSubview(collectionView)
        collectionView.fillSuperview()
        
        collectionView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ])
        
        containerView.backgroundColor = .systemGroupedBackground
        containerView.layer.masksToBounds = true
        containerView.layer.cornerRadius = 10
        collectionView.backgroundColor = .systemGroupedBackground
        imageView.backgroundColor = .clear
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let activities = activities {
            imageView.isHidden = true
            return activities.count
        } else if let healthMetrics = healthMetrics {
            imageView.isHidden = true
            return healthMetrics.count
        } else if let finances = finances {
            imageView.isHidden = true
            return finances.count
        } else {
            imageView.isHidden = false
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let activities = activities {
            let item = activities[indexPath.item]
            if item.isTask ?? false {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: taskCellID, for: indexPath) as? TaskCollectionCell ?? TaskCollectionCell()
                cell.configureCell(for: indexPath, task: item)
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: eventCellID, for: indexPath) as? EventCollectionCell ?? EventCollectionCell()
                cell.configureCell(for: indexPath, activity: item, withInvitation: nil)
                return cell
            }
        } else if let healthMetrics = healthMetrics {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
            let metric = healthMetrics[indexPath.item]
            cell.configure(metric)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
            if let finances = finances {
                if let item = finances[indexPath.item] as? TransactionDetails {
                    cell.transactionDetails = item
                } else if let item = finances[indexPath.item] as? AccountDetails {
                    cell.accountDetails = item
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        if let activities = activities {
            let item = activities[indexPath.item]
            if item.isTask ?? false {
                let dummyCell = TaskCollectionCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                dummyCell.configureCell(for: indexPath, task: item)
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                height = estimatedSize.height
            } else {
                let dummyCell = EventCollectionCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
                dummyCell.configureCell(for: indexPath, activity: item, withInvitation: nil)
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
                height = estimatedSize.height
            }
        } else if let healthMetrics = healthMetrics {
            let dummyCell = HealthMetricCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            let metric = healthMetrics[indexPath.item]
            dummyCell.configure(metric)
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        } else if let finances = finances {
            if let item = finances[indexPath.item] as? TransactionDetails {
                let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
                dummyCell.transactionDetails = item
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
                height = estimatedSize.height
            } else if let item = finances[indexPath.item] as? AccountDetails {
                let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewComparisonCell, for: indexPath) as! FinanceCollectionViewComparisonCell
                dummyCell.accountDetails = item
                dummyCell.layoutIfNeeded()
                let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
                height = estimatedSize.height
            }
        }
        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)
    }
}
