import SwiftUI

struct FoodIconSelectorView: View {
    @Binding var selection: FoodIconKind
    @State private var isGridPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FoodIconSelectorLabel(title: "Icon", symbolName: "square.grid.2x2")

            Button {
                isGridPresented = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selection.symbolName)
                        .font(.system(size: 17, weight: .medium))
                        .symbolRenderingMode(.monochrome)
                        .frame(width: 24)

                    Text(selection.title)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.primaryText)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.mutedText)
                }
                .foregroundStyle(AppTheme.primaryText)
                .padding(.horizontal, 12)
                .frame(height: AppTheme.Control.fieldHeight)
                .background(AppTheme.surfaceRaised)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: AppTheme.Radius.control,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppTheme.Radius.control,
                        style: .continuous
                    )
                    .strokeBorder(AppTheme.strongBorder, lineWidth: AppTheme.Stroke.hairline)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Food icon")
            .accessibilityValue(selection.title)
        }
        .sheet(isPresented: $isGridPresented) {
            FoodIconGridView(selection: $selection)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct FoodIconGridView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: FoodIconKind

    private static let iconKinds = FoodIconKind.allCases
    private static let columns = [
        GridItem(.adaptive(minimum: 52), spacing: 10),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Self.columns, spacing: 10) {
                    ForEach(Self.iconKinds) { iconKind in
                        FoodIconGridButton(
                            iconKind: iconKind,
                            isSelected: selection == iconKind
                        ) {
                            selection = iconKind
                            dismiss()
                        }
                    }
                }
                .padding(AppTheme.Spacing.screen)
            }
            .background(AppTheme.background)
            .navigationTitle("Food Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(AppTheme.Typography.bodyStrong)
                }
            }
        }
        .preferredColorScheme(AppTheme.preferredColorScheme)
    }
}

private struct FoodIconGridButton: View, Equatable {
    let iconKind: FoodIconKind
    let isSelected: Bool
    let action: () -> Void

    static func == (lhs: FoodIconGridButton, rhs: FoodIconGridButton) -> Bool {
        lhs.iconKind == rhs.iconKind && lhs.isSelected == rhs.isSelected
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: iconKind.symbolName)
                    .font(.system(size: 21, weight: .medium))
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(isSelected ? AppTheme.background : AppTheme.primaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isSelected ? AppTheme.primaryText : AppTheme.surfaceRaised)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppTheme.Radius.control,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: AppTheme.Radius.control,
                            style: .continuous
                        )
                        .strokeBorder(AppTheme.strongBorder, lineWidth: AppTheme.Stroke.hairline)
                    }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.background)
                        .padding(5)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(iconKind.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

private struct FoodIconSelectorLabel: View {
    let title: String
    let symbolName: String

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(AppTheme.Typography.eyebrow)
            .foregroundStyle(AppTheme.mutedText)
            .textCase(.uppercase)
            .tracking(0.8)
            .labelStyle(.titleAndIcon)
    }
}
