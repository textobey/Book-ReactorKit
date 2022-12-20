//
//  NewBookView.swift
//  Book-ReactorKit
//
//  Created by 이서준 on 2022/12/01.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ReactorKit

class NewBookView: UIView {
    private let disposeBag = DisposeBag()
    
    private let refreshControl = UIRefreshControl()
    
    lazy var tableView = UITableView().then {
        $0.separatorStyle = .none
        $0.register(NewBookTableViewCell.self, forCellReuseIdentifier: NewBookTableViewCell.identifier)
        $0.refreshControl = self.refreshControl
    }
    
    lazy var loadingIndicator = UIActivityIndicatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.directionalEdges.equalToSuperview()
        }
        
        addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}

extension NewBookView {
    func bind(reactor: NewBookReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
}

extension NewBookView {
    private func bindAction(reactor: NewBookReactor) {
        tableView.rx.contentOffset.withUnretained(self)
            .filter { $0.0.tableView.isNearBottomEdge() }
            .map { _ in NewBookReactor.Action.paging }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        refreshControl.rx.controlEvent(.valueChanged)
            .withUnretained(self)
            .do(onNext: { $0.0.stopLoadingIndicator() })
            .map { _ in NewBookReactor.Action.refresh }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: NewBookReactor) {
        reactor.state
            .compactMap { $0.books }
            .bind(to: tableView.rx.items(cellIdentifier: NewBookTableViewCell.identifier, cellType: NewBookTableViewCell.self)) { row, bookItem, cell in
                cell.configureCell(by: bookItem)
                cell.bookmarkTap.map { bookItem }
                    .map { NewBookReactor.Action.bookmark($0) }.bind(to: reactor.action).disposed(by: cell.disposeBag)
            }.disposed(by: disposeBag)
        
        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)
        
        reactor.state
            .map { !$0.isLoading }
            .distinctUntilChanged()
            .bind(to: loadingIndicator.rx.isHidden)
            .disposed(by: disposeBag)
    }
}

extension NewBookView {
    private func stopLoadingIndicator() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.tableView.refreshControl?.endRefreshing()
        })
    }
}
