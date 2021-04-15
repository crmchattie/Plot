//
//  AnalyticsDetailViewController.swift
//  Plot
//
//  Created by Botond Magyarosi on 16.03.2021.
//  Copyright © 2021 Immature Creations. All rights reserved.
//

import UIKit
import Combine
import Firebase

class AnalyticsDetailViewController: UIViewController, ActivityDetailShowing {
    
    var networkController: NetworkController { viewModel.networkController }
    
    private let viewModel: AnalyticsDetailViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    // activities
    var activitiesParticipants: [String : [User]] = [:]
    // transaction
    var users = [User]()
    var filteredUsers = [User]()
    var participants: [String: [User]] = [:]
    
    private let rangeControlView: UISegmentedControl = {
        let control = UISegmentedControl(items: DateRangeType.allCases.map { $0.filterTitle } )
        control.selectedSegmentIndex = 0
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(rangeChanged), for: .valueChanged)
        return control
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(AnalyticsBarChartCell.self)
        tableView.register(AnalyticsLineChartCell.self)
        tableView.register(ActivityCell.self)
        tableView.register(FinanceTableViewCell.self)
        return tableView
    }()
    
    // MARK: - Lifecycle
    
    init(viewModel: AnalyticsDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.title = viewModel.title
        
        let rangeContainer = UIView()
        rangeContainer.translatesAutoresizingMaskIntoConstraints = false
        rangeContainer.addSubview(rangeControlView)
        
        NSLayoutConstraint.activate([
            rangeControlView.leadingAnchor.constraint(equalTo: rangeContainer.leadingAnchor, constant: 8),
            rangeControlView.topAnchor.constraint(equalTo: rangeContainer.topAnchor, constant: 16),
            rangeControlView.trailingAnchor.constraint(equalTo: rangeContainer.trailingAnchor, constant: -8),
            rangeControlView.bottomAnchor.constraint(equalTo: rangeContainer.bottomAnchor, constant: -16)
        ])
        
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = rangeContainer
        if viewModel.title == "Activities" {
            tableView.separatorStyle = .none
        }
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView?.frame.size.width = self.view.bounds.width
        tableView.tableHeaderView = self.tableView.tableHeaderView
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rangeContainer.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        initBindings()
    }
    
    func showActivityIndicator() {
        if let tabController = self.tabBarController {
            self.showSpinner(onView: tabController.view)
        }
        self.navigationController?.view.isUserInteractionEnabled = false
    }
    
    func hideActivityIndicator() {
        self.navigationController?.view.isUserInteractionEnabled = true
        self.removeSpinner()
    }
    
    private func initBindings() {
        viewModel.entries
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.chartViewModel
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] _ in
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    private func showTranscationDetail(transaction: Transaction) {
        let destination = FinanceTransactionViewController()
        destination.transaction = transaction
        destination.users = users
        destination.filteredUsers = filteredUsers
        destination.delegate = self
        self.getParticipants(transaction: transaction, account: nil) { (participants) in
            destination.selectedFalconUsers = participants
            self.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
    @objc private func rangeChanged(_ sender: UISegmentedControl) {
        viewModel.range.type = DateRangeType.allCases[sender.selectedSegmentIndex]
    }
    
    // MARK: - Data
    
    func getParticipants(transaction: Transaction?, account: MXAccount?, completion: @escaping ([User])->()) {
        if let transaction = transaction, let participantsIDs = transaction.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = transaction.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if transaction.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else if let account = account, let participantsIDs = account.participantsIDs, let currentUserID = Auth.auth().currentUser?.uid {
            let group = DispatchGroup()
            let ID = account.guid
            let olderParticipants = self.participants[ID]
            var participants: [User] = []
            for id in participantsIDs {
                if account.admin == currentUserID && id == currentUserID {
                    continue
                }
                
                if let first = olderParticipants?.filter({$0.id == id}).first {
                    participants.append(first)
                    continue
                }
                
                group.enter()
                let participantReference = Database.database().reference().child("users").child(id)
                participantReference.observeSingleEvent(of: .value, with: { (snapshot) in
                    if snapshot.exists(), var dictionary = snapshot.value as? [String: AnyObject] {
                        dictionary.updateValue(snapshot.key as AnyObject, forKey: "id")
                        let user = User(dictionary: dictionary)
                        participants.append(user)
                    }
                    
                    group.leave()
                })
            }
            
            group.notify(queue: .main) {
                self.participants[ID] = participants
                completion(participants)
            }
        } else {
            let participants: [User] = []
            completion(participants)
        }
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension AnalyticsDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { 2 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : viewModel.entries.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let chartViewModel = viewModel.chartViewModel.value
            switch chartViewModel.chartType {
            case .continous:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsLineChartCell.self, for: indexPath)
                cell.prevNextStackView.isHidden = false
                cell.chartView.highlightPerTapEnabled = true
                cell.chartView.highlightPerDragEnabled = true
                cell.delegate = self
                cell.configure(with: chartViewModel)
                return cell
            case .values:
                let cell = tableView.dequeueReusableCell(ofType: AnalyticsBarChartCell.self, for: indexPath)
                cell.prevNextStackView.isHidden = false
                cell.chartView.highlightPerTapEnabled = true
                cell.chartView.highlightPerDragEnabled = true
                cell.delegate = self
                cell.configure(with: chartViewModel)
                return cell
            }
        } else {
            switch viewModel.entries.value[indexPath.row] {
            case .activity(let activity):
                let cell = tableView.dequeueReusableCell(ofType: ActivityCell.self, for: indexPath)
                cell.configureCell(for: indexPath, activity: activity, withInvitation: nil)
                return cell
            case .transaction(let transaction):
                let cell = tableView.dequeueReusableCell(ofType: FinanceTableViewCell.self, for: indexPath)
                cell.transaction = transaction
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard indexPath.section > 0 else { return }
        
        switch viewModel.entries.value[indexPath.row] {
        case .activity(let activity):
            showActivityDetail(activity: activity)
        case .transaction(let transaction):
            showTranscationDetail(transaction: transaction)
        }
    }
}

// MARK: - StackedBarChartCellDelegate

extension AnalyticsDetailViewController: StackedBarChartCellDelegate {
    
    func previousTouched(on cell: StackedBarChartCell) {
        viewModel.loadPreviousSegment()
    }
    
    func nextTouched(on cell: StackedBarChartCell) {
        viewModel.loadNextSegment()
    }
}

// MARK: - UpdateTransactionDelegate

extension AnalyticsDetailViewController: UpdateTransactionDelegate {
    
    func updateTransaction(transaction: Transaction) {
        guard let index = viewModel.entries.value.firstIndex(where: {
            if case .transaction(let trs) = $0 {
                return trs == transaction
            }
            return false
        }) else { return }
        viewModel.entries.value[index] = .transaction(transaction)
        tableView.reloadData()
    }
}
