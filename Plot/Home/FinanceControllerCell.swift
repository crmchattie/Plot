//
//  FinanceControllerCell.swift
//  Plot
//
//  Created by Cory McHattie on 12/22/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

protocol FinanceControllerCellDelegate: AnyObject {
    func openTransactionDetails(transactionDetails: TransactionDetails)
    func openAccountDetails(accountDetails: AccountDetails)
    func openMember(member: MXMember)
    func openHolding(holding: MXHolding)
    func openTransaction(transaction: Transaction)
    func viewTappedFinance(sectionType: SectionType)
}

class FinanceControllerCell: UICollectionViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var delegate: FinanceControllerCellDelegate?
                
    let collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
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
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        
        collectionView.register(HeaderCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: kHeaderCell)
        collectionView.register(FinanceCollectionViewCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewCell)
        collectionView.register(FinanceCollectionViewMemberCell.self, forCellWithReuseIdentifier: kFinanceCollectionViewMemberCell)

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func setupViews() {
        collectionView.backgroundColor = .systemGroupedBackground
        addSubview(collectionView)
        collectionView.fillSuperview()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sec = sections[section]
        if sec == .transactions {
            if groups[sec]?.count ?? 0 < 3 {
                return groups[sec]?.count ?? 0
            }
            return 3
        }
        return groups[sec]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        let object = groups[section]
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section) - 1
        if section != .financialIssues {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewCell, for: indexPath) as! FinanceCollectionViewCell
            cell.mode = .small
            if indexPath.item == 0 {
                cell.firstPosition = true
            }
            if indexPath.item == totalItems {
                cell.lastPosition = true
            }
            if let object = object as? [TransactionDetails] {
                cell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                cell.accountDetails = object[indexPath.item]
            } else if let object = object as? [MXHolding] {
                cell.holding = object[indexPath.item]
            } else if let object = object as? [Transaction] {
                cell.firstPosition = true
                cell.lastPosition = true
                cell.transaction = object[indexPath.item]
            } 
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kFinanceCollectionViewMemberCell, for: indexPath) as! FinanceCollectionViewMemberCell
            if let object = object as? [MXMember] {
                cell.member = object[indexPath.item]
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 328
        let section = sections[indexPath.section]
        let object = groups[section]
        let totalItems = collectionView.numberOfItems(inSection: indexPath.section) - 1
        if section != .financialIssues {
            let dummyCell = FinanceCollectionViewCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            dummyCell.mode = .small
            if indexPath.item == 0 {
                dummyCell.firstPosition = true
            }
            if indexPath.item == totalItems {
                dummyCell.lastPosition = true
            }
            if let object = object as? [TransactionDetails] {
                dummyCell.transactionDetails = object[indexPath.item]
            } else if let object = object as? [AccountDetails] {
                dummyCell.accountDetails = object[indexPath.item]
            } else if let object = object as? [Transaction] {
                dummyCell.firstPosition = true
                dummyCell.lastPosition = true
                dummyCell.transaction = object[indexPath.item]
            } else if let object = object as? [MXAccount] {
                dummyCell.account = object[indexPath.item]
            } else if let object = object as? [MXHolding] {
                dummyCell.holding = object[indexPath.item]
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width, height: 1000))
            height = estimatedSize.height
        } else {
            let dummyCell = FinanceCollectionViewMemberCell(frame: .init(x: 0, y: 0, width: self.collectionView.frame.size.width, height: 1000))
            if let object = object as? [MXMember] {
                dummyCell.member = object[indexPath.item]
            }
            dummyCell.layoutIfNeeded()
            let estimatedSize = dummyCell.systemLayoutSizeFitting(.init(width: self.collectionView.frame.size.width - 30, height: 1000))
            height = estimatedSize.height
        }
        return CGSize(width: self.collectionView.frame.size.width - 30, height: height)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.collectionView.frame.size.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = sections[indexPath.section]
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: kHeaderCell, for: indexPath) as! HeaderCell
        header.backgroundColor = .systemGroupedBackground
        header.delegate = self
        header.sectionType = section
        header.titleLabel.text = section.name
        if section == .transactions && groups[section]?.count ?? 0 > 3 {
            header.view.isUserInteractionEnabled = true
            header.subTitleLabel.isHidden = false
        } else {
            header.view.isUserInteractionEnabled = false
            header.subTitleLabel.isHidden = true
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        let section = sections[section]
        if section == .transactions || section == .financialAccounts || section == .financialIssues {
            return 10
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
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
        } else if let object = object as? [Transaction] {
            if section.subType == "Transactions" {
                let transaction = object[indexPath.item]
                delegate?.openTransaction(transaction: transaction)
            }
        } else if let object = object as? [MXHolding] {
            if section.subType == "Investments" {
                let holding = object[indexPath.item]
                delegate?.openHolding(holding: holding)
            }
        } else if let object = object as? [MXMember] {
            if section.type == "Issues" {
                let member = object[indexPath.item]
                delegate?.openMember(member: member)
            }
        }
    }
}

extension FinanceControllerCell: HeaderCellDelegate {
    func viewTapped(sectionType: SectionType) {
        delegate?.viewTappedFinance(sectionType: sectionType)
    }
}
