//
//  BookItem.swift
//  Book-ReactorKit
//
//  Created by 이서준 on 2022/12/01.
//

import Foundation

struct BookItem: Decodable {
    var title: String?
    var subtitle: String?
    var isbn13: String?
    var price: String?
    var image: String?
    var url: String?
}