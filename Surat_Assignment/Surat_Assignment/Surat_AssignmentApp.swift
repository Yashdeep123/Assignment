//
//  Surat_AssignmentApp.swift
//  Surat_Assignment
//
//  Created by Yash Patil on 27/08/24.
//

import SwiftUI

@main
struct Surat_AssignmentApp: App {
    @State var vm = ViewModel()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(vm)
        }
    }
}
