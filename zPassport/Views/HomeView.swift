//
//  HomeView.swift
//  zPassport
//
//  Created by Alex Kim on 5/3/25.
//  Copyright © 2025 Alexander Kim. All rights reserved.
//s

import SwiftUI
import NFCPassportReader

struct HomeView: View {

    @EnvironmentObject var settings: SettingsStore
    
    @Binding var clearInfo : Bool
    @Binding var showNewEntryView : Bool
    
    @State private var storedPassports = [URL]()
    @State private var showImport : Bool = false
    @State private var showDetails = false
    
    @State private var showPassports = false
    
    @State private var image: UIImage?
    @State private var name = ""
    
    
    var body: some View {
        ZStack {
//                NavigationLink( destination: SettingsView(), isActive: $showSettings) { Text("") }
//                NavigationLink( destination: StoredPassportView(), isActive: $showSavedPassports) { Text("") }

          NavigationLink(
            destination:
                NewEntryView(
                    clearInfo: $clearInfo,
                    showNewEntryView: $showNewEntryView,
                )
                .onAppear {
                    if clearInfo {
                        settings.passportNumber = ""
                        settings.dateOfBirth = Date()
                        settings.dateOfExpiry = Date()
                    }
                },
            isActive: $showNewEntryView) { Text("") }
            
            NavigationLink( destination: SavedPassportView(), isActive: $showDetails) { Text("") }

            

            VStack {
                HStack{
                    Image("zpassport-light")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250)
                        .padding(.leading, -10)
    
                    
                    Spacer()
//                        Image(systemName: "gear")
//                            .resizable()
//                            .frame(width: 30, height: 30)
//                            .foregroundStyle(.gray)
//                            .padding(.top,5)
                }
                .padding(.top,10)
                
                ZStack {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 192, height: 192)
                        .foregroundStyle(Color(#colorLiteral(red: 0.6919034719, green: 0.702383697, blue: 0.7021996379, alpha: 1)))
                        .padding([.top],40)
                        .padding([.bottom])
                        .opacity(image != nil  ? 0 : 1)
                    
                    Image(uiImage:image ?? UIImage(named:"head")!)
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 192, height: 192)
                        .padding([.leading], 10.0)
                        .opacity(image != nil ? 1 : 0)
                }


                
                Text( name != "" ? name : "YOUR NAME HERE")
                    .font(.title)
                    .foregroundColor(.gray)
                    .padding(.leading,1)
                    .lineLimit(1)
                
                Divider()
                    .frame(height: 2)
                    .overlay(Color(#colorLiteral(red: 0.6919034719, green: 0.702383697, blue: 0.7021996379, alpha: 1)))
                    .padding(.horizontal,10)
                
                
                ForEach(self.storedPassports, id: \.self) { item in
                    
                    Button(action: {
                        if let data = try? Data(contentsOf: item),
                           let passport = loadPassport(data:data) {
                            self.settings.passport = passport
                            self.showDetails = true
                        }
                    }) {
                        Spacer()
                        Text("ID: " + item.deletingPathExtension().lastPathComponent)
                            .frame(height: 70)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .background (Color("zpurple"))
                    .foregroundStyle(.white)
                    .border(Color("zpurple"), width: 2)
                    .font(.title)
                    .cornerRadius(8)
                    .padding(.horizontal,10)
                    
                }
                .onDelete(perform: deletePassport)
                
                Button(action: {
                    self.showNewEntryView.toggle()
                }){
                    HStack {
                        Image(systemName: "plus")
                        Text("Add New Credentials")
                            .font(.title)

                    }
                        .foregroundStyle(Color("zpurple"))
                        .padding(.top)

                    
                }
            
                

                Spacer()
            }
            .padding(.horizontal,20)
            
        }
        .fileImporter(
            isPresented: $showImport, allowedContentTypes: [.json,.text],
            allowsMultipleSelection: false
        ) { result in
            
            hideKeyboard()
            
            guard let selectedFile: URL = try? result.get().first else { return }
            if selectedFile.startAccessingSecurityScopedResource() {
                defer { selectedFile.stopAccessingSecurityScopedResource() }
                importFile( url:selectedFile )
            } else {
                print("Unable to read file contents - denied")
            }

        }
        .onAppear() {
            loadStoredPassports()
            if storedPassports.count > 0 {
                if let data = try? Data(contentsOf: storedPassports[0]),
                   let passport = loadPassport(data:data) {
                    self.name = passport.lastName + ", " + passport.firstName
                    self.image = passport.passportImage
                }
            }
        }
//            .toolbar {
//                ToolbarItem(placement: .primaryAction) {
//                    Menu {
//                        Button(action: {showSettings.toggle()}) {
//                            Label("Settings", systemImage: "gear")
//                        }
//                        Button(action: {self.showSavedPassports.toggle()}) {
//                            Label("Show saved passports", systemImage: "doc")
//                        }
//                    } label: {
//                        Image(systemName: "gear")
//                            .foregroundColor(Color.secondary)
//                    }
//                }
//            }
        .background(Color.white)
    }
}



extension HomeView {
    func loadStoredPassports() {
        
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: FileManager.cachesFolder, includingPropertiesForKeys: nil, options: [])
            
            storedPassports = urls.filter { $0.pathExtension == "json" }
        } catch {
            print("Could not search for urls of files in documents directory: \(error)")
        }
    }
    
    func importFile( url : URL ) {
        
        do {
            let data = try Data(contentsOf: url )
            if let passport = loadPassport( data: data ) {
                
                if true {
                    // Save passport to docs folder
                    let savedPath = FileManager.cachesFolder.appendingPathComponent("\(passport.documentNumber).json")
                    try? data.write(to: savedPath, options: .completeFileProtection)
                }
                
                self.settings.passport = passport
                self.showDetails = true
            }
        } catch {
            // Handle failure.
            print("Unable to read file contents")
            print(error.localizedDescription)
        }
    }
    
    func loadPassport( data: Data) -> NFCPassportModel? {
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        if let arr = json as? [String:String] {
            
            let passport = NFCPassportModel(from: arr)
            
            let masterListURL = Bundle.main.url(forResource: "masterList", withExtension: ".pem")!
            passport.verifyPassport(masterListURL: masterListURL)
            return passport
        }
        return nil
    }
    
    func deletePassport( at offsets: IndexSet) {
        
        let fm = FileManager.default
        offsets.forEach {
            let url = storedPassports[$0]
            try? fm.removeItem(at: url)
        }
        storedPassports.remove(atOffsets: offsets)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let settings = SettingsStore()
        @State var showNewEntryView : Bool = false
        @State var clearInfo : Bool = false
        HomeView(
            clearInfo: $clearInfo,
            showNewEntryView: $showNewEntryView,
            
        )
            .environmentObject(settings)
            .environment( \.colorScheme, .light)
    }
}
