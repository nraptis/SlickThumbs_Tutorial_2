//
//  SlickThumbsApp.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/15/22.
//

import SwiftUI

@main
struct SlickThumbsApp: App {
    let myPageViewModel = MyPageViewModel()
    var body: some Scene {
        WindowGroup {
            MyPageView(viewModel: myPageViewModel)
        }
    }
}
