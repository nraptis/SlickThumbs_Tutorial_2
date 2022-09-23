//
//  MyPageViewModel.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/20/22.
//

import SwiftUI

class MyPageViewModel: ObservableObject {
    
    private static let fetchCount = 6
    private static let probeRangeForFetchingMoreCells = 5
    
    private(set) var isFetching = false
    
    static func mock() -> MyPageViewModel {
        return MyPageViewModel()
    }
    
    let layout = GridLayout()
    private let model = MyPageModel()
    
    init() {
        layout.delegate = self
        fetch(at: 4, withCount: Self.fetchCount) { _ in }
    }
    
    func numberOfThumbCells() -> Int {
        return 118
    }
    
    func clear() {
        model.clear()
    }
    
    func thumbModel(at index: Int) -> ThumbModel? {
        return model.thumbModel(at: index)
    }
    
    func fetch(at index: Int, withCount count: Int, completion: @escaping ( Result<Void, ThumbError> ) -> Void) {
     
        isFetching = true
        model.fetch(at: index, withCount: count) { result in
            
            switch result {
                
            case .success:
                self.isFetching = false
                completion(.success(()))
                self.objectWillChange.send()
                self.fetchMoreThumbsIfNecessary()
            case .failure(let error):
                self.isFetching = false
                completion(.failure(error))
                self.objectWillChange.send()
            }
        }
    }
    
    // This may be called very often...
    fileprivate func fetchMoreThumbsIfNecessary() {
        
        if isFetching { return }
        if !layout.isAnyRowVisible() { return }
        
        let firstIndexOnScreen = layout.firstIndexOnScreen()
        let lastIndexOnScreen = layout.lastIndexOnScreen()
        
        //case 1: the visible cells on screen!
        
        var checkIndex = firstIndexOnScreen
        while checkIndex <= lastIndexOnScreen {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                //if the thumb model is missing, go ahead and fetch starting at checkIndex...
                if model.thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
        // case 2: a little bit after the screen's visible indices
        checkIndex = lastIndexOnScreen + 1
        while checkIndex < (lastIndexOnScreen + Self.probeRangeForFetchingMoreCells) {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                //if the thumb model is missing, go ahead and fetch starting at checkIndex...
                if model.thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
        // case 2: a little bit before the screen's visible indices
        checkIndex = firstIndexOnScreen - Self.probeRangeForFetchingMoreCells
        while checkIndex < firstIndexOnScreen {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                //if the thumb model is missing, go ahead and fetch starting at checkIndex...
                if model.thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
    }
    
    private func refreshInline() {
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        fetch(at: 0, withCount: Self.fetchCount) { _ in
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
    }
    
    func refresh() async {
        
        clear()
        
        if Thread.isMainThread {
            objectWillChange.send()
        } else {
            DispatchQueue.main.sync {
                self.objectWillChange.send()
            }
        }
        
        let t = Task.detached {
            self.refreshInline()
        }
        _ = await t.result
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
