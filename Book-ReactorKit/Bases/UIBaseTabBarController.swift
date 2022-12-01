//
//  UIBaseTabBarController.swift
//  Book-ReactorKit
//
//  Created by 이서준 on 2022/12/01.
//

import UIKit

final class UIBaseTabBarController: UITabBarController {
    
    private var rootViewControllers: [UIViewController] {
        return [NewBookViewController(), SearchViewController()]
    }
    
    private var tabBarItems: [UITabBarItem] {
        return self.fetchTabBarItems()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.appendRootViewControllers()
        self.setupTabBarController()
    }
    
    private func setupTabBarController() {
        self.selectedIndex = 0
        self.view.backgroundColor = .white
        self.tabBar.isTranslucent = true
        self.tabBar.backgroundColor = .systemGroupedBackground
    }
    
    private func appendRootViewControllers() {
        let viewControllers = rootViewControllers.enumerated().map { index, rootViewController -> UINavigationController in
            rootViewController.view.backgroundColor = .white
            rootViewController.tabBarItem = tabBarItems[index]
            return UINavigationController(rootViewController: rootViewController)
        }
        self.viewControllers = viewControllers
    }
    
    private func fetchTabBarItems() -> [UITabBarItem] {
        return [
            UITabBarItem(title: "New", image: UIImage(systemName: "book"), tag: 0),
            UITabBarItem(tabBarSystemItem: .search, tag: 1)
        ]
    }
}
