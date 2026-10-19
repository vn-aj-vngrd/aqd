import SwiftUI

/// The animated splash. It starts exactly where the static launch screen leaves off (same canvas, same 200-point mark), so the
/// hand-over is invisible; then the glass turns slightly toward the light while one highlight crosses it. `exiting` lifts the mark
/// forward and dissolves it so the app underneath can fade in.
struct LaunchSplash: View {
    var exiting = false
    @State private var glint: CGFloat = -1.3
    @State private var turned = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color("LaunchCanvas").ignoresSafeArea()
            Image("LaunchMark").resizable().scaledToFit().frame(width: 200, height: 200)
                .overlay {
                    GeometryReader { proxy in
                        LinearGradient(colors: [AppTheme.onMedia.opacity(0), AppTheme.onMedia.opacity(0.6), AppTheme.onMedia.opacity(0)],
                                       startPoint: .leading, endPoint: .trailing)
                            .frame(width: proxy.size.width * 0.4)
                            .rotationEffect(.degrees(22))
                            .offset(x: glint * proxy.size.width)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    }
                    // The transparent mark has the same geometry as the launch art, so the light stays on the glass.
                    .mask { Image("BrandMark").resizable().scaledToFit() }
                }
                .rotation3DEffect(.degrees(turned ? 10 : 0), axis: (x: 0.2, y: 1, z: 0), perspective: 0.45)
                .scaleEffect(exiting ? 1.14 : (turned ? 1.03 : 1))
                .blur(radius: exiting ? 12 : 0)
                .opacity(exiting ? 0 : 1)
        }
        .task {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1)) { glint = 1.3 }
            withAnimation(.easeInOut(duration: 0.55)) { turned = true }
            do { try await Task.sleep(for: .milliseconds(550)) } catch { return }
            withAnimation(.easeInOut(duration: 0.6)) { turned = false }
        }
    }
}
