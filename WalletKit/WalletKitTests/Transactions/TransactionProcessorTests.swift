import XCTest
import Cuckoo
import RealmSwift
@testable import WalletKit

class TransactionProcessorTests: XCTestCase {
    private var mockExtractor: MockTransactionExtractor!
    private var mockLinker: MockTransactionLinker!
    private var mockLogger: MockLogger!
    private var transactionProcessor: TransactionProcessor!

    private var realm: Realm!

    override func setUp() {
        super.setUp()

        let mockWalletKit = MockWalletKit()

        mockExtractor = mockWalletKit.mockTransactionExtractor
        mockLinker = mockWalletKit.mockTransactionLinker
        mockLogger = mockWalletKit.mockLogger

        realm = mockWalletKit.mockRealm

        stub(mockLinker) { mock in
            when(mock.handle(transaction: any(), realm: any())).thenDoNothing()
        }
        stub(mockExtractor) { mock in
            when(mock.extract(transaction: any())).thenDoNothing()
        }
        stub(mockLogger) { mock in
            when(mock.log(tag: any(), message: any())).thenDoNothing()
        }

        transactionProcessor = TransactionProcessor(realmFactory: mockWalletKit.mockRealmFactory, extractor: mockExtractor, linker: mockLinker, logger: mockLogger, queue: DispatchQueue.main)
    }

    override func tearDown() {
        mockExtractor = nil
        mockLogger = nil
        mockLinker = nil
        transactionProcessor = nil

        realm = nil

        super.tearDown()
    }

    func testTransactionProcessing() {
        let transaction = TestData.p2pkhTransaction
        let processedTransaction = TestData.p2shTransaction
        processedTransaction.processed = true

        try! realm.write {
            realm.add(transaction)
            realm.add(processedTransaction)
        }

        transactionProcessor.enqueueRun()

        waitForMainQueue()

        verify(mockExtractor).extract(transaction: equal(to: transaction))
        verify(mockExtractor, never()).extract(transaction: equal(to: processedTransaction))

        verify(mockLinker).handle(transaction: equal(to: transaction), realm: equal(to: realm))
        verify(mockLinker, never()).handle(transaction: equal(to: processedTransaction), realm: equal(to: realm))

        XCTAssertEqual(transaction.processed, true)
    }

    func testProcessingError() {
        let error = TransactionExtractor.ExtractionError.invalid
        let transaction = TestData.p2pkhTransaction

        try! realm.write {
            realm.add(transaction)
        }

        stub(mockExtractor) { mock in
            when(mock.extract(transaction: any())).thenThrow(error)
        }

        transactionProcessor.enqueueRun()

        waitForMainQueue()

        verify(mockLogger).log(tag: "Transaction Processor Error", message: "\(error)")
    }

}
