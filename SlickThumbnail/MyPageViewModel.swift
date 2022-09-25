//
//  MyPageViewModel.swift
//  SlickThumbnail
//
//  Created by Nick Raptis on 9/23/22.
//

import SwiftUI

class MyPageViewModel: ObservableObject {
    
    private static let fetchCount = 6
    private static let probeRangeForCellPrefetch = 5
    
    static func mock() -> MyPageViewModel {
        return MyPageViewModel()
    }
    
    init() {
        layout.delegate = self
        fetch(at: 4, withCount: Self.fetchCount) { _ in }
    }
    
    private let model = MyPageModel()
    let layout = GridLayout()
    
    private(set) var isFetching = false
    
    func numberOfThumbCells() -> Int {
        return model.totalExpectedCount
    }
    
    func thumbModel(_ index: Int) -> ThumbModel? {
        return model.thumModel(index)
    }
    
    func clear() {
        model.clear()
    }
    
    func fetch(at index: Int, withCount count: Int, completion: @escaping ( Result<Void, ServiceError> ) -> Void) {
        
        isFetching = true
        model.fetch(at: index, withCount: count) { result in
            switch result {
            case .success:
                self.isFetching = false
                completion(.success( () ))
                self.objectWillChange.send()
                self.fetchMoreThumbsIfNecessary()
            case .failure(let error):
                self.isFetching = false
                completion(.failure( error ))
                self.objectWillChange.send()
            }
        }
    }
    
    // This could be called often...
    private func fetchMoreThumbsIfNecessary() {
        
        if isFetching { return }
        
        let firstCellIndexOnScreen = layout.firstCellIndexOnScreen()
        let lastCellIndexOnScreen = layout.lastCellIndexOnScreen()
        
        if firstCellIndexOnScreen > lastCellIndexOnScreen { return }
        if lastCellIndexOnScreen <= 0 { return }
        
        // Case 1: All of the cells which are currently on the screen...
        var checkIndex = firstCellIndexOnScreen
        while checkIndex <= lastCellIndexOnScreen {
            // Are we in range?
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                // Do we have this data yet? If not, fetch from THIS index...
                if thumbModel(checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
        // Case 2: Stuff that is slightly after our visible cell index range...
        checkIndex = lastCellIndexOnScreen + 1
        while checkIndex < (lastCellIndexOnScreen + Self.probeRangeForCellPrefetch) {
            // Are we in range?
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                // Do we have this data yet? If not, fetch from THIS index...
                if thumbModel(checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
        // Case 3: Stuff that is slightly before our visible cell index range...
        checkIndex = firstCellIndexOnScreen - Self.probeRangeForCellPrefetch
        while checkIndex < firstCellIndexOnScreen {
            // Are we in range?
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                // Do we have this data yet? If not, fetch from THIS index...
                if thumbModel(checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
    }
}

extension MyPageViewModel: GridLayoutDelegate {
    func cellsDidEnterScreen(_ startIndex: Int, _ endIndex: Int) {
        fetchMoreThumbsIfNecessary()
    }
    
    func cellsDidLeaveScreen(_ startIndex: Int, _ endIndex: Int) {
        fetchMoreThumbsIfNecessary()
    }
}
