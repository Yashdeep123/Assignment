//
//  ContentView.swift
//  Surat_Assignment
//
//  Created by Yash Patil on 27/08/24.
//

import SwiftUI
import Observation
import CoreData
import CryptoKit

struct AccountDetail: Identifiable {
    let id = UUID().uuidString
    let account: String
    let username: String
    let password: String
}

struct HomeView: View {
    
    @State var isPresented: Bool = false
    @Environment(ViewModel.self) var vm: ViewModel
    
    @State var showAccount: Bool = false
    
    @State var accountDetails: AccountDetail?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack {
                titleView
                
                if !vm.savedPasswords.isEmpty {
                    passwordsList
                }else {
                    Text("No Passwords Yet")
                        .font(.title)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    
                }
                
            }
            .padding()
            
            Button {
                isPresented = true
                
            } label: {
                Image(.button)
                    .padding(.trailing)
            }
            
        }
        .background(.gray.opacity(0.1))

        .sheet(isPresented: $isPresented) {
            SheetView(isPresented: $isPresented)
                .presentationDetents([.height(350)])
                .presentationCornerRadius(25)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $accountDetails, content: { accountDetails in
            
            AccountView(account: accountDetails.account, username: accountDetails.username, password: accountDetails.password, oldaccount: accountDetails.account, oldUserName: accountDetails.username, oldPassword: accountDetails.password)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)

        })
    }
}

extension HomeView {
    func securePassword(_ data: Data?, key: String?) -> String {
        var password: String = ""
        
        guard let data,
              let key,
              let encodedKey = Data(base64Encoded: key) else { return "" }
        
        let result = vm.decrypt(data: data, key: SymmetricKey(data: encodedKey))
        
        for _ in 1...result.count {
            password.append("*")
        }
        
        return password
    }
    
    var titleView: some View {
        VStack {
            HStack {
                Text("Password Manager")
                    .font(.system(size: 20).bold())
                    .frame(alignment: .leading)
                Spacer()
            }
            
            Divider()
        }

    }
    
    var passwordsList: some View {
       ScrollView {
            VStack(spacing: 25) {
                listView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .animation(.linear, value: vm.savedPasswords)
        }
       .padding(.top)
    }
    
    @ViewBuilder
    var listView: some View {
        ForEach(vm.savedPasswords, id: \.id) { (credential: Credentials) in
            HStack(spacing: 10) {
                Text(credential.account!)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                
                SecureField(securePassword(credential.encryptedPassword, key: credential.key), text: .constant(""))
                    .padding(.top, 10)
                    .font(.title)
                    .allowsHitTesting(false)
                
                Image(systemName: "chevron.right")
                    .padding()
            }
            .onTapGesture {
                let password = passwordString(credential)
                self.accountDetails = AccountDetail(account: credential.account!, username: credential.usernameOrEmail!, password: password)
            }
            .frame(height: 70, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 35)
                //                                .stroke(.gray, lineWidth: 0.5)
                    .foregroundStyle(.white)
            }
        }
    }
    
    func passwordString(_ credential: Credentials) -> String {
        guard let data = credential.encryptedPassword,
              let key = Data(base64Encoded: credential.key!) else { return "" }
       
        
        let result = vm.decrypt(data: data, key: SymmetricKey(data: key))
        
        return result
    }
}

struct AccountView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(ViewModel.self) var vm: ViewModel
    
    @State var allowsEditing: Bool = false
    
    @State var account: String = ""
    @State var username: String = ""
    @State var password: String = ""
    
    @State var oldaccount: String = ""
    @State var oldUserName: String = ""
    @State var oldPassword: String = ""

    @State var isSecure: Bool = true
        
    var body: some View {
        VStack(alignment: .leading, spacing: 35) {
            Text("Account Details")
                .font(.title2.bold())
                .foregroundStyle(.blue)
            
            // Custom fields
            VStack(alignment: .leading, spacing: 25) {
                
                DetailsView(title: "Account Type", value: $account)
                
                DetailsView(title: "username/email", value: $username)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("password")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    
                    Group {
                        if isSecure {
                            SecureField("", text: $password)
                                .frame(width: 250)
                                .font(.title2.bold())
                                .allowsHitTesting(allowsEditing)
                            
                        }else {
                            TextField("", text: $password)
                                .frame(width: 250)
                                .font(.title2.bold())
                                .allowsHitTesting(allowsEditing)
                        }
                    }
                    .overlay(alignment: .trailing) {
                        Button {
                            isSecure.toggle()
                        } label: {
                            Image(systemName: isSecure ? "eye.slash": "eye")
                                .tint(.black)
                        }
                    }
                }
                
            }
            
            HStack(spacing: 20) {
                Button {
                    if allowsEditing {
                        edit()
                    }
                    allowsEditing.toggle()
                    
                } label: {
                    Text(allowsEditing ? "Done" : "Edit")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 150, height: 45)
                        .background {
                            RoundedRectangle(cornerRadius: 25)
                                .foregroundStyle(.black.gradient)
                        }
                }
                
                Button {
                    delete()
                    dismiss()
                } label: {
                    Text("Delete")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 150, height: 45)
                        .background {
                            RoundedRectangle(cornerRadius: 25)
                                .foregroundStyle(.red.gradient)
                        }
                }
            }
        }
    }
    
    func delete() {
        let credential = vm.savedPasswords.first(where: {
            $0.account == oldaccount })
        vm.delete(credential)
        
    }
    
    func edit() {
        
        if !vm.savedPasswords.contains(where: { $0.usernameOrEmail == username && $0.password == password && $0.account == account }) {
           
            delete()
            
            vm.addValues(with: account, userName: username, password: password)
            
            dismiss()
        }
    }
    
    func DetailsView(title: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.gray)
            
            TextField("", text: value)
                .frame(width: 300)
                .font(.title2.bold())
                .allowsHitTesting(allowsEditing)
                
        }
    }
}

struct SheetView: View {
    
    @Environment(ViewModel.self) var vm: ViewModel
    
    @Binding var isPresented: Bool
    @State var account: String = ""
    @State var userName: String = ""
    @State var password: String = ""
    
    @State var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Account Name", text: $account)
                .frame(width: 300, height: 20, alignment: .center)
                .autocorrectionDisabled()                .textInputAutocapitalization(.never)

                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 0.5)
                        .foregroundStyle(.gray)
                }
            
            TextField("Username/Email", text: $userName)
                .frame(width: 300, height: 20, alignment: .center)
                .autocorrectionDisabled()                .textInputAutocapitalization(.never)

                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 0.5)
                        .foregroundStyle(.gray)
                }
            
            CustomTextField(text: $password)                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            Button {
                addAccount(withAccount: account, userName: userName, password: password)
            } label: {
                
                Text("Add New Account")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 330, height: 50)
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundStyle(.black.gradient)
                    }
            }
            
            Text(errorMessage)
                .foregroundStyle(.red)
        }
    }
}

extension SheetView {
    func addAccount(withAccount account: String, userName: String, password: String) {
        guard !account.isEmpty,
              !userName.isEmpty,
              !password.isEmpty
            else {
            errorMessage = "One of the fields are empty"
            return }
        
        if !(password.count >= 8) {
            errorMessage = "Password must contain at least 8 letters"
            return
        }
        
        if vm.savedPasswords.contains(where: { $0.usernameOrEmail == userName }) {
            errorMessage = "Username already exists"
            return
        }
        
        vm.addValues(with: account, userName: userName, password: password)
        
        self.isPresented = false
    }
}

struct CustomTextField: View {
    @State private var isSecure: Bool = true
    @Binding var text: String
    
    var body: some View {
        HStack {
            if isSecure {
                SecureField("Password", text: $text)
            }else {
                TextField("Password", text: $text)
            }
        }
        .overlay(alignment: .trailing) {
            Button {
                isSecure.toggle()
            } label: {
                Image(systemName: isSecure ? "eye.slash": "eye")
                    .tint(.black)
            }

        }
        .frame(width: 300, height: 18, alignment: .center)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .stroke(lineWidth: 0.5)
                .foregroundStyle(.gray)
        }
        
    }
}

#Preview {
    HomeView()
        .environment(ViewModel())
}

#Preview {
    SheetView(isPresented: .constant(true))
        .environment(ViewModel())
}

#Preview {
    AccountView(account: "", username: "", password: "", oldaccount: "", oldUserName: "", oldPassword: "")
        .environment(ViewModel())

}

@Observable
class ViewModel {
    
    let persistentContainer: NSPersistentContainer
        
    var savedPasswords: [Credentials] = []
    
    init() {
        
        persistentContainer = NSPersistentContainer(name: "Container")
        
        persistentContainer.loadPersistentStores { storeDescription, error in
            if let error {
               print("Error: \(error)")
            }else {
                print("SUCCESSFULL Loading")
            }
        }
        
        fetchValues()
    }
    
    func fetchValues() {
        let request = NSFetchRequest<Credentials>(entityName: "Credentials")
        
        do {
            savedPasswords = try persistentContainer.viewContext.fetch(request)
        }catch let error {
            print("Error fetching the values: \(error)")
        }
    }
    
    func addValues(with account: String, userName: String, password: String) {
        
        if !savedPasswords.contains(where: { $0.account == account && $0.password == password && $0.usernameOrEmail == password }) {
            let entity = Credentials(context: persistentContainer.viewContext)
            entity.account = account
            entity.usernameOrEmail = userName
            let key = SymmetricKey(size: .bits256)
            entity.encryptedPassword = encryptString(password: password, key: key)
            entity.key = key.withUnsafeBytes({ Data(Array($0))}).base64EncodedString()
            
            save()

        }
        
    }
    
    func delete(_ object: Credentials?) {
        if let object {
            persistentContainer.viewContext.delete(object)
            save()
        }
    }
    
    func save() {
        do {
            try persistentContainer.viewContext.save()
            fetchValues()
            
        }catch let error {
            print("Error saving the data: \(error)")
        }
    }
    
    func encryptString(password: String, key: SymmetricKey) -> Data {
                
        let data = Data(password.utf8)
        
        do {
            let data = try encrypt(data: data, key: key)
            return data
        }catch let error {
            print("Error encrypting: \(error)")
            return Data()
        }
    }
    
    func encrypt(data: Data, key: SymmetricKey) throws -> Data {

        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    func decrypt(data: Data, key: SymmetricKey) -> String {
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            let result = String(data: decryptedData, encoding: .utf8)!
            print(result)
            return result

        }catch let error {
            print("Error decrypting: \(error)")
            return ""
        }
    }
    
}
