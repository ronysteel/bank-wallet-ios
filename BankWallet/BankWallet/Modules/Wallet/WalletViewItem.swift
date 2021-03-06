import RxSwift

struct WalletViewItem {
    let coinValue: CoinValue
    let exchangeValue: CurrencyValue?
    let currencyValue: CurrencyValue?
    let state: AdapterState
    let rateExpired: Bool
}
