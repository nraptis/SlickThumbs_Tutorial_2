//
//  ThumbGrid.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/15/22.
//

import SwiftUI

struct ThumbGrid<Item, ItemView> : View where ItemView: View, Item: ThumbGridConforming {
    
    let items: [Item]
    let layout: GridLayout
    let content: (Item) -> ItemView
    
    func thumb(item: Item) -> some View {
        let x = layout.getX(item.index)
        let y = layout.getY(item.index)
        return content(item)
            .offset(x: x, y: y)
    }
    
    var body: some View {
        ForEach(items) { item in
            thumb(item: item)
        }
    }
}
