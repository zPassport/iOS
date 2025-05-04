
//
//  PassportView.swift
//  NFCPassportReaderApp
//
//  Created by Andy Qua on 30/06/2019.
//  Copyright © 2019 Andy Qua. All rights reserved.
//

import SwiftUI
import NFCPassportReader

struct PassportView : View {
    @EnvironmentObject var settings: SettingsStore
    @State private var showExportPassport : Bool = false
    @State private var savePassportValid : Bool = true
    
    @Binding var clearInfo : Bool
    @Binding var showNewEntryView : Bool
    @Binding var fullName : String
    
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
            Button(action: {
                fullName = settings.passport!.lastName + ", " + settings.passport!.firstName;
                savePassport(passport: settings.passport!)
            }) {
                Spacer()
                Label("Save", systemImage:"plus.app")
                    .padding(10)
                Spacer()
            }
            .background(savePassportValid ? Color("zpurple") : Color.black.opacity(0.07)
            )
            .foregroundStyle(savePassportValid ? .white : Color(#colorLiteral(red: 0.6919034719, green: 0.702383697, blue: 0.7021996379, alpha: 1))
            )
            .font(.title)
            .cornerRadius(8)
            .padding(.horizontal,30)
            .disabled( !savePassportValid)
            
            DetailsView(passport:settings.passport!)
        }
        .navigationTitle("Passport Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension PassportView {
    func savePassport(passport : NFCPassportModel)
    {
        Task {
            // Save passport
            let dict = passport.dumpPassportData(selectedDataGroups: DataGroupId.allCases, includeActiveAuthenticationData: true)
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) {
                
                let savedPath = FileManager.cachesFolder.appendingPathComponent("\(passport.documentNumber).json")
                
                try? data.write(to: savedPath, options: .completeFileProtection)
    
            }
        
            print("Saved passport")
            
            self.showNewEntryView.toggle()

            
        }
    }
    
    
    func shareLogs() {
        hideKeyboard()
        PassportUtils.shareLogs()
    }
}

#if DEBUG
struct PassportView_Previews : PreviewProvider {
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
            PassportView(
                clearInfo: $clearInfo,
                showNewEntryView: $showNewEntryView,
                fullName: $fullName
            )
                .environmentObject(settings)
                .environment( \.colorScheme, .light)
                .navigationTitle("WEEE")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
