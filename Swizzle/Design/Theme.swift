import SwiftUI

// Swizzle house style: white and black only, Apple liquid glass for chrome, and two typefaces:
// Times New Roman for display type, Helvetica Neue for everything else.

extension ShapeStyle where Self == Color {
    static var paper: Color { .white }
    static var ink: Color { Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255) }
    static var ink2: Color { Color(red: 117 / 255, green: 117 / 255, blue: 117 / 255) }
    static var ink3: Color { Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255, opacity: 0.5) }
    static var line: Color { Color(red: 217 / 255, green: 217 / 255, blue: 217 / 255) }
    static var field: Color { Color(red: 244 / 255, green: 244 / 255, blue: 243 / 255) }
}

enum SwizzleFont {
    enum Weight {
        case light, regular, medium

        var postScriptName: String {
            switch self {
            case .light: "HelveticaNeue-Light"
            case .regular: "HelveticaNeue"
            case .medium: "HelveticaNeue-Medium"
            }
        }
    }

    /// Times New Roman, for headings and cocktail names.
    static func display(_ size: CGFloat, italic: Bool = false, relativeTo style: Font.TextStyle = .title) -> Font {
        .custom(italic ? "TimesNewRomanPS-ItalicMT" : "TimesNewRomanPSMT", size: size, relativeTo: style)
    }

    /// Helvetica Neue, for interface and body text.
    static func ui(_ size: CGFloat, weight: Weight = .regular, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.postScriptName, size: size, relativeTo: style)
    }
}

// MARK: Buttons

/// The full-width black capsule used for each screen's main action.
struct InkButtonStyle: ButtonStyle {
    var height: CGFloat = 54
    var ghost = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SwizzleFont.ui(16, weight: .medium))
            .foregroundStyle(ghost ? Color.ink : Color.paper)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Capsule().fill(ghost ? Color.paper : Color.ink))
            .overlay { if ghost { Capsule().strokeBorder(Color.ink) } }
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.35)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// The small pill buttons on the Library scan card ("Take photo", "Upload").
struct PillButtonStyle: ButtonStyle {
    var ghost = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SwizzleFont.ui(13, weight: .medium))
            .labelStyle(PillLabelStyle())
            .foregroundStyle(ghost ? Color.ink : Color.paper)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(Capsule().fill(ghost ? Color.paper : Color.ink))
            .overlay { if ghost { Capsule().strokeBorder(Color.ink) } }
            .contentShape(Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.35)
    }
}

private struct PillLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.font(.system(size: 13, weight: .regular))
            configuration.title
        }
    }
}

/// A centered text button ("Already have an account? Log in").
struct TextLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SwizzleFont.ui(14))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: Small pieces

/// Outlined uppercase label, e.g. GIN or CLASSIC.
struct TagView: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(SwizzleFont.ui(11, relativeTo: .caption2))
            .tracking(0.2)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .overlay(Capsule().strokeBorder(lineWidth: 1))
            .fixedSize()
    }
}

/// A bottle chip that's filled when it's on the shelf.
struct ChipButton: View {
    let title: String
    var detail: String? = nil
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if let detail { Text(detail).font(SwizzleFont.ui(11)).opacity(0.6) }
            }
            .font(SwizzleFont.ui(13))
            .foregroundStyle(isOn ? Color.paper : Color.ink)
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(Capsule().fill(isOn ? Color.ink : Color.paper))
            .overlay(Capsule().strokeBorder(Color.ink))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(SwizzleFont.ui(12, relativeTo: .caption))
            .tracking(0.24)
            .foregroundStyle(Color.ink2)
    }
}

/// Eyebrow plus a large serif title, at the top of For You, Library and Search.
struct ScreenHeader: View {
    var eyebrow: String? = nil
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let eyebrow { Eyebrow(text: eyebrow) }
            Text(title).font(SwizzleFont.display(34, relativeTo: .largeTitle))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 22)
    }
}

/// Serif section title with a count on the right ("Saved   3").
struct SubHeader: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(SwizzleFont.display(24, relativeTo: .title2))
            Spacer()
            if let trailing { Text(trailing).font(SwizzleFont.ui(12)).foregroundStyle(Color.ink2) }
        }
        .padding(.top, 30)
        .padding(.bottom, 10)
    }
}

/// A gentle message for an empty list.
struct EmptyNote: View {
    var title: String? = nil
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            if let title { Text(title).font(SwizzleFont.display(26)) }
            Text(message)
                .foregroundStyle(Color.ink2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

/// Wraps chips onto as many rows as they need.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            var row = rows[rows.count - 1]
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if needed > width && !row.indices.isEmpty {
                rows.append(Row(indices: [index], width: size.width, height: size.height))
                continue
            }
            row.indices.append(index)
            row.width = needed
            row.height = max(row.height, size.height)
            rows[rows.count - 1] = row
        }
        return rows.filter { !$0.indices.isEmpty }
    }
}

extension View {
    /// The standard 16-point side margin.
    func gutter() -> some View { padding(.horizontal, 16) }
}
