import CoreData
import Kingfisher
import SwiftUI

struct LinkDetailView: View {
    @ObservedObject var content: Content
    var viewModel: LinkViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingFullImage = false

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // 1. Immersive Header Image
                    Button(action: {
                        if content.thumbIconUrl != nil {
                            showingFullImage = true
                        }
                    }) {
                        ZStack(alignment: .bottomLeading) {
                            if let thumbUrl = content.thumbIconUrl, let url = URL(string: thumbUrl)
                            {
                                GeometryReader { geometry in
                                    ZStack {
                                        // 1. Blurred Background (Fill)
                                        KFImage(url)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(
                                                width: geometry.size.width,
                                                height: geometry.size.height
                                            )
                                            .clipped()
                                            .blur(radius: 20)
                                            .overlay(Color.black.opacity(0.3))

                                        // 2. Main Image (Fit)
                                        KFImage(url)
                                            .resizable()
                                            .placeholder {
                                                Image(systemName: "photo")
                                                    .foregroundColor(.secondary)
                                            }
                                            .fade(duration: 0.25)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 350)
                                            .cornerRadius(12)
                                    }
                                }
                            } else {
                                Rectangle().fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.blue.opacity(0.3), Color.purple.opacity(0.3),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 350)
                                .overlay(
                                    Image(systemName: "link.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.5))
                                )
                            }

                            // Gradient Overlay
                            LinearGradient(
                                gradient: Gradient(colors: [.black.opacity(0.6), .clear]),
                                startPoint: .bottom, endPoint: .top
                            )
                            .frame(height: 100)
                        }
                        .frame(height: 350)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // 2. Content Body
                    VStack(alignment: .leading, spacing: 20) {

                        // Title
                        Text(content.title ?? "Untitled Link")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)  // Ensure full width usage
                            .fixedSize(horizontal: false, vertical: true)  // Ensure wrapping

                        // Metadata Row (Date & Domain)
                        HStack(spacing: 16) {
                            if let domain = content.domainName {
                                HStack(spacing: 6) {
                                    if let iconUrl = content.domainIconUrl,
                                        let url = URL(string: iconUrl)
                                    {
                                        // Replaced AsyncImage with KFImage
                                        KFImage(url)
                                            .resizable()
                                            .placeholder {
                                                Image(systemName: "globe")
                                                    .foregroundColor(.secondary)
                                            }
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "globe")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(domain)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                            }

                            if let date = content.creationDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.caption)
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                        }

                        Divider()

                        // URL Display (Clickable)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LINK URL")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)

                            Button(action: {
                                openLink()
                            }) {
                                HStack {
                                    Text(content.savedLinkUrl ?? "No URL")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.blue)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }

                        // Description / Subtitle Logic
                        if let subtitle = content.subtitle, !subtitle.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DESCRIPTION")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)

                                Text(subtitle)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                    .background(Color(UIColor.systemGroupedBackground))
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                    .offset(y: -20)
                }
            }
            .edgesIgnoringSafeArea(.top)

            // Floating Action Bar (Capsule)
            // Floating Action Bar (Capsule Buttons)
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    // Edit Button
                    Button(action: { showingEditSheet = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }

                    // Share Button
                    Button(action: {
                        if let urlString = content.savedLinkUrl, let url = URL(string: urlString) {
                            shareLink(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }

                    Spacer()

                    // Open Button (Primary)
                    Button(action: openLink) {
                        HStack(spacing: 6) {
                            Text("Open")
                            Image(systemName: "safari")
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(false)  // Show nav bar for back button, but transparent?
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.toggleFavorite(content)
                    }) {
                        Image(systemName: content.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(content.isFavorite ? .red : .white)
                            .font(.title2)
                            .shadow(radius: 2)
                            .scaleEffect(content.isFavorite ? 1.1 : 1.0)
                            .animation(
                                .spring(response: 0.3, dampingFraction: 0.5),
                                value: content.isFavorite)
                    }

                    Menu {
                        Button(action: {
                            if let urlString = content.savedLinkUrl,
                                let url = URL(string: urlString)
                            {
                                shareLink(url)
                            }
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button(
                            role: .destructive,
                            action: {
                                showingDeleteAlert = true
                            }
                        ) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.white)  // Visible on image header?
                            .font(.title2)
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditLinkSheet(content: content, viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            ZStack {
                Color.black.ignoresSafeArea()
                if let thumbUrl = content.thumbIconUrl, let url = URL(string: thumbUrl) {
                    // Replaced AsyncImage with KFImage
                    KFImage(url)
                        .resizable()
                        .placeholder {
                            Color.gray
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)  // This frame seems small for a full screen cover, but following instruction
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Added to ensure it fills the screen
                }

                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showingFullImage = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Link"),
                message: Text("Are you sure you want to delete this link?"),
                primaryButton: .destructive(Text("Delete")) {
                    viewModel.deleteLink(content)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func openLink() {
        if let urlString = content.savedLinkUrl, let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func shareLink(_ url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else { return }

        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }

        topVC.present(activityVC, animated: true, completion: nil)
    }
}

// Minimal Edit Sheet
struct EditLinkSheet: View {
    @ObservedObject var content: Content
    var viewModel: LinkViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var editedTitle: String = ""
    @State private var editedURL: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $editedTitle)
                    TextField("URL", text: $editedURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Link")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    Task {
                        await viewModel.updateLink(
                            content, title: editedTitle, urlString: editedURL)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
            .onAppear {
                editedTitle = content.title ?? ""
                editedURL = content.savedLinkUrl ?? ""
            }
        }
    }
}

// Helper for Visual Blur and Rounded Corners
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
