import SwiftUI
import SwiftData

//TipView
//
// Opened as a sheet from Edit Bill ("Tip" row).
//18% / 20% / 25% buttons, each showing its dollar amount.
//Custom: a %/$ toggle and a text field.
//Summary: tip, tax, and the New Total.
// All math lives in TipViewModel; this View only displays and forwards input.

struct TipView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TipViewModel

    // Custom field state (what the user is typing, before the ViewModel validates it).
    @State private var customIsPercent = true
    @State private var customText = ""

    init(bill: Bill, context: ModelContext) {
        _viewModel = State(initialValue: TipViewModel(bill: bill, context: context))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Subtotal") {
                        Text(viewModel.subtotal, format: .currency(code: "USD"))
                    }
                } footer: {
                    Text("Tip is calculated on the subtotal, before tax.")
                }

                // --- Presets ---
                Section("Quick tip") {
                    HStack(spacing: 10) {
                        ForEach(viewModel.presets, id: \.self) { preset in
                            presetButton(preset)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // --- Custom ---
                Section("Custom") {
                    Picker("Enter as", selection: $customIsPercent) {
                        Text("%").tag(true)
                        Text("$").tag(false)
                    }
                    .pickerStyle(.segmented)

                    TextField(customIsPercent ? "Percent, e.g. 15" : "Dollars, e.g. 8.00",
                              text: $customText)
                        .keyboardType(.decimalPad)

                    if let error = viewModel.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                }

                // --- Summary ---
                Section {
                    LabeledContent("Tip") {
                        Text("\(viewModel.tipPercent.formatted(.number.precision(.fractionLength(0...1))))% · \(viewModel.tipAmount.formatted(.currency(code: "USD")))")
                    }
                    LabeledContent("Tax") {
                        Text(viewModel.tax, format: .currency(code: "USD"))
                    }
                    LabeledContent("New total") {
                        Text(viewModel.newTotal, format: .currency(code: "USD"))
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: customText) { _, _ in applyCustom() }
            .onChange(of: customIsPercent) { _, _ in applyCustom() }
            // Reopening: if the saved tip was typed in dollars, show it in the $ field.
            .onAppear {
                if !viewModel.tipIsPercent && viewModel.tipAmount > 0 {
                    customIsPercent = false
                    customText = "\(viewModel.tipAmount)"
                }
            }
        }
    }

    /// One preset button: "20%" with its dollar amount underneath.
    private func presetButton(_ preset: Decimal) -> some View {
        let selected = viewModel.isSelected(preset)
        return Button {
            customText = ""                  // a preset replaces any custom entry
            viewModel.setPercent(preset)
        } label: {
            VStack(spacing: 4) {
                Text("\(preset.formatted())%").font(.headline)
                Text(viewModel.amount(forPercent: preset), format: .currency(code: "USD"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color.orange.opacity(0.18) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color.orange : Color.clear, lineWidth: 1.5)
            )
        }
        // .plain makes each button tappable on its own inside a Form row.
        .buttonStyle(.plain)
    }

    //Sends the custom field to the ViewModel. An empty field changes nothing.
    private func applyCustom() {
        let trimmed = customText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard let value = Decimal(string: trimmed) else {
            viewModel.errorMessage = "Enter a number."
            return
        }
        if customIsPercent {
            viewModel.setPercent(value)
        } else {
            viewModel.setAmount(value)
        }
    }
}
