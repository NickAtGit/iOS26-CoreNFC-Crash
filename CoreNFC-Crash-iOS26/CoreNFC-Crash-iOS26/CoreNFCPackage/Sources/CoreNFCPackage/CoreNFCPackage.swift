import CoreNFC

@MainActor
public class NFCPackageViewModel: ObservableObject, @MainActor NFCDelegate {

    public init() {}

    @Published public var message = ""
    let nfc = NFCPackage()

    public func scan() {
        nfc.delegate = self
        nfc.newTagReaderSession()
    }

    public func didConnectTag(identifier: Data?) {
        print("🏷 didConnectTag")
        Task { @MainActor in
            do {
                let nfcMessage = try await nfc.readNDEF()
                for (index, record) in nfcMessage.records.enumerated() {
                    let recordTitle = "Record \(index + 1)"

                    var content = ""
                    var type = ""

                    switch record.typeNameFormat {
                    case .nfcWellKnown:
                        if record.type == Data([0x54]) { // Text record
                            content = String(data: record.payload.dropFirst(3), encoding: .utf8) ?? "Invalid text"
                            type = "Text"
                        } else if record.type == Data([0x55]) { // URI record
                            content = String(data: record.payload.dropFirst(), encoding: .utf8) ?? "Invalid URI"
                            type = "URI"
                        } else {
                            content = record.type.hexDescription
                            type = "Well-known"
                        }
                    case .media:
                        content = String(data: record.payload, encoding: .utf8) ?? "Binary data"
                        type = "Media"
                    case .absoluteURI:
                        content = String(data: record.type, encoding: .utf8) ?? "Unknown URI"
                        type = "Absolute URI"
                    case .nfcExternal:
                        content = String(data: record.payload, encoding: .utf8) ?? "External data"
                        type = "External"
                    case .empty:
                        content = "No content"
                        type = "Empty"
                    case .unchanged:
                        content = "Unchanged record"
                        type = "Unchanged"
                    case .unknown:
                        content = "Unknown content"
                        type = "Unknown"
                    @unknown default:
                        content = "Unknown content"
                        type = "Unknown"
                    }
                    print(recordTitle)
                    print(type)
                    print(content)
                    self.message = content
                }
            } catch {
                message = "Error: " + String(describing: error)
            }
        }
    }
    
    public func didConnectTag(tag: NFCTag, identifier: Data?) {
        print("🏷 didConnectTag")
        Task { @MainActor in
            do {
                let nfcMessage = try await nfc.readNDEF()
                for (index, record) in nfcMessage.records.enumerated() {
                    let recordTitle = "Record \(index + 1)"

                    var content = ""
                    var type = ""

                    switch record.typeNameFormat {
                    case .nfcWellKnown:
                        if record.type == Data([0x54]) { // Text record
                            content = String(data: record.payload.dropFirst(3), encoding: .utf8) ?? "Invalid text"
                            type = "Text"
                        } else if record.type == Data([0x55]) { // URI record
                            content = String(data: record.payload.dropFirst(), encoding: .utf8) ?? "Invalid URI"
                            type = "URI"
                        } else {
                            content = record.type.hexDescription
                            type = "Well-known"
                        }
                    case .media:
                        content = String(data: record.payload, encoding: .utf8) ?? "Binary data"
                        type = "Media"
                    case .absoluteURI:
                        content = String(data: record.type, encoding: .utf8) ?? "Unknown URI"
                        type = "Absolute URI"
                    case .nfcExternal:
                        content = String(data: record.payload, encoding: .utf8) ?? "External data"
                        type = "External"
                    case .empty:
                        content = "No content"
                        type = "Empty"
                    case .unchanged:
                        content = "Unchanged record"
                        type = "Unchanged"
                    case .unknown:
                        content = "Unknown content"
                        type = "Unknown"
                    @unknown default:
                        content = "Unknown content"
                        type = "Unknown"
                    }
                    print(recordTitle)
                    print(type)
                    print(content)
                    self.message = content
                }
            } catch {
                message = "Error: " + String(describing: error)
            }
        }
    }
    
    public func didInvalidate(with error: any Error) {

    }
}

public protocol NFCDelegate: AnyObject {
    func didConnectTag(identifier: Data?)
    func didConnectTag(tag: NFCTag, identifier: Data?)
    func didInvalidate(with error: Error)
}

@MainActor
public class NFCPackage: NSObject, @MainActor NFCTagReaderSessionDelegate {

    private var tagSession: NFCTagReaderSession?
    private var ndefSession: NFCNDEFReaderSession?
    private var originalTag: NFCTag?
    private var nfcNDEFTag: NFCNDEFTag?
    private var tagType: NFCTagType = .none
    public var stringMessage: String = ""

    weak var delegate: NFCDelegate?

    var message: NFCNDEFMessage?
    var isSessionActive = false

    public func newTagReaderSession() {
        if NFCTagReaderSession.readingAvailable {
            print("NFC Tag reading is available.")
        } else {
            print("NFC Tag reading is NOT available.")
        }

        tagSession = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693, .iso18092],
            delegate: self,
            queue: nil
        )
        tagSession?.alertMessage = "Scan"
        tagSession?.begin()
    }

    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        print("NFCTagReaderSession did become active. isReady: \(session.isReady)")
        Task { @MainActor in
            self.isSessionActive = session.isReady
        }
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("NFCTagReaderSession didInvalidateWithError: \(String(describing: error))")
        Task { @MainActor in
            self.isSessionActive = session.isReady
        }
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if let firstTag = tags.first {
            originalTag = firstTag
            switch firstTag {
            case let .miFare(tag):
                print("🏷 Did detect tag: MiFare")
                nfcNDEFTag = tag
                tagType = .type2

                Task { @MainActor in
                    print("🏷 delegating")
                    self.delegate?.didConnectTag(tag: firstTag, identifier: tag.identifier)
                }

            case let .feliCa(tag):
                print("🏷 Did detect tag: FeliCa")
                nfcNDEFTag = tag
                tagType = .type3
            case let .iso7816(tag):
                print("🏷 Did detect tag: ISO7816")
                nfcNDEFTag = tag
                tagType = .type4
            case let .iso15693(tag):
                print("🏷 Did detect tag: ISO15693")
                nfcNDEFTag = tag
                tagType = .type5
            @unknown default:
                // Failed to connect tag
                nfcNDEFTag = nil
            }
        } else {
            originalTag = nil
            nfcNDEFTag = nil
        }
    }

    func readNDEF() async throws -> NFCNDEFMessage {
        guard let originalTag else { throw NFCError.tagNotFound }
        do {
            try await tagSession?.connect(to: originalTag)
            guard let message = try await nfcNDEFTag?.readNDEF() else {
                throw NFCError.ndefReadFailed
            }
            return message

        } catch let error as NFCReaderError {
            if error.code == .readerTransceiveErrorTagResponseError {
                throw NFCError.ndefNotFormatted
            } else {
                throw NFCError.unknown
            }
        } catch {
            throw NFCError.unknown
        }
    }

#warning("HERE: The sole presence of this methods leads to crashes! Xcode Version 26.0 beta 3 (17A5276g)")

//    func compatibilityReadTag() async throws -> NFCNDEFMessage {
//        if let nfcNDEFTag = nfcNDEFTag {
//            try await ndefSession?.connect(to: nfcNDEFTag)
//            let message = try await nfcNDEFTag.readNDEF()
//            ndefSession?.invalidate()
//            return message
//        } else {
//            throw NFCError.tagNotFound
//        }
//    }
}

public enum NFCTagType: UInt8 {
    case none
    case type2 //MiFare
    case type3 //FeliCa
    case type4 //iso7816
    case type5 //iso15693
}

public enum NFCError: Error {
    case unknown
    case tagNotFound
    case ndefReadFailed
    case ndefNotFormatted
}

public extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x : ", $1)}.dropLast().dropLast().uppercased()
    }
}
