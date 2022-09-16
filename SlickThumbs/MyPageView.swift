//
//  MyPageView.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/15/22.
//

import SwiftUI

struct MyPageView: View {
    
    @ObservedObject var viewModel: MyPageViewModel
    var body: some View {
        GeometryReader { containerGeometry in
            list(containerGeometry)
                .refreshable {
                    await viewModel.refresh()
                }
        }
    }
    
    func grid(_ containerGeometry: GeometryProxy, _ scrollContentGeometry: GeometryProxy) -> some View {
        
        let layout = viewModel.layout
        
        layout.registerContent(scrollContentGeometry)
        
        let visibleCells = layout.getAllVisibleCellModels()
        
        return ThumbGrid(items: visibleCells, layout: viewModel.layout) { cellModel in
            ThumbView(viewModel: viewModel,
                      index: cellModel.index,
                      width: layout.getWidth(cellModel.index),
                      height: layout.getHeight(cellModel.index))
        }
    }
    
    func list(_ containerGeometry: GeometryProxy) -> some View {
        
        if viewModel.layout.registerList(containerGeometry, numberOfThumbCells()) {
            DispatchQueue.main.async {
                self.viewModel.objectWillChange.send()
            }
        }
        
        return List {
            GeometryReader { scrollContentGeometry in
                grid(containerGeometry, scrollContentGeometry)
            }
            .frame(width: viewModel.layout.width,
                   height: viewModel.layout.height)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
    
    func numberOfThumbCells() -> Int {
        return 118
    }
    
}

struct MyPageView_Previews: PreviewProvider {
    static var previews: some View {
        MyPageView(viewModel: MyPageViewModel.mock())
    }
}
