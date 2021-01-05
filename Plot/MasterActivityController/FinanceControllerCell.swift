//
//  FinanceControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

protocol FinanceControllerCellDelegate: class {
    func openTransactionDetails(transactionDetails: TransactionDetails)
    func openAccountDetails(accountDetails: AccountDetails)
    func openMember(member: MXMember)
}

class FinanceControllerCell: BaseContainerCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var delegate: FinanceControllerCellDelegate?
    
    let kHeaderCell = "HeaderCell"
    let kFinanceCollectionViewCell = "FinanceCollectionViewCell"
    let kFinanceCollectionViewMemberCell = "FinanceCollectionViewMemberCell"
    
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 20, right: 10)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInset.bottom = 0
        return collectionView
    }()
        
    var institutionDict = [String: String]()
    
    var sections = [SectionType]()
    var groups = [SectionType: [AnyHashable]]() {
        didSet {
            setupViews()
            collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 16
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        
        collectionView.backgroundColor = backgroundColor
        
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kHeaderCell)
        collectionView.register(FinanceCollectionViewCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewCell)
        collectionView.register(FinanceCollectionViewMemberCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewMemberCell)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func setupViews() {
        super.setupViews()
        addSubview(collectionView)
        collectionView.fillSuperview(padding: .init(top: 15, left: 5, bottom: 0, right: 5))
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sec = sections[section]
        return groups[sec]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let object = groups[section]
        if section != .financialIssues {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            cell.mode = .small
            if let object = object as? [TransactionDetails] {
                cell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                cell.accountDetails = object[indexPath.item]
            } else if let object = object as? [Transaction] {
                cell.transaction = object[indexPath.item]
            } else if let object = object as? [MXAccount] {
                cell.account = object[indexPath.item]
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.kFinanceCollectionViewMemberCell, for: indexPath) as! FinanceCollectionViewMemberCell
            cell.backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
            if let object = object as? [MXMember] {
                if let imageURL = institutionDict[object[indexPath.item].institution_code] {
                    cell.imageURL = imageURL
                    cell.member = object[indexPath.item]
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        let section = sections[indexPath.section]
        let object = groups[section]
        if section != .financialIssues {
            let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width - 20, height: 1000))
            dummyCell.mode = .small
            if let object = object as? [TransactionDetails] {
                dummyCell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                dummyCell.accountDetails = object[indexPath.item]
            } else if let object = object as? [Transaction] {
                dummyCell.transaction = object[indexPath.item]
            } else if let object = object as? [MXAccount] {
                dummyCell.account = object[indexPath.item]
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: frame.width - 20, height: 1000))
            height = estimatedSize.height
        } else {
            let dummyCell = FinanceCollectionViewMemberCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width - 20, height: 1000))
            if let object = object as? [MXMember] {
                if let imageURL = institutionDict[object[indexPath.item].institution_code] {
                    dummyCell.imageURL = imageURL
                    dummyCell.member = object[indexPath.item]
                }
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: frame.width - 20, height: 1000))
            height = estimatedSize.height
        }
        return CGSize(width: self.collectionView.frame.size.width - 20, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = sections[indexPath.section]
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.kHeaderCell, for: indexPath) as! HeaderCell
        header.titleLabel.text = section.name
        header.subTitleLabel.isHidden = true
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
        let object = groups[section]
        if let object = object as? [TransactionDetails] {
            if section.subType == "Income Statement" {
                let transactionDetails = object[indexPath.item]
                delegate?.openTransactionDetails(transactionDetails: transactionDetails)
            }
        } else if let object = object as? [AccountDetails] {
            if section.subType == "Balance Sheet" {
                let accountDetails = object[indexPath.item]
                delegate?.openAccountDetails(accountDetails: accountDetails)
            }
        } else if let object = object as? [MXMember] {
            if section.type == "Issues" {
                let member = object[indexPath.item]
                delegate?.openMember(member: member)
            }
        }
    }
}
