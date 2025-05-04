//
//  SettingsView.swift
//  NFCPassportReaderApp
//
//  Created by Andy Qua on 10/02/2021.
//  Copyright © 2021 Andy Qua. All rights reserved.
//

import SwiftUI
import OSLog
import Combine
import NFCPassportReader
import UniformTypeIdentifiers
import MRZParser


struct NewEntryView: View {
    @EnvironmentObject var settings: SettingsStore
    
    @State private var showDetails = false
    @State private var showManualMRZ : Bool = false
    @State private var showScanMRZ : Bool = false
    
    @State private var showingAlert = false
    @State private var alertTitle : String = ""
    @State private var alertMessage : String = ""
    
    @Binding var clearInfo : Bool
    @Binding var showNewEntryView : Bool
    @Binding var fullName : String
    
    
    private let passportReader = PassportReader()
    
    
    var body: some View {
        ZStack {
            NavigationLink(
                destination:
                    PassportView(
                        clearInfo: $clearInfo,
                        showNewEntryView: $showNewEntryView,
                        fullName : $fullName
                    ).onAppear {
                        clearInfo = true
                    },
                isActive: $showDetails) { Text("") }
            NavigationLink( destination: MRZScanner(completionHandler: {
                mrz in
                
                if let (docNr, dob, doe) = parse( mrz:mrz ) {
                    settings.passportNumber = docNr
                    settings.dateOfBirth = dob
                    settings.dateOfExpiry = doe
                    clearInfo = false
                    showScanMRZ = false
                }
            }).navigationTitle("Scan MRZ"), isActive: $showScanMRZ){ Text("") }
            
            
            
            
            VStack {
                VStack{
                    Button(action: {self.showScanMRZ.toggle()}) {
                        Spacer()
                        Label("Scan MRZ", systemImage:"camera")
                            .padding(10)
                        Spacer()
                    }
                        .background(Color("zpurple"))
                        .foregroundStyle(.white)
                        .font(.title)
                        .cornerRadius(8)

                    Text("OR")
                        .font(.title2)
                        .foregroundColor(Color(#colorLiteral(red: 0.6919034719, green: 0.702383697, blue: 0.7021996379, alpha: 1)))
                        .padding([.top,.bottom],10)
                        

                    
                    MRZEntryView()
                        .padding([.bottom])
                }
                
                Divider()
                    .frame(height: 2)
                    .overlay(Color(#colorLiteral(red: 0.6919034719, green: 0.702383697, blue: 0.7021996379, alpha: 1)))
                    .padding(20)
                
                Button(action: {
                    self.scanPassport()
                }) {
                    HStack {
                        Spacer()
                        Text("Scan Passport")
                            .font(.largeTitle)
                            .foregroundColor(isValid ? .white : Color(#colorLiteral(red: 0.6919034719, green: 0.702383697, blue: 0.7021996379, alpha: 1)))
                            .cornerRadius(8)
                        Spacer()
                    }
    
                    .padding(10)
                
                }
                .background(isValid ? Color("zpurple") : Color.black.opacity(0.07))
                .cornerRadius(8)
                
                .disabled( !isValid )
            }
            .padding(.horizontal,30)
            
        }
    }
}



// MARK: View functions - functions that affect the view
extension NewEntryView {
    
    var isValid : Bool {
        return settings.passportNumber.count >= 8
    }

    func parse( mrz:String ) -> (String, Date, Date)? {
        print( "mrz = \(mrz)")
        
        let parser = MRZParser(isOCRCorrectionEnabled: true)
        if let result = parser.parse(mrzString: mrz),
           let docNr = result.documentNumber,
           let dob = result.birthdate,
           let doe = result.expiryDate
        {
            return (docNr, dob, doe)
        }
        return nil
    }
}

// MARK: Action Functions
extension NewEntryView {
    func scanPassport( ) {let appLogging = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "app")
        lastPassportScanTime = Date.now

        hideKeyboard()
        self.showDetails = false
        
        let df = DateFormatter()
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "YYMMdd"
        
        let pptNr = settings.passportNumber
        let dob = df.string(from:settings.dateOfBirth)
        let doe = df.string(from:settings.dateOfExpiry)
        let useExtendedMode = settings.useExtendedMode

        let passportUtils = PassportUtils()
        let mrzKey = passportUtils.getMRZKey( passportNumber: pptNr, dateOfBirth: dob, dateOfExpiry: doe)

        // Set the masterListURL on the Passport Reader to allow auto passport verification
        let masterListURL = Bundle.main.url(forResource: "masterList", withExtension: ".pem")!
        passportReader.setMasterListURL( masterListURL )
        
        // Set whether to use the new Passive Authentication verification method (default true) or the old OpenSSL CMS verifiction
        passportReader.passiveAuthenticationUsesOpenSSL = !settings.useNewVerificationMethod
        
        // If we want to read only specific data groups we can using:
//        let dataGroups : [DataGroupId] = [.COM, .SOD, .DG1, .DG2, .DG7, .DG11, .DG12, .DG14, .DG15]
//        passportReader.readPassport(mrzKey: mrzKey, tags:dataGroups, completed: { (passport, error) in
        
        appLogging.error( "Using version \(UIApplication.version)" )
        
        Task {
            let customMessageHandler : (NFCViewDisplayMessage)->String? = { (displayMessage) in
                switch displayMessage {
                    case .requestPresentPassport:
                        return "Hold your iPhone near an NFC enabled passport.  For U.S. passports, the chip is located on the inside of the back cover.  You may need to remove your phone case."
                    default:
                        // Return nil for all other messages so we use the provided default
                        return nil
                }
            }
            
            do {
                let passport = try await passportReader.readPassport( mrzKey: mrzKey, useExtendedMode: useExtendedMode,  customDisplayMessage:customMessageHandler)
                
                if let _ = passport.faceImageInfo {
                    print( "Got face Image details")
                }
                

                
                DispatchQueue.main.async {
                    self.settings.passport = passport
                    self.showDetails = true
                }
            } catch {
                self.alertTitle = "Oops"
                self.alertTitle = error.localizedDescription
                self.showingAlert = true

            }
        }
    }
}

struct NewEntryView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = SettingsStore()
        @State var showNewEntryView : Bool = false
        @State var clearInfo : Bool = false
        @State var fullName : String = ""
        NewEntryView(
            clearInfo: $clearInfo,
            showNewEntryView: $showNewEntryView,
            fullName: $fullName
        )
            .environmentObject(settings)
            .environment( \.colorScheme, .light)
    }
}
