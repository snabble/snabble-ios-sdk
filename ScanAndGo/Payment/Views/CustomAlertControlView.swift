//
//  CustomAlertControlView.swift
//  ScanAndGo
//
//  Created by Uwe Tilemann on 09.06.24.
//

import SwiftUI

import SnabbleCore
import SnabbleUI

extension Shopper {
    func alert(_ controller: UIAlertController?) -> Alert {
        if let controller {
            Alert(title: Text(controller.title ?? "no title"),
                              message: Text(controller.message ?? "No message available!"))
        } else {
            Alert(title: Text("No Alert Controller"))
        }
    }
}

struct CustomSheetControlView: UIViewControllerRepresentable {
    var sheet: SheetProviding
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CustomSheetControlView>) -> UIViewController {
        return UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<CustomSheetControlView>) {
        let sheet = sheet.sheetController {
            print("sheetController dismiss")
//            isPresented.toggle()
        }
                        
        DispatchQueue.main.async {
            uiViewController.present(sheet, animated: true)
        }
    }
}
