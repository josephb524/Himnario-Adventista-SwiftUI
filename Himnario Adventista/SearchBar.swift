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
            } else {
                onCommit()
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
            searchBarInstance?.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, onCommit: onCommit, onClear: onClear)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar(frame: .zero)
        context.coordinator.searchBarInstance = searchBar
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Buscar Himno"
        
        // Modern styling - pill-shaped
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()
        searchBar.layer.cornerRadius = 25
        searchBar.clipsToBounds = true
        
        // Configure text field with pill shape and search icon
        if let textField = searchBar.searchTextField as? UITextField {
            textField.backgroundColor = .systemBackground
            textField.font = UIFont.systemFont(ofSize: 17)
            textField.layer.cornerRadius = 25
            textField.clipsToBounds = true
            
            // Add magnifying glass icon on the left
            let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
            searchIcon.tintColor = UIColor.systemGray
            searchIcon.contentMode = .scaleAspectFit
            searchIcon.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
            
            let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
            leftPaddingView.addSubview(searchIcon)
            searchIcon.center = leftPaddingView.center
            
            textField.leftView = leftPaddingView
            textField.leftViewMode = .always
            
            // Add right padding
            let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
            textField.rightView = rightPaddingView
            textField.rightViewMode = .always
        }

        // Add Done button toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(context.coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]
        searchBar.searchTextField.inputAccessoryView = toolbar

        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
}
