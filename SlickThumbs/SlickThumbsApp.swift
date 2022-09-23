//
//  SlickThumbsApp.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/20/22.
//

import SwiftUI

@main
struct SlickThumbsApp: App {
    
    @StateObject var myPageViewModel = MyPageViewModel()
    var body: some Scene {
        WindowGroup {
            MyPageView(viewModel: myPageViewModel)
        }
    }
}
