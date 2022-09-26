//
//  MyPageViewModel.swift
//  SlickThumbnail
//
//  Created by Nick Raptis on 9/23/22.
//

import SwiftUI

class MyPageViewModel: ObservableObject {
    
    private static let fetchCount = 6
    private static let probeAheadOrBehindAmountForPrefetch = 5
    
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
    
    // Could be called very often...
    private func fetchMoreThumbsIfNecessary() {
        
        if isFetching { return }
        
        let firstCellIndexOnScreen = layout.firstCellIndexOnScreen()
        let lastCellIndexOnScreen = layout.lastCellIndexOnScreen()
        
        if lastCellIndexOnScreen <= 0 { return }
        guard firstCellIndexOnScreen < lastCellIndexOnScreen else { return }
        guard firstCellIndexOnScreen < model.totalExpectedCount else { return }
        
        // Case 1: Is there any missing data from the cells on screen?
        var checkIndex = firstCellIndexOnScreen
        while checkIndex <= lastCellIndexOnScreen {
            // Are we in range? (Greater than 0) (Will not cause infinite re-fetch loop (Very Important))
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                // Is the data missing here? If so, start a new fetch from checkIndex
                if thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                }
            }
            checkIndex += 1
        }
        
        // Case 2: Is there any missing data slightly after the cells on screen?
        checkIndex = lastCellIndexOnScreen + 1
        while checkIndex < (lastCellIndexOnScreen + Self.probeAheadOrBehindAmountForPrefetch) {
            // Are we in range? (Greater than 0) (Will not cause infinite re-fetch loop (Very Important))
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                // Is the data missing here? If so, start a new fetch from checkIndex
                if thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                }
            }
            checkIndex += 1
        }
        
        // Case 3: Is there any missing data slightly before the cells on screen?
        checkIndex = firstCellIndexOnScreen - Self.probeAheadOrBehindAmountForPrefetch
        while checkIndex < firstCellIndexOnScreen {
            // Are we in range? (Greater than 0) (Will not cause infinite re-fetch loop (Very Important))
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                // Is the data missing here? If so, start a new fetch from checkIndex
                if thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
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
