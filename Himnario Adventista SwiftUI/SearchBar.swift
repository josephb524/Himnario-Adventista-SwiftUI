//
//  SearchBar.swift
//  Concordancia Biblica
//
//  Created by Jose Pimentel on 6/22/24.
//

import SwiftUI

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    var onClear: () -> Void

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        var onCommit: () -> Void
        var onClear: () -> Void
        weak var searchBarInstance: UISearchBar?

        init(text: Binding<String>, onCommit: @escaping () -> Void, onClear: @escaping () -> Void) {
            _text = text
            self.onCommit = onCommit
            self.onClear = onClear
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
            if searchText.isEmpty {
                onClear()
            }
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            onCommit()
        }

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }

        @objc func doneButtonTapped() {
            // Dismiss the keyboard
            searchBarInstance?.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onCommit: onCommit, onClear: onClear)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        context.coordinator.searchBarInstance = searchBar // Assign the UISearchBar instance
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Buscar palabra"

        // Create the toolbar with the Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(context.coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]

        // Find the UITextField inside UISearchBar and set its inputAccessoryView
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.inputAccessoryView = toolbar
        }

        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}
