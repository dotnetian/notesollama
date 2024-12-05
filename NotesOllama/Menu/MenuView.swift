import SwiftUI
import OllamaKit
import Combine
import AXSwift

// The menu UI at the bottom right in Notes
struct MenuView: View {
    var updatePanelPosition: (CGPoint?) -> Void
    var notesWatcher = NotesWatcher()
    
    @StateObject private var viewModel = MenuViewModel()
    @State var selectedText: String?
    @State var commands: [Command] = []

    var body: some View {
        VStack {
            HStack {
                Menu {
                    if let selectedText {
                        ForEach(Array(commands.enumerated()), id: \.offset) { index, command in
                            Button(command.name) {
                                viewModel.generate(prompt: command.prompt, text: selectedText)
                            }
                        }
                        Divider()
                    }
                    Menu {
                        Text("NotesOllama \(appVersion)")
                        Menu("Models") {
                            ForEach(viewModel.models, id: \.self) { model in
                                Toggle(model, isOn: Binding(
                                    get: { viewModel.selectedModel == model },
                                    set: { isSelected in
                                        if isSelected { viewModel.selectedModel = model }
                                    }
                                ))
                            }
                            Divider()
                            Button("Refresh models") { viewModel.refreshModels() }
                        }
                        LaunchAtLogin.Toggle("Launch at login")
                        HStack {
                            Link("Get latest version ↗", destination: URL(string: "https://smallest.app/notesollama")!)
                        }
                        Divider()
                        Button("Quit") { NSApp.terminate(nil) }
                    } label: {
                        Text("Settings")
                    }
                } label: {
                    Image(systemName: "wand.and.stars.inverse")
                }
                .disabled(viewModel.isLoading)
                .opacity(viewModel.isLoading ? 0.75 : 1)
                .frame(width: PANEL_WIDTH, height: PANEL_WIDTH)
                .labelStyle(.iconOnly)
            }.overlay {
                if (viewModel.isLoading) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                }
            }.alertHandling(viewModel: viewModel)
        }
        .onAppear {
            viewModel.refreshModels()
            
            viewModel.onGenerationEnded = {
                updatePanelPosition(nil)
            }
            
            notesWatcher.start(onSelectionChange: { text, position in
                if !viewModel.isLoading {
                    updatePanelPosition(text?.count ?? 0 > 0 ? position : nil)
                }
                self.selectedText = text
            })
           
            commands = loadCommandsFromFile()
        }
    }
    
    var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "v\(version)"
        } else {
            return ""
        }
    }
}

#Preview {
    MenuView(updatePanelPosition: { p in })
}
