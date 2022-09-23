//
//  ThumbView.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/22/22.
//

import SwiftUI

struct ThumbView: View {
    
    @ObservedObject var viewModel: MyPageViewModel
    let index: Int
    let width: CGFloat
    let height: CGFloat
    
    private let shape = RoundedRectangle(cornerRadius: 12)
    
    private func thumbContent(_ thumbModel: ThumbModel) -> some View {
        ZStack {
            Text("\(thumbModel.image)")
                .font(.system(size: width * 0.5))
        }
        .frame(width: width, height: height)
        .background(shape.fill().foregroundColor(.orange).opacity(0.5))
    }
    
    private func placeholderContent() -> some View {
        ZStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
        .frame(width: width, height: height)
        .background(shape.fill().foregroundColor(.purple).opacity(0.5))
    }
    
    @ViewBuilder
    var body: some View {
        if let thumbModel = viewModel.thumbModel(at: index) {
            thumbContent(thumbModel)
        } else {
            placeholderContent()
        }
    }
}

struct ThumbView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbView(viewModel: MyPageViewModel.mock(),
                  index: 0,
                  width: 100,
                  height: 140)
    }
}
