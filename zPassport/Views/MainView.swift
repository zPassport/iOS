//
//  MainView.swift
//  NFCPassportReaderApp
//
//  Created by Andy Qua on 04/06/2019.
//  Copyright © 2019 Andy Qua. All rights reserved.
//

import SwiftUI
import OSLog
import Combine
import NFCPassportReader
import UniformTypeIdentifiers
import MRZParser

let appLogging = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "app")


struct MainView : View {
    @EnvironmentObject var settings: SettingsStore

    @State private var showingAlert = false
    @State private var showingSheet = false
    @State private var alertTitle : String = ""
    @State private var alertMessage : String = ""
    @State private var showSettings : Bool = false
    @State private var showScanMRZ : Bool = false
    @State private var showManualMRZ : Bool = false
    @State private var showSavedPassports : Bool = false
    @State private var showNewEntryView : Bool = false
    
    @State private var clearInfo : Bool = true
    @State private var fullName : String = ""

    
    @State var page = 0
    
    @State var bgColor = Color.white

    var body: some View {
        NavigationView {
            HomeView(
                clearInfo: $clearInfo,
                showNewEntryView: $showNewEntryView,
                fullName : $fullName
            )
            .onAppear {
                clearInfo = true
            }
            
        }

    }
    
}


//MARK: PreviewProvider
#if DEBUG
struct ContentView_Previews : PreviewProvider {

    static var previews: some View {
        let settings = SettingsStore()
        
        return Group {
            MainView()
                .environmentObject(settings)
                .environment( \.colorScheme, .light)
        }
    }
}
#endif



