//
//  MyPageViewModel.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/15/22.
//

import SwiftUI

class MyPageViewModel: ObservableObject {
    
    private var isFetching = false
    
    private static let fetchCount = 6
    private static let probeRangeForFetchingMoreThumbs = 5
    
    static func mock() -> MyPageViewModel {
        return MyPageViewModel()
    }
    
    init() {
        layout.delegate = self
        fetch(at: 4, withCount: Self.fetchCount) { _ in }
    }
    
    let layout = GridLayout()
    let model = MyPageModel()
    
    func thumbModel(at index: Int) -> ThumbModel? {
        return model.thumbModel(at: index)
    }
    
    func clear() {
        model.clear()
    }
    
    func fetch(at index: Int, withCount count: Int, completion: @escaping (Result<Void, ThumbError>) -> Void) {
        fetch(at: index, withCount: count, attempts: 1, completion: completion)
    }
    
    func fetch(at index: Int, withCount count: Int, attempts attemptCount: Int, completion: @escaping (Result<Void, ThumbError>) -> Void) {
        
        isFetching = true
        
        model.fetch(at: index, withCount: count) { modelResult in
            
            switch modelResult {
            case .success:
                self.isFetching = false
                self.objectWillChange.send()
                completion(.success(()))
                self.fetchMoreThumbsIfNecessary()
                
            case .failure(let error):
                if attemptCount < 3 {
                    self.fetch(at: index, withCount: count, attempts: attemptCount + 1, completion: completion)
                } else {
                    print("web service failed 3 times! \(error.localizedDescription)")
                    self.isFetching = false
                    self.objectWillChange.send()
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func refreshInline() {
        
        let g = DispatchGroup()
        
        g.enter()
        self.fetch(at: 4, withCount: Self.fetchCount) { _ in
            g.leave()
        }
        g.wait()
    }
    
    private func postUpdate() {
        if Thread.isMainThread {
            objectWillChange.send()
        } else {
            DispatchQueue.main.sync {
                self.objectWillChange.send()
            }
        }
    }
    
    func refresh() async {
        clear()
        postUpdate()
        
        let t = Task.detached {
            self.refreshInline()
        }
        
        _ = await t.result
        postUpdate()
    }
    
    private func fetchMoreThumbsIfNecessary() {
        // what we want ... "first index on screen" / "last index on screen"
        
        if isFetching { return }
        if layout.isAnyRowVisible() == false { return }
        
        let firstIndexOnScreen = layout.firstIndexOnScreen()
        let lastIndexOnScreen = layout.lastIndexOnScreen()
        
        // are we missing anything in our visible range?
        
        var checkIndex = firstIndexOnScreen
        while checkIndex <= lastIndexOnScreen {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                if model.thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
        // are we missing anything AFTER our visible range?
        checkIndex = lastIndexOnScreen + 1
        while checkIndex < (lastIndexOnScreen + Self.probeRangeForFetchingMoreThumbs) {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                if model.thumbModel(at: checkIndex) == nil {
                    fetch(at: checkIndex, withCount: Self.fetchCount) { _ in }
                    return
                }
            }
            checkIndex += 1
        }
        
        // are we missing anything AFTER our visible range?
        checkIndex = firstIndexOnScreen - Self.probeRangeForFetchingMoreThumbs
        while checkIndex < firstIndexOnScreen {
            if checkIndex >= 0 && checkIndex < model.totalExpectedCount {
                if model.thumbModel(at: checkIndex) == nil {
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
