//
//  MyPageViewModel.swift
//  SlickThumbnail
//
//  Created by Nick Raptis on 9/23/22.
//

import SwiftUI

class MyPageViewModel: ObservableObject {
    
    private static let fetchCount = 6
    private static let probeAheadOrBehindRangeForPrefetch = 5
    
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
    
    func thumbModel(at index: Int) -> ThumbModel? {
        return model.thumbModel(at: index)
    }
    
    func clear() {
        model.clear()
    }
    
    func fetch(at index: Int, withCount count: Int, completion: @escaping ( Result<Void, ServiceError> ) -> Void) {
        
        if isFetching { return }
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
    
    private func fetchMoreThumbsIfNecessary() {
        
        if isFetching { return }
        
        let firstCellIndexOnScreen = layout.firstCellIndexOnScreen()
        let lastCellIndexOnScreen = layout.lastCellIndexOnScreen()
        
        // Case 1: Cells directly on screen
        var checkIndex = firstCellIndexOnScreen
        while checkIndex <= lastCellIndexOnScreen {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                if thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
        // Case 2: Cells shortly after screen's range of indices
        checkIndex = lastCellIndexOnScreen + 1
        while checkIndex <= (lastCellIndexOnScreen + Self.probeAheadOrBehindRangeForPrefetch) {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                if thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
        // Case 3: Cells shortly before screen's range of indices
        checkIndex = firstCellIndexOnScreen - Self.probeAheadOrBehindRangeForPrefetch
        while checkIndex < firstCellIndexOnScreen {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                if thumbModel(at: checkIndex) == nil {
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
