import SwiftUI

struct LiquidSegmented: View {
    @Binding var selected: Int
    let options: [String]
    var tint: Color = Theme.pink
    @Namespace private var ns
    @State private var hapticTrigger: Int = 0

    var body: some View {
        fallback
            .sensoryFeedback(.selection, trigger: hapticTrigger)
    }

    private var fallback: some View {
        ZStack(alignment: .leading) {
            GeometryReader { geo in
                let width = geo.size.width / CGFloat(options.count)
                Capsule()
                    .fill(tint)
                    .frame(width: width - 4, height: geo.size.height - 4)
                    .offset(x: width * CGFloat(selected) + 2, y: 2)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selected)
            }

            HStack(spacing: 0) {
                ForEach(0..<options.count, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            selected = index
                        }
                        hapticTrigger += 1
                    } label: {
                        Text(options[index])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(selected == index ? .white : Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 42)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().stroke(Theme.pink.opacity(0.2), lineWidth: 1))
    }
}
