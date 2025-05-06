//
//  SavedPassportView.swift
//  zPassport
//
//  Created by Alex Kim on 5/3/25.
//  Copyright © 2025 Alexander Kim. All rights reserved.
//

import SwiftUI
import NFCPassportReader

struct SavedPassportView : View {
    @EnvironmentObject var settings: SettingsStore
    @State private var showExportPassport : Bool = false
    @State private var savePassportValid : Bool = true
    
    
    var body: some View {
        VStack {
//            NavigationLink( destination: ExportPassportView(), isActive: $showExportPassport) { Text("") }
            
            PassportSummaryView(passport:settings.passport!)
//            HStack {
//
//                Button(action: {showExportPassport.toggle()}) {
//                    Label("Export passport", systemImage: "square.and.arrow.up")
//                }
//                .padding()
//                Spacer()
//                Button(action: {shareLogs()}) {
//                    Label("Share logs", systemImage: "square.and.arrow.up")
//                }
//                .padding()
//            }
            
            DetailsView(passport:settings.passport!)
        }
        .navigationTitle("Passport Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#if DEBUG
struct SavedPassportView_Previews : PreviewProvider {
    static var previews: some View {
        
        let passport : NFCPassportModel
        if let file = Bundle.main.url(forResource: "passport", withExtension: "json"),
           let data = try? Data(contentsOf: file),
           let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let arr = json as? [String:String] {
            passport = NFCPassportModel(from: arr)
        } else {
            passport = NFCPassportModel()
        }
        let settings = SettingsStore()
        settings.passport = passport
        
        @State var showNewEntryView : Bool = false
        @State var clearInfo : Bool = false
        @State var fullName : String = ""
        
        return NavigationView {
            SavedPassportView()
                .environmentObject(settings)
                .environment( \.colorScheme, .light)
                .navigationTitle("WEEE")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
