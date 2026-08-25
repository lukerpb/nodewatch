import SwiftUI

enum EditServerFocusField {
    case name, url, port, hostGroups
}

struct EditServerView: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var config: ServerConfig
    var saveAction: (ServerConfig, Bool) -> Void
    
    @State private var draftConfig: ServerConfig
    @State private var showDiscardAlert = false
    
    @FocusState private var focusedField: EditServerFocusField?
    var initialFocus: EditServerFocusField? = nil
    
    init(config: Binding<ServerConfig>, initialFocus: EditServerFocusField? = nil, saveAction: @escaping (ServerConfig, Bool) -> Void) {
        self._config = config
        self.initialFocus = initialFocus
        self.saveAction = saveAction
        self._draftConfig = State(initialValue: config.wrappedValue)
    }
    
    var hasChanges: Bool {
        draftConfig != config
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if let error = draftConfig.lastError {
                    Section {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                
                Section(header: Text("Server Details")) {
                    TextField("Instance Name", text: $draftConfig.name)
                        .focused($focusedField, equals: .name)
                }
                
                Section(
                    header: HStack {
                        Text("Connection")
                        Spacer()
                        Link("Setup Guide", destination: URL(string: "https://github.com/lukerpb/Nodewatch/wiki/Setup-Guide")!)
                            .font(.caption)
                    }
                ) {
                    TextField("n8n Webhook URL (e.g. http://n8n.yoursite.com)", text: $draftConfig.url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .url)
                    
                    TextField("Port (Default: 5678)", text: $draftConfig.port)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .port)
                }
                
                Section(header: Text("Notifications"), footer: Text("Comma-separated list of host groups to receive alerts for.")) {
                    TextField("production, dev...", text: $draftConfig.hostGroups)
                        .focused($focusedField, equals: .hostGroups)
                }
            }
            .navigationTitle("Edit Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges {
                            showDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let needsTest = (draftConfig.url != config.url) || (draftConfig.port != config.port)
                        if needsTest { draftConfig.lastError = nil }
                        
                        saveAction(draftConfig, needsTest)
                        dismiss()
                    }
                    .bold()
                }
            }
            .interactiveDismissDisabled(hasChanges)
            .alert("Discard Changes?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) { }
            }
            .onAppear {
                draftConfig = config
                
                if let focus = initialFocus {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        focusedField = focus
                    }
                }
            }
        }
    }
}
