//
//  TeleCashUserView.swift
//
//
//  Created by Uwe Tilemann on 06.08.24.
//

import SwiftUI

import SnabbleUser

struct TeleCashUserView: View {
    let userFields = UserField.fieldsWithout([.firstName, .state, .dateOfBirth])
    
    var body: some View {
        UserView(fields: userFields) { user in
            print("got User:", user)
        }
    }
}


#Preview {
    TeleCashUserView()
}
