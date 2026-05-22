import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lensManager: LensManager
    
    @State private var selectedPlan: Plan = .yearly
    @State private var isLoading = false
    @State private var showSuccess = false
    
    enum Plan {
        case monthly
        case yearly
        
        var title: String {
            switch self {
            case .monthly: return "Monthly Plan"
            case .yearly: return "Annual Plan"
            }
        }
        
        var price: String {
            switch self {
            case .monthly: return "$1.99 / mo"
            case .yearly: return "$14.99 / yr"
            }
        }
        
        var description: String {
            switch self {
            case .monthly: return "Cancel anytime. Billed monthly."
            case .yearly: return "Save 37%. Just $1.25 / month, billed annually."
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.2),
                    Color(red: 0.03, green: 0.05, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header / Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title / Hero
                        VStack(spacing: 8) {
                            Text("👑")
                                .font(.system(size: 50))
                            
                            Text("Lens Tracker Pro")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Unlock the full potential of your eyes")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        
                        // Features list
                        VStack(spacing: 16) {
                            FeatureRow(
                                icon: "drop.fill",
                                iconColor: .cyan,
                                title: "Accessory Tracking",
                                description: "Track durations and inventory for Eye Drops, Cleaners, and Lens Cases."
                            )
                            
                            FeatureRow(
                                icon: "paintpalette.fill",
                                iconColor: .pink,
                                title: "Custom Color Themes",
                                description: "Personalize your app layout with over 10 gorgeous gradient themes."
                            )
                            
                            FeatureRow(
                                icon: "square.grid.2x2.fill",
                                iconColor: .purple,
                                title: "Home Screen Widgets",
                                description: "Monitor active lenses and accessory days remaining right on your home screen."
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Plans Selection
                        VStack(spacing: 14) {
                            PlanSelectorRow(
                                plan: .yearly,
                                isSelected: selectedPlan == .yearly,
                                tag: "BEST VALUE",
                                action: { selectedPlan = .yearly }
                            )
                            
                            PlanSelectorRow(
                                plan: .monthly,
                                isSelected: selectedPlan == .monthly,
                                action: { selectedPlan = .monthly }
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 20)
                    }
                }
                
                // Purchase Section at bottom
                VStack(spacing: 14) {
                    if showSuccess {
                        // Success message animation
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Premium Activated Successfully!")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: handleSubscribe) {
                        ZStack {
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(16)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(showSuccess ? "Success!" : "Start Pro Mode")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 56)
                    }
                    .disabled(isLoading || showSuccess)
                    .padding(.horizontal, 24)
                    
                    // Footer Links
                    HStack(spacing: 24) {
                        Button("Restore Purchases") {
                            triggerSuccessState()
                        }
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.3))
                        
                        Link(destination: URL(string: "https://example.com/terms")!) {
                            Text("Terms of Use")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
                .background(Color(red: 0.05, green: 0.08, blue: 0.14))
            }
        }
    }
    
    private func handleSubscribe() {
        isLoading = true
        
        // Simulate App Store delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            triggerSuccessState()
        }
    }
    
    private func triggerSuccessState() {
        isLoading = false
        withAnimation(.spring()) {
            showSuccess = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Enable Premium Mode in manager
        lensManager.isSubscribed = true
        
        // Dismiss sheet automatically after showing checkmark
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// Subviews
struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

struct PlanSelectorRow: View {
    let plan: SubscriptionView.Plan
    let isSelected: Bool
    var tag: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Radio button indicator
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let tagText = tag {
                            Text(tagText)
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(plan.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(plan.price)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: 2)
                    .background(Color.white.opacity(isSelected ? 0.05 : 0.02))
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}
