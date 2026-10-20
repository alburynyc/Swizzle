import SwiftUI

/// First run, four steps: Welcome, Account setup, Capture your bar, Upgrade to Premium.
struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            OnboardingNav(step: store.onboardingStep)
            ZStack {
                switch store.onboardingStep {
                case 0: WelcomeStep()
                case 1: AccountStep()
                case 2: CaptureStep()
                default: PremiumStep()
                }
            }
            .id(store.onboardingStep)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
        }
        .animation(.smooth, value: store.onboardingStep)
        .background(Color.paper)
    }
}

/// Back arrow (or step name), four progress bars, and "01 / 04".
private struct OnboardingNav: View {
    @Environment(AppStore.self) private var store
    let step: Int

    var body: some View {
        HStack {
            Group {
                if step == 0 {
                    Text("WELCOME").font(SwizzleFont.ui(11))
                } else {
                    Button {
                        store.onboardingStep = max(0, step - 1)
                    } label: {
                        Image(systemName: "arrow.left").frame(width: 40, height: 40).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, -10)
                    .accessibilityLabel("Back")
                }
            }
            .frame(width: 76, alignment: .leading)
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<4) { i in
                    Capsule().fill(i <= step ? Color.ink : Color.line).frame(width: 24, height: 3)
                }
            }
            .accessibilityHidden(true)
            Spacer()
            Text("0\(step + 1) / 04")
                .font(SwizzleFont.ui(12))
                .monospacedDigit()
                .foregroundStyle(Color.ink2)
                .frame(width: 76, alignment: .trailing)
                .accessibilityLabel("Step \(step + 1) of 4")
        }
        .frame(height: 44)
        .gutter()
    }
}

/// Shared layout: content at the top, actions pinned to the bottom.
private struct StepLayout<Top: View, Actions: View>: View {
    @ViewBuilder var top: Top
    @ViewBuilder var actions: Actions

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) { top }
                .gutter()
                .padding(.top, 16)
                .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 16) { actions }
                .gutter()
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color.paper)
        }
    }
}

private struct Intro: View {
    let eyebrow: String
    var title: String? = nil
    var lede: String? = nil
    var titleFont = SwizzleFont.display(34, relativeTo: .largeTitle)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: eyebrow)
            if let title { Text(title).font(titleFont) }
            if let lede {
                Text(lede).font(SwizzleFont.ui(16)).foregroundStyle(Color.ink2)
            }
        }
    }
}

private struct OnboardingPhoto: View {
    let name: String
    let aspect: CGFloat
    var body: some View {
        Color.field
            .aspectRatio(aspect, contentMode: .fit)
            .overlay { Image(name).resizable().scaledToFill() }
            .clipShape(.rect(cornerRadius: 20))
    }
}

// MARK: Steps

private struct WelcomeStep: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        StepLayout {
            VStack(spacing: 4) {
                Text("Swizzle").font(SwizzleFont.display(52, italic: true, relativeTo: .largeTitle))
                Text("Your bottles. Better cocktail recipes.").font(SwizzleFont.ui(13))
            }
            .frame(maxWidth: .infinity)
            OnboardingPhoto(name: "Photo-negroni", aspect: 370 / 324)
                .accessibilityLabel("Two Negronis on ice with orange peel")
            Intro(eyebrow: "Your bar. Your next favorite.",
                  lede: "Discover cocktails you’ll love, made with the bottles you already have.")
        } actions: {
            Button {
                store.nextOnboardingStep()
            } label: {
                HStack(spacing: 10) { Text("Let’s get started"); Image(systemName: "arrow.right") }
            }
            .buttonStyle(InkButtonStyle())
            Button("Already have an account? Log in") { store.onboardingStep = 2 }
                .buttonStyle(TextLinkStyle())
        }
    }
}

private struct AccountStep: View {
    @Environment(AppStore.self) private var store
    @State private var password = ""
    @State private var showPassword = false
    @FocusState private var focus: Field?

    private enum Field { case name, password }

    var body: some View {
        @Bindable var store = store
        let longEnough = password.count >= 8
        let ready = !store.name.trimmingCharacters(in: .whitespaces).isEmpty && longEnough

        StepLayout {
            VStack(alignment: .leading, spacing: 30) {
                Intro(eyebrow: "Make yourself at home", title: "What should we call you?",
                      titleFont: SwizzleFont.ui(34, relativeTo: .largeTitle))
                VStack(alignment: .leading, spacing: 22) {
                    InputField(label: "Your name") {
                        TextField("First name", text: $store.name)
                            .textContentType(.givenName)
                            .focused($focus, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focus = .password }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        InputField(label: "Create a password") {
                            Group {
                                if showPassword {
                                    TextField("8 characters or more", text: $password)
                                } else {
                                    SecureField("8 characters or more", text: $password)
                                }
                            }
                            .textContentType(.newPassword)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focus, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { if ready { store.nextOnboardingStep() } }
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye" : "eye.slash").frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                        }
                        Label(longEnough ? "At least 8 characters. Looking good." : "Use at least 8 characters.",
                              systemImage: "checkmark.circle")
                            .font(SwizzleFont.ui(12))
                            .foregroundStyle(longEnough ? Color.ink : Color.ink2)
                    }
                }
            }
        } actions: {
            Text("By continuing, you agree to our Terms of Service\nand Privacy Policy. For ages 21 and over.")
                .font(SwizzleFont.ui(11))
                .foregroundStyle(Color.ink2)
                .multilineTextAlignment(.center)
            Button {
                store.nextOnboardingStep()
            } label: {
                HStack(spacing: 10) { Text("Create account"); Image(systemName: "arrow.right") }
            }
            .buttonStyle(InkButtonStyle())
            .disabled(!ready)
            Button("Already a member? Log in") { store.onboardingStep = 2 }
                .buttonStyle(TextLinkStyle())
        }
    }
}

private struct InputField<Content: View>: View {
    let label: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(SwizzleFont.ui(14))
            HStack(spacing: 10) { content }
                .font(SwizzleFont.ui(17))
                .padding(.horizontal, 16)
                .frame(height: 58)
                .background(Color.field, in: .rect(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.line))
        }
    }
}

private struct CaptureStep: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        let n = store.bar.count
        StepLayout {
            Intro(eyebrow: "Stock your library", title: "Add your home bar.",
                  lede: "Take a picture of what you’ve got, then we’ll show you all the cocktails you can make.")
            Viewfinder()
            HStack(spacing: 28) {
                Button { store.showPhotoPicker = true } label: { Label("Upload", systemImage: "photo") }
                    .buttonStyle(PillButtonStyle(ghost: true))
                    .frame(width: 92)
                Button { store.openCamera() } label: {
                    Circle()
                        .fill(Color.ink)
                        .frame(width: 54, height: 54)
                        .padding(3)
                        .overlay(Circle().strokeBorder(Color.ink, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Take a photo")
                Color.clear.frame(width: 92, height: 1)
            }
            .frame(maxWidth: .infinity)
            .disabled(store.scanning)
        } actions: {
            Button {
                store.nextOnboardingStep()
            } label: {
                HStack(spacing: 10) {
                    Text(n > 0 ? "Continue with \(n) bottle\(n == 1 ? "" : "s")" : "Add a bottle to continue")
                    Image(systemName: "arrow.right")
                }
            }
            .buttonStyle(InkButtonStyle())
            .disabled(n == 0)
            Button("I’ll add my bottles manually") { store.showManualAdd = true }
                .buttonStyle(TextLinkStyle())
        }
    }
}

/// The example (or the person's own) shelf photo with the scan guide and a result pill.
private struct Viewfinder: View {
    @Environment(AppStore.self) private var store
    @State private var pulse = false

    var body: some View {
        Color.field
            .aspectRatio(370 / 350, contentMode: .fit)
            .overlay {
                if let photo = store.viewfinderPhoto {
                    Image(uiImage: photo).resizable().scaledToFill()
                } else {
                    Image("Photo-ginbar").resizable().scaledToFill()
                        .accessibilityLabel("Example: a gin bottle on a home bar")
                }
            }
            .overlay {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.white, lineWidth: 1.5)
                        .frame(width: geo.size.width * 0.65, height: geo.size.height * 0.59)
                        .position(x: geo.size.width / 2, y: geo.size.height * (0.18 + 0.295))
                        .opacity(store.scanning && pulse ? 0.35 : 1)
                }
            }
            .overlay(alignment: .topLeading) {
                Label("AI-powered home bar scan", systemImage: "viewfinder")
                    .font(SwizzleFont.ui(11))
                    .textCase(.uppercase)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassEffect(.regular, in: .capsule)
                    .padding(14)
            }
            .overlay(alignment: .bottom) { resultPill.padding(12) }
            .clipShape(.rect(cornerRadius: 20))
            .onChange(of: store.scanning) { _, scanning in
                pulse = false
                if scanning {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
                }
            }
    }

    private var resultPill: some View {
        let found = store.scannedInOnboarding
        let last = found.first
        let title: String, subtitle: String
        if store.scanning {
            title = "Reading labels…"
            subtitle = "Picking out every bottle in the shot"
        } else if let last {
            title = last.label + (found.count > 1 ? " + \(found.count - 1) more" : "")
            subtitle = "Label found · Tap to review your bottles"
        } else {
            title = "Line up your bottles"
            subtitle = "Labels facing out, then tap the shutter"
        }
        return Button {
            if last != nil { store.showManualAdd = true } else { store.openCamera() }
        } label: {
            HStack(spacing: 10) {
                if store.scanning {
                    ProgressView().tint(Color.ink)
                } else {
                    Image(systemName: last == nil ? "viewfinder" : "checkmark.circle").font(.system(size: 20))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(SwizzleFont.ui(15, weight: .medium))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(SwizzleFont.ui(12))
                        .foregroundStyle(Color.ink2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 57)
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        .disabled(store.scanning)
    }
}

private struct PremiumStep: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        let yearly = store.plan == .yearly
        StepLayout {
            Intro(eyebrow: "Introducing Premium", title: "Your bar, with no limits.")
            OnboardingPhoto(name: "Photo-ofwide", aspect: 370 / 142)
                .overlay(alignment: .topLeading) {
                    Label("The good stuff", systemImage: "sparkle")
                        .font(SwizzleFont.ui(11))
                        .textCase(.uppercase)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .glassEffect(.regular, in: .capsule)
                        .padding(12)
                }
                .accessibilityLabel("An Old Fashioned with an orange twist")
            VStack(alignment: .leading, spacing: 14) {
                Benefit(title: "Every recipe, at your fingertips", detail: "Explore the full cocktail collection.") {
                    GlassIcon(.martini).stroke(Color.ink, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                }
                Benefit(title: "A bar that keeps growing", detail: "Unlimited bottle scans and saved cocktails.") {
                    Image(systemName: "viewfinder")
                }
                Benefit(title: "Discover your next favorite", detail: "Personal picks and one-bottle-away ideas.") {
                    Image(systemName: "sparkle")
                }
            }
            HStack(spacing: 12) {
                PlanOption(title: "Yearly", price: "$39.99 / year", detail: "$3.33 / month · Save 44%", selected: yearly) { store.plan = .yearly }
                PlanOption(title: "Monthly", price: "$5.99 / month", detail: "Billed monthly", selected: !yearly) { store.plan = .monthly }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Billing")
        } actions: {
            Text("\(yearly ? "7 days free, then $39.99 / year." : "7 days free, then $5.99 / month.")\nAuto-renews. Cancel anytime.")
                .font(SwizzleFont.ui(12))
                .foregroundStyle(Color.ink2)
                .multilineTextAlignment(.center)
            Button("Start my 7-day free trial") { store.finishOnboarding(startTrial: true) }
                .buttonStyle(InkButtonStyle())
            Button("Not now, take me to my bar") { store.finishOnboarding(startTrial: false) }
                .buttonStyle(TextLinkStyle())
            Text("Restore purchases · Terms · Privacy")
                .font(SwizzleFont.ui(11))
                .foregroundStyle(Color.ink2)
        }
    }
}

private struct Benefit<Icon: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var icon: Icon

    var body: some View {
        HStack(spacing: 12) {
            icon
                .font(.system(size: 16))
                .frame(width: 18, height: 18)
                .frame(width: 34, height: 34)
                .background(Color.field, in: .circle)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(SwizzleFont.ui(14, weight: .medium))
                Text(detail).font(SwizzleFont.ui(12)).foregroundStyle(Color.ink2)
            }
        }
    }
}

private struct PlanOption: View {
    let title: String
    let price: String
    let detail: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title).font(SwizzleFont.ui(14, weight: .medium))
                    Spacer()
                    Circle()
                        .strokeBorder(selected ? Color.ink : Color.line, lineWidth: selected ? 5 : 1)
                        .background(Circle().fill(Color.paper))
                        .frame(width: 16, height: 16)
                }
                Text(price).font(SwizzleFont.ui(19)).lineLimit(1).minimumScaleFactor(0.8)
                Text(detail).font(SwizzleFont.ui(11)).foregroundStyle(Color.ink2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.field : Color.paper, in: .rect(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(selected ? Color.ink : Color.line, lineWidth: selected ? 1.5 : 1))
            .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
