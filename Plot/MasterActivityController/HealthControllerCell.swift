//
//  HealthControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

protocol HealthControllerCellDelegate: class {
    func cellTapped(metric: HealthMetric)
}

class HealthControllerCell: UICollectionViewCell, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    weak var delegate: HealthControllerCellDelegate?
    
    let healthMetricCellID = "HealthMetricCellID"
    let healthMetricSectionHeaderID = "HealthMetricSectionHeaderID"
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    var healthMetricSections: [String] = []
    var healthMetrics: [String: [HealthMetric]] = [:] {
        didSet {
            setupViews()
            collectionView.reloadData()
        }
    }
    
    let viewPlaceholder = ViewPlaceholder()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
                
        collectionView.register(HealthMetricCell.self, forCellWithReuseIdentifier: healthMetricCellID)
        collectionView.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: healthMetricSectionHeaderID)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
        collectionView.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
        addSubview(collectionView)
        collectionView.fillSuperview()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if healthMetricSections.count == 0 {
            viewPlaceholder.add(for: collectionView, title: .emptyHealth, subtitle: .emptyHealth, priority: .medium, position: .fill)
        } else {
            viewPlaceholder.remove(from: collectionView, priority: .medium)
        }
        return healthMetricSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let key = healthMetricSections[section]
        return healthMetrics[key]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
        let key = healthMetricSections[indexPath.section]
        if let metrics = healthMetrics[key] {
            let metric = metrics[indexPath.row]
            cell.configure(metric)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        var height: CGFloat = 0
//        let dummyCell = collectionView.dequeueReusableCell(withReuseIdentifier: healthMetricCellID, for: indexPath) as! HealthMetricCell
//        let key = healthMetricSections[indexPath.section]
//        if let metrics = healthMetrics[key] {
//            let metric = metrics[indexPath.row]
//            dummyCell.configure(metric)
//            dummyCell.layoutIfNeeded()
//            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
//            print("estimatedHeight \(estimatedSize.height)")
//            height = estimatedSize.height
//        }
        return CGSize(width: self.collectionView.frame.size.width - 30, height: 85)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let key = healthMetricSections[indexPath.section]
            let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: healthMetricSectionHeaderID, for: indexPath) as! SectionHeader
            sectionHeader.backgroundColor = ThemeManager.currentTheme().generalBackgroundColor
            sectionHeader.subTitleLabel.isHidden = true
            sectionHeader.titleLabel.text = key.capitalized
            return sectionHeader
        } else { //No footer in this case but can add option for that
            return UICollectionReusableView()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let key = healthMetricSections[indexPath.section]
        if let metrics = healthMetrics[key] {
            let metric = metrics[indexPath.row]
            delegate?.cellTapped(metric: metric)
        }
    }
    
}
