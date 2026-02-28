import SwiftUI

struct AddLinkView: View {
    @Environment(\.presentationMode) var presentationMode
    var viewModel: LinkViewModel
    var targetGroup: LinkGroup?
    var groupViewModel: LinkGroupViewModel?

    // Callback for success animation
    var onSuccess: (() -> Void)? = nil

    @State private var textInput: String = ""
    @State private var detectedURLs: [URL] = []
    @State private var showSelectionView = false
    @State private var showError = false
    @State private var showSuccessMessage = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 24) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Link")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Text(
                            "Paste a URL or text containing links below. We'll automatically detect and organize them for you."
                        )
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Input Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "link")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                            Text("URL or Text")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)

                            Spacer()

                            // Paste Button
                            if UIPasteboard.general.hasStrings {
                                Button(action: {
                                    if let string = UIPasteboard.general.string {
                                        withAnimation {
                                            textInput = string
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.clipboard")
                                        Text("Paste")
                                    }
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 4)

                        ZStack(alignment: .topLeading) {
                            if textInput.isEmpty {
                                Text("https://example.com...")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(Color(uiColor: UIColor.tertiaryLabel))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                            }

                            TextEditor(text: $textInput)
                                .font(.system(.body, design: .rounded))
                                .frame(height: 150)
                                .padding(4)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                // Transparent background for TextEditor to show our background
                                .scrollContentBackground(.hidden)
                        }
                        .padding(8)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Action Button
                    Button(action: processInput) {
                        HStack {
                            Text("Add")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(textInput.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(
                            color: textInput.isEmpty ? Color.clear : Color.blue.opacity(0.3),
                            radius: 8, x: 0, y: 4)
                    }
                    .disabled(textInput.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                // Success Overlay
                if showSuccessMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            Text("Link Added Successfully")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(2)
                }

                // Selection View Overlay
                if showSelectionView && !detectedURLs.isEmpty {
                    Color.black.opacity(0.4).ignoresSafeArea()

                    ShareLinkSelectionView(
                        detectedURLs: detectedURLs,
                        onSave: { selected in
                            saveLinks(selected)
                        },
                        onCancel: {
                            showSelectionView = false
                        }
                    )
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .padding()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(3)
                }
            }
            .navigationBarHidden(true)  // Using custom header
            .alert("No Links Found", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func processInput() {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(
            in: textInput, options: [], range: NSRange(location: 0, length: textInput.utf16.count))

        var foundURLs: [URL] = []

        matches?.forEach { match in
            if let url = match.url {
                foundURLs.append(url)
            }
        }

        if foundURLs.isEmpty {
            errorMessage = "Please verify the text contains valid web links."
            showError = true
            return
        }

        // Filter unique URLs
        let uniqueURLs = Array(Set(foundURLs))

        if uniqueURLs.count == 1, let singleURL = uniqueURLs.first {
            // Single Link - Add Directly
            // Use remaining text as description if it's substantial and not just the link itself
            let cleanText = textInput.replacingOccurrences(of: singleURL.absoluteString, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let subtitle = cleanText.isEmpty ? nil : cleanText

            Task {
                let newContent = await viewModel.addLink(url: singleURL, subtitle: subtitle)

                if let group = targetGroup, let groupVM = groupViewModel {
                    groupVM.addLinksToGroup(group: group, links: [newContent])
                }

                // onSuccess?() // Disable home view animation since we are staying here
                handleLocalSuccess()
            }
        } else {
            // Multiple Links - Show Selection
            detectedURLs = uniqueURLs
            showSelectionView = true
        }
    }

    private func saveLinks(_ urls: [URL]) {
        showSelectionView = false
        Task {
            for url in urls {
                let newContent = await viewModel.addLink(url: url)
                if let group = targetGroup, let groupVM = groupViewModel {
                    groupVM.addLinksToGroup(group: group, links: [newContent])
                }
            }
            // Show success then dismiss everything
            hideKeyboard()
            withAnimation {
                showSuccessMessage = true
                textInput = ""
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func handleLocalSuccess() {
        hideKeyboard()
        withAnimation {
            textInput = ""  // Clear input
            showSuccessMessage = true
        }

        // Hide success message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showSuccessMessage = false
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
