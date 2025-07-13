import SwiftUI
import CoreNFC
import CoreNFCPackage

struct ContentView: View {

    @ObservedObject var nfc = NFCPackageViewModel()

    var body: some View {
        VStack {
            List {
                Text(nfc.message)
            }
            Button("Scan from Package") {
                nfc.scan()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
