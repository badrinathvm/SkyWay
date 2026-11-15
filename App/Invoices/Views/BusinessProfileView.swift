import SwiftUI

/// Where the person enters the business details that invoice PDFs show as the sender.
struct BusinessProfileView: View {
  @AppStorage(BusinessProfile.Key.name) private var name = ""
  @AppStorage(BusinessProfile.Key.email) private var email = ""
  @AppStorage(BusinessProfile.Key.address) private var address = ""
  @AppStorage(BusinessProfile.Key.paymentInstructions) private var paymentInstructions = ""
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      Form {
        Section {
          TextField("Business or Your Name", text: $name)
            .textContentType(.organizationName)
          TextField("Email", text: $email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
          TextField("Address", text: $address, axis: .vertical)
            .textContentType(.fullStreetAddress)
            .lineLimit(2...4)
        } header: {
          Text("From")
        } footer: {
          Text("Shown at the top of every invoice PDF you share.")
        }

        Section {
          TextField("Like “Zelle to pay@example.com”", text: $paymentInstructions, axis: .vertical)
            .lineLimit(2...5)
        } header: {
          Text("How to Pay")
        } footer: {
          Text("Printed at the bottom of each invoice.")
        }
      }
      .navigationTitle("Business Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", systemImage: "checkmark") {
            dismiss()
          }
        }
      }
    }
  }
}
