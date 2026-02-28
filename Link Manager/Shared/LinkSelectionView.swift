import SwiftUI

struct ShareLinkSelectionView: View {
    @State var detectedURLs: [URL]
    var onSave: ([URL]) -> Void
    var onCancel: () -> Void
    
    @State private var selectedURLs: Set<URL> = []
    
    init(detectedURLs: [URL], onSave: @escaping ([URL]) -> Void, onCancel: @escaping () -> Void) {
        _detectedURLs = State(initialValue: detectedURLs)
        self.onSave = onSave
        self.onCancel = onCancel
        _selectedURLs = State(initialValue: Set(detectedURLs)) // Select all by default
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Links")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                            Text("Choose which links to save")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        Button("Cancel", action: onCancel)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(detectedURLs, id: \.self) { url in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedURLs.contains(url) {
                                            selectedURLs.remove(url)
                                        } else {
                                            selectedURLs.insert(url)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        // Icon
                                        ZStack {
                                            Color(UIColor.secondarySystemFill)
                                            Image(systemName: "link")
                                                .font(.system(size: 20))
                                                .foregroundColor(.blue)
                                        }
                                        .frame(width: 56, height: 56)
                                        .cornerRadius(12)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(url.host?.replacingOccurrences(of: "www.", with: "").capitalized ?? "Link")
                                                .font(.system(.headline, design: .rounded))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            
                                            Text(url.absoluteString)
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: selectedURLs.contains(url) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 24))
                                            .foregroundColor(selectedURLs.contains(url) ? .blue : Color(UIColor.tertiaryLabel))
                                    }
                                    .padding(12)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedURLs.contains(url) ? Color.blue : Color.primary.opacity(0.05), lineWidth: selectedURLs.contains(url) ? 2 : 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .scaleEffect(selectedURLs.contains(url) ? 0.98 : 1.0)
                            }
                        }
                        .padding()
                        .padding(.bottom, 100)
                    }
                }
                
                // Floating Action Bar
                VStack {
                    Spacer()
                    Button(action: {
                        let fitered = detectedURLs.filter { selectedURLs.contains($0) }
                        onSave(fitered)
                    }) {
                        HStack {
                            Text("Save \(selectedURLs.count) Link(s)")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedURLs.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(20)
                        .shadow(color: selectedURLs.isEmpty ? Color.clear : Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(selectedURLs.isEmpty)
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}
