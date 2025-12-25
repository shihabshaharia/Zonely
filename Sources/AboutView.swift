import SwiftUI

// Custom GitHub Icon using SwiftUI Path
struct GitHubIcon: View {
    var size: CGFloat = 16
    var color: Color = .primary
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / 256
            
            // Main cat head/body path
            var path1 = Path()
            path1.move(to: CGPoint(x: 119.83 * scale, y: 56 * scale))
            path1.addCurve(
                to: CGPoint(x: 76 * scale, y: 32 * scale),
                control1: CGPoint(x: 107 * scale, y: 32 * scale),
                control2: CGPoint(x: 76 * scale, y: 32 * scale)
            )
            path1.addCurve(
                to: CGPoint(x: 72.51 * scale, y: 76.7 * scale),
                control1: CGPoint(x: 62 * scale, y: 32 * scale),
                control2: CGPoint(x: 58 * scale, y: 60 * scale)
            )
            path1.addCurve(
                to: CGPoint(x: 64 * scale, y: 104 * scale),
                control1: CGPoint(x: 66 * scale, y: 86 * scale),
                control2: CGPoint(x: 64 * scale, y: 94 * scale)
            )
            path1.addLine(to: CGPoint(x: 64 * scale, y: 112 * scale))
            path1.addCurve(
                to: CGPoint(x: 112 * scale, y: 160 * scale),
                control1: CGPoint(x: 64 * scale, y: 138 * scale),
                control2: CGPoint(x: 85 * scale, y: 160 * scale)
            )
            path1.addLine(to: CGPoint(x: 160 * scale, y: 160 * scale))
            path1.addCurve(
                to: CGPoint(x: 208 * scale, y: 112 * scale),
                control1: CGPoint(x: 186 * scale, y: 160 * scale),
                control2: CGPoint(x: 208 * scale, y: 138 * scale)
            )
            path1.addLine(to: CGPoint(x: 208 * scale, y: 104 * scale))
            path1.addCurve(
                to: CGPoint(x: 199.49 * scale, y: 76.7 * scale),
                control1: CGPoint(x: 208 * scale, y: 94 * scale),
                control2: CGPoint(x: 206 * scale, y: 86 * scale)
            )
            path1.addCurve(
                to: CGPoint(x: 196 * scale, y: 32 * scale),
                control1: CGPoint(x: 214 * scale, y: 60 * scale),
                control2: CGPoint(x: 210 * scale, y: 32 * scale)
            )
            path1.addCurve(
                to: CGPoint(x: 152.17 * scale, y: 56 * scale),
                control1: CGPoint(x: 196 * scale, y: 32 * scale),
                control2: CGPoint(x: 165 * scale, y: 32 * scale)
            )
            path1.closeSubpath()
            
            context.stroke(path1, with: .color(color), lineWidth: 2)
            
            // Legs path
            var path2 = Path()
            path2.move(to: CGPoint(x: 104 * scale, y: 232 * scale))
            path2.addLine(to: CGPoint(x: 104 * scale, y: 192 * scale))
            path2.addCurve(
                to: CGPoint(x: 136 * scale, y: 160 * scale),
                control1: CGPoint(x: 104 * scale, y: 174 * scale),
                control2: CGPoint(x: 118 * scale, y: 160 * scale)
            )
            path2.addCurve(
                to: CGPoint(x: 168 * scale, y: 192 * scale),
                control1: CGPoint(x: 154 * scale, y: 160 * scale),
                control2: CGPoint(x: 168 * scale, y: 174 * scale)
            )
            path2.addLine(to: CGPoint(x: 168 * scale, y: 232 * scale))
            
            context.stroke(path2, with: .color(color), lineWidth: 2)
            
            // Tail path
            var path3 = Path()
            path3.move(to: CGPoint(x: 104 * scale, y: 208 * scale))
            path3.addLine(to: CGPoint(x: 72 * scale, y: 208 * scale))
            path3.addCurve(
                to: CGPoint(x: 40 * scale, y: 176 * scale),
                control1: CGPoint(x: 54 * scale, y: 208 * scale),
                control2: CGPoint(x: 40 * scale, y: 194 * scale)
            )
            path3.addCurve(
                to: CGPoint(x: 8 * scale, y: 144 * scale),
                control1: CGPoint(x: 40 * scale, y: 158 * scale),
                control2: CGPoint(x: 26 * scale, y: 144 * scale)
            )
            
            context.stroke(path3, with: .color(color), lineWidth: 2)
        }
        .frame(width: size, height: size)
    }
}

// Custom Instagram Icon using SwiftUI Path
struct InstagramIcon: View {
    var size: CGFloat = 16
    var color: Color = .pink
    
    var body: some View {
        Canvas { context, canvasSize in
            let scale = min(canvasSize.width, canvasSize.height) / 256
            
            // Outer rounded rectangle
            let rect = CGRect(
                x: 32 * scale, y: 32 * scale,
                width: 192 * scale, height: 192 * scale
            )
            let roundedRect = Path(roundedRect: rect, cornerRadius: 48 * scale)
            context.stroke(roundedRect, with: .color(color), lineWidth: 2)
            
            // Center circle (camera lens)
            let center = CGPoint(x: 128 * scale, y: 128 * scale)
            let circlePath = Path(ellipseIn: CGRect(
                x: center.x - 40 * scale,
                y: center.y - 40 * scale,
                width: 80 * scale,
                height: 80 * scale
            ))
            context.stroke(circlePath, with: .color(color), lineWidth: 2)
            
            // Small dot (flash)
            let dotPath = Path(ellipseIn: CGRect(
                x: 180 * scale - 12 * scale,
                y: 76 * scale - 12 * scale,
                width: 24 * scale,
                height: 24 * scale
            ))
            context.fill(dotPath, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // App Icon
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title
            Text("Zonly")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            // Version
            Text("Version \(AppVersion.formatted)")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            // Credit
            Text("Built with ❤️ by Shihab Shaharia")
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.8))
            
            Spacer()
            
            // Social Links
            HStack(spacing: 24) {
                Link(destination: URL(string: "https://github.com/shihabshaharia")!) {
                    HStack(spacing: 8) {
                        GitHubIcon(size: 18, color: .primary)
                        Text("GitHub")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(8)
                }
                
                Link(destination: URL(string: "https://instagram.com/virtualshihab")!) {
                    HStack(spacing: 8) {
                        InstagramIcon(size: 18, color: .pink)
                        Text("Instagram")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.pink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [.purple.opacity(0.12), .pink.opacity(0.12), .orange.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(8)
                }
            }
            
            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
