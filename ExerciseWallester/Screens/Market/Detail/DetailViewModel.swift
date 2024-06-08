//
//  DetailViewModel.swift
//  CoinGekoWallester
//
//  Created by Denis Sinitsa on 29.05.2024.
//

import Combine
import SwiftUI

class DetailViewModel: ObservableObject, DetailCryptoCurrencyProtocol, TimerProtocol {
    @Published var coinDetailData: CoinDetailModel?
    @Published var coinHistoricalChartData: CoinHistoricalChartDataModel?

    @Published var isLoading = true
    @Published var id: String
    @Published var name: String
    @Published var currencyCode: String
    @Published var coinSymbol: String
    @Published var currencySymbol: String
    @Published var timeframe: String = "1"

    private var cancellables = Set<AnyCancellable>()
    private var currencyService = CurrencyService.shared
    private var timer: AnyCancellable?
    var localeService = LocaleService.shared

    init(id: String, name: String, currencyCode: String, currencySymbol: String, coinSymbol: String) {
        self.id = id
        self.name = name
        self.currencyCode = currencyCode
        self.currencySymbol = currencySymbol
        self.coinSymbol = coinSymbol

        checkCachedData()
        loadInitialData()
        initializeDataFetchTimer()
    }

    func checkCachedData() {
        CoinDataService.shared.fetchCryptoCurrencyDetails(id: id, forceUpdate: false)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { coin in
                self.coinDetailData = coin
                self.checkLoadingState()
            })
            .store(in: &cancellables)

        CoinDataService.shared.fetchCryptoCurrencyHistoricalChartData(
            id: id,
            currency: currencyCode,
            timeframe: timeframe,
            forceUpdate: false
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in }, receiveValue: { data in
            let prices = data.prices.map { $0[1] }
            self.coinHistoricalChartData = CoinHistoricalChartDataModel(prices: prices.map { [$0] })
            self.checkLoadingState()
        })
        .store(in: &cancellables)
    }

    func loadInitialData() {
        fetchCryptoData(id: id, currencyCode: currencyCode)
        fetchCryptoHistoricalChartData(id: id, currencyCode: currencyCode, timeframe: timeframe)
    }

    func initializeDataFetchTimer() {
        timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.fetchCryptoData(id: self.id, currencyCode: self.currencyCode)
                self.fetchCryptoHistoricalChartData(
                    id: self.id,
                    currencyCode: self.currencyCode,
                    timeframe: self.timeframe
                )
            }
    }

    func fetchCryptoData(id: String, currencyCode: String) {
        CoinDataService.shared.fetchCryptoCurrencyDetails(id: id, forceUpdate: true)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    print("Error fetching details, trying cached data: \(error)")
                    self.fetchCachedCryptoData(id: id, currencyCode: currencyCode)

                case .finished:
                    print("Finished fetching crypto details")
                }
            }, receiveValue: { coin in
                self.coinDetailData = coin
                self.checkLoadingState()
            })
            .store(in: &cancellables)
    }

    func fetchCachedCryptoData(id: String, currencyCode: String) {
        CoinDataService.shared.fetchCryptoCurrencyDetails(id: id, forceUpdate: false)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case let .failure(error):
                    print("Failed to fetch cached details: \(error)")

                case .finished:
                    print("Finished fetching cached crypto details")
                }
            }, receiveValue: { coin in
                self.coinDetailData = coin
                self.checkLoadingState()
            })
            .store(in: &cancellables)
    }

    func fetchCryptoHistoricalChartData(id: String, currencyCode: String, timeframe: String) {
        CoinDataService.shared.fetchCryptoCurrencyHistoricalChartData(
            id: id,
            currency: currencyCode,
            timeframe: timeframe,
            forceUpdate: true
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                print("Error fetching data: \(error)")
                self.fetchCachedHistoricalChartData(id: id, currencyCode: currencyCode, timeframe: timeframe)

            case .finished:
                print("Finished fetching crypto historical chart data")
            }
        }, receiveValue: { [weak self] data in
            let prices = data.prices.map { $0[1] }
            self?.coinHistoricalChartData = CoinHistoricalChartDataModel(prices: prices.map { [$0] })
            self?.checkLoadingState()
        })
        .store(in: &cancellables)
    }

    func fetchCachedHistoricalChartData(id: String, currencyCode: String, timeframe: String) {
        CoinDataService.shared.fetchCryptoCurrencyHistoricalChartData(
            id: id,
            currency: currencyCode,
            timeframe: timeframe,
            forceUpdate: false
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case let .failure(error):
                print("Failed to fetch cached historical chart data: \(error)")

            case .finished:
                print("Finished fetching cached crypto historical chart data")
            }
        }, receiveValue: { data in
            let prices = data.prices.map { $0[1] }
            self.coinHistoricalChartData = CoinHistoricalChartDataModel(prices: prices.map { [$0] })
            self.checkLoadingState()
        })
        .store(in: &cancellables)
    }

    func checkLoadingState() {
        if coinDetailData != nil && coinHistoricalChartData != nil {
            isLoading = false
        }
    }
}
