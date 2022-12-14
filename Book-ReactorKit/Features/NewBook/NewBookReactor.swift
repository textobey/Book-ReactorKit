//
//  NewBookReactor.swift
//  Book-ReactorKit
//
//  Created by 이서준 on 2022/12/01.
//

import RxSwift
import RxCocoa
import SnapKit
import ReactorKit
import UserNotifications

class NewBookReactor: Reactor {
    fileprivate var allBooks: [[BookItem]] = []
    
    enum Action {
        case refresh
        case paging
    }
    
    enum Mutation {
        case setBooks([BookItem])
        case pagingBooks
        case printBook([AnyHashable: Any])
    }
    
    struct State {
        var books: [BookItem] = []
    }
    
    let initialState = State()
    
    init() {
        requestNotificationAuthorization()
        sendNotification(seconds: 5)
    }
}

extension NewBookReactor {
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .refresh:
            return fetchBookItemsResult().flatMap { bookItems -> Observable<Mutation> in
                return Observable.just(.setBooks(bookItems))
            }
        case .paging:
            guard allBooks.count > 0 else { return .empty() }
            return Observable.just(.pagingBooks)
        }
    }
}

extension NewBookReactor {
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
        case .setBooks(let bookItems):
            let slicedBookImtes = sliceBookItems(bookItems)
            allBooks = slicedBookImtes
            newState.books = slicedBookImtes.first ?? []
            allBooks.removeFirst()
            print("남은 책 목록", allBooks.count)
        case .pagingBooks:
            if let nextBooks = allBooks.first {
                newState.books.append(contentsOf: nextBooks)
                allBooks.removeFirst()
                print("남은 책 목록", allBooks.count)
            } else {
                print("마지막 페이지 입니다.")
            }
        case .printBook(let book):
            print(book)
        }
        return newState
    }
}

extension NewBookReactor {
    func transform(mutation: Observable<Mutation>) -> Observable<Mutation> {
        let eventMutation = NotificationService.shared.event.flatMap { event -> Observable<Mutation> in
            switch event {
            case .didReceive(let dictionary):
                print("didReceive")
                return .just(.printBook(dictionary))
            case .willPresent:
                print("willPresent")
                return .empty()
            case .error:
                print("Error")
                return .empty()
            }
        }
        return Observable.merge(mutation, eventMutation)
    }
}

private extension NewBookReactor {
    func fetchBookItemsResult() -> Observable<[BookItem]> {
        let fetchResult = NetworkService.shared.fetchBookItems()
        return Observable<[BookItem]>.create { observer in
            fetchResult.sink { result in
                switch result {
                case.success(let bookModel):
                    observer.onNext(bookModel.books ?? [])
                    observer.onCompleted()
                case .failure(let error):
                    print(error.localizedDescription)
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    private func sliceBookItems(_ bookItems: [BookItem]) -> [[BookItem]] {
        var slicedBookItems: [[BookItem]] = [[BookItem]]()
        for i in stride(from: 0, to: bookItems.count, by: 3) {
            if let split = bookItems[safe: i ..< i + 3] {
                slicedBookItems.append(Array(split))
            }
        }
        return slicedBookItems
    }
}

// MARK: - Local Notification
extension NewBookReactor {
    private func requestNotificationAuthorization() {
        let authOptions = UNAuthorizationOptions(arrayLiteral: .alert, .badge, .sound)
        
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { success, error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
    
    private func sendNotification(seconds: Double) {
        let notificationContent = UNMutableNotificationContent()
        
        notificationContent.title = "새로운 책들을 확인해보세요."
        notificationContent.body = "베스트 셀러 작가들의 신규 책들이 발간 되었어요!"
        notificationContent.userInfo = ["name":"A Swift Kickstart, 2nd Edition"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: notificationContent,
                                            trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
    }
}
