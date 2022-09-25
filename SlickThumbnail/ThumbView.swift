//
//  ThumbView.swift
//  SlickThumbnail
//
//  Created by Nick Raptis on 9/25/22.
//

import SwiftUI

struct ThumbView: View {
    
    let thumbModel: ThumbModel?
    let width: CGFloat
    let height: CGFloat
    
    private static let tileBackground = RoundedRectangle(cornerRadius: 12)
    
    private func thumbContent(_ thumbModel: ThumbModel) -> some View {
        ZStack {
            Text("\(thumbModel.emoji)")
                .font(.system(size: width * 0.5))
        }
        .frame(width: width, height: height)
        .background(Self.tileBackground.fill().foregroundColor(.orange).opacity(0.5))
    }
    
    private func placeholderContent() -> some View {
        ZStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
        .frame(width: width, height: height)
        .background(Self.tileBackground.fill().foregroundColor(.purple).opacity(0.5))
    }
    
    @ViewBuilder
    var body: some View {
        if let thumbModel = thumbModel {
            thumbContent(thumbModel)
        } else {
            placeholderContent()
        }
    }
}

struct ThumbView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbView(thumbModel: ThumbModel.mock(),
                  width: 100,
                  height: 145)
    }
}
