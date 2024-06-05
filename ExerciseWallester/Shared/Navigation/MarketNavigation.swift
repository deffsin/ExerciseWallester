//
//  MarketNavigation.swift
//  TestExerciseWallester
//
//  Created by Denis Sinitsa on 02.06.2024.
//

import SwiftUI

enum MarketNavigation: Hashable, Identifiable, View {
    var id: Self { self }
    
    case detail(id: String, name: String, currencyCode: String, currencySymbol: String, coinSymbol: String)
    
    var body: some View {
        switch self {
        case .detail(let id, let name, let currencyCode, let currencySymbol, let coinSymbol):
            DetailView(viewModel: DetailViewModel(id: id, name: name, currencyCode: currencyCode, currencySymbol: currencySymbol, coinSymbol: coinSymbol))
        }
    }
}
