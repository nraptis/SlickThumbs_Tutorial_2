//
//  GridLayout.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/20/22.
//

import SwiftUI

// Give the view "cells" (cell models) to iterate over (ForEach) (Identifiable)
// Serve up the frame of each cell
// Serve up the geometry (size) of the container of all the cells... (Scroll content size)

protocol GridLayoutDelegate: AnyObject {
    func cellsDidEnterScreen(_ startIndex: Int, _ endIndex: Int)
    func cellsDidLeaveScreen(_ startIndex: Int, _ endIndex: Int)
}

class GridLayout {
    
    // Pertaining only to layout, not actual data
    struct ThumbGridCellModel: ThumbGridConforming {
        let index: Int
        var id: Int {
            return index
        }
    }
    
    weak var delegate: GridLayoutDelegate?
    
    private(set) var width: CGFloat = 255
    private(set) var height: CGFloat = 255
    
    private let maximumCellWidth = 100
    private let cellHeight = 140
    
    private let cellSpacingH = 9
    private let cellPaddingLeft = 24
    private let cellPaddingRight = 24
    
    private let cellSpacingV = 9
    private let cellPaddingTop = 24
    private let cellPaddingBottom = 128
    
    private var _numberOfElements = 0
    private var _numberOfCols = 0
    private var _numberOfRows = 0
    private var _cellWidthArray = [Int]()
    private var _cellXArray = [Int]()
    private var _cellYArray = [Int]()
    
    private var _rowVisible = [Bool]()
    private var _cellVisible = [Bool]()
    
    private var _firstIndexOnScreen = 0
    private var _lastIndexOnScreen = 0
    
    
    private var _containerFrame = CGRect.zero
    private var _containerFrameWithoutSafeArea = CGRect.zero
    
    private var _scrollContentFrame = CGRect.zero
    
    func clear() {
        
        _numberOfElements = 0
        _numberOfCols = 0
        _numberOfRows = 0
        _cellWidthArray = [Int]()
        _cellXArray = [Int]()
        _cellYArray = [Int]()
        
        _rowVisible = [Bool]()
        _cellVisible = [Bool]()
        
        _firstIndexOnScreen = 0
        _lastIndexOnScreen = 0
    }
    
    func registerContainer(_ containerGeometry: GeometryProxy, _ numberOfElements: Int) -> Bool {
        
        var newContainerFrame = containerGeometry.frame(in: .global)
        _containerFrameWithoutSafeArea = newContainerFrame
        
        //expand our container frame to erase the safe area (they are factored in by system)
        
        let left = containerGeometry.safeAreaInsets.leading
        let right = containerGeometry.safeAreaInsets.trailing
        let top = containerGeometry.safeAreaInsets.top
        let bottom = containerGeometry.safeAreaInsets.bottom
        
        newContainerFrame = CGRect(x: newContainerFrame.minX - left,
                                   y: newContainerFrame.minY - top,
                                   width: newContainerFrame.width + (left + right),
                                   height: newContainerFrame.height + (top + bottom))
        
        
        // Did frame or ele count change?
        if newContainerFrame != _containerFrame || numberOfElements != _numberOfElements {
            
            clear()
            
            _containerFrame = newContainerFrame
            _numberOfElements = numberOfElements
            
            // Then we need to layout the 2d grid!!!
            layoutGrid()
            
            return true
        }
        
        return false
    }
    
    func registerScrollContent(_ scrollContentGeometry: GeometryProxy) {
        let newScrollContentFrame = scrollContentGeometry.frame(in: .global)
        _scrollContentFrame = newScrollContentFrame
        handleScrollContentDidChangePosition(_containerFrame, _scrollContentFrame)
    }
    
    private static let onScreenPadding = -72
    func handleScrollContentDidChangePosition(_ containerFrame: CGRect, _ scrollContentFrame: CGRect) {
        
        let contentTop = Int(containerFrame.minY - scrollContentFrame.minY) - Self.onScreenPadding
        let contentBottom = Int(containerFrame.maxY - scrollContentFrame.minY) + Self.onScreenPadding
        let contentRange = contentTop...contentBottom
        
        var shouldRefreshFirstAndLastIndexOnScreen = false
        
        for rowIndex in 0..<_numberOfRows {
            
            let cellTop = _cellYArray[rowIndex]
            let cellBottom = cellTop + cellHeight
            
            let cellRange = cellTop...cellBottom
            
            let overlap = contentRange.overlaps(cellRange)
            
            let cellStartIndex = firstIndexOfRow(rowIndex)
            let cellEndIndex = lastIndexOfRow(rowIndex)
            
            if overlap {
                //show these cells!
                if _rowVisible[rowIndex] == false {
                    _rowVisible[rowIndex] = true
                    for cellIndex in cellStartIndex...cellEndIndex { _cellVisible[cellIndex] = true }
                    delegate?.cellsDidEnterScreen(cellStartIndex, cellEndIndex)
                    shouldRefreshFirstAndLastIndexOnScreen = true
                }
            } else {
                //hide these cells!
                
                if _rowVisible[rowIndex] == true {
                    _rowVisible[rowIndex] = false
                    for cellIndex in cellStartIndex...cellEndIndex { _cellVisible[cellIndex] = false }
                    delegate?.cellsDidLeaveScreen(cellStartIndex, cellEndIndex)
                    shouldRefreshFirstAndLastIndexOnScreen = true
                }
            }
        }
        
        if shouldRefreshFirstAndLastIndexOnScreen {
            refreshFirstAndLastIndexOnScreen()
        }
        
    }
    
    private func layoutGrid() {
        _numberOfCols = numberOfCols()
        _numberOfRows = numberOfRows()
        _cellWidthArray = cellWidthArray()
        
        buildXArray()
        buildYArray()
        buildVisibityArrays()
        
        width = _containerFrame.width
        height = CGFloat((_numberOfRows * cellHeight) + (cellPaddingTop + cellPaddingBottom))
        
        //add the vertical spacing between the cells!!!
        if _numberOfRows > 1 {
            height += CGFloat((_numberOfRows - 1) * cellSpacingV)
        }
    }
    
    private func buildXArray() {
        
        if _cellXArray.count != _numberOfCols {
            _cellXArray = [Int](repeating: 0, count: _numberOfCols)
        }
        
        var cellX = cellPaddingLeft
        var indexX = 0
        while indexX < _numberOfCols {
            _cellXArray[indexX] = cellX
            
            //advance cell x...
            cellX += _cellWidthArray[indexX] + cellSpacingH
            indexX += 1
        }
        
    }
    
    private func buildYArray() {
        if _cellYArray.count != _numberOfRows {
            _cellYArray = [Int](repeating: 0, count: _numberOfRows)
        }
        
        var cellY = cellPaddingTop
        var indexY = 0
        while indexY < _numberOfRows {
            _cellYArray[indexY] = cellY
            
            //advance cell y...
            cellY += cellHeight + cellSpacingV
            indexY += 1
        }
    }
    
    private func buildVisibityArrays() {
        
        if (_rowVisible.count) != _numberOfRows {
            _rowVisible = [Bool](repeating: false, count: _numberOfRows)
        }
        
        let numberOfCells = _numberOfRows * _numberOfCols
        if (_cellVisible.count) != numberOfCells {
            _cellVisible = [Bool](repeating: false, count: numberOfCells)
        }
    }
    
    func firstIndexOfRow(_ rowIndex: Int) -> Int {
        return _numberOfCols * rowIndex
    }
    
    func lastIndexOfRow(_ rowIndex: Int) -> Int {
        return (_numberOfCols * rowIndex) + (_numberOfCols - 1)
    }
    
    func firstIndexOnScreen() -> Int {
        return _firstIndexOnScreen
    }
    
    func lastIndexOnScreen() -> Int {
        return _lastIndexOnScreen
    }
    
    func refreshFirstAndLastIndexOnScreen() {
        _firstIndexOnScreen = 0
        _lastIndexOnScreen = 0
        var found = false
        for rowIndex in 0..<_numberOfRows {
            if _rowVisible[rowIndex] {
                if found == false {
                    found = true
                    _firstIndexOnScreen = firstIndexOfRow(rowIndex)
                    _lastIndexOnScreen = lastIndexOfRow(rowIndex)
                } else {
                    _lastIndexOnScreen = lastIndexOfRow(rowIndex)
                }
            }
        }
    }
    
    func isAnyRowVisible() -> Bool {
        for rowIndex in 0..<_numberOfRows {
            if _rowVisible[rowIndex] { return true }
        }
        return false
    }
    
    func index(rowIndex: Int, colIndex: Int) -> Int {
        return (_numberOfCols * rowIndex) + colIndex
    }
    
    func col(index: Int) -> Int {
        if _numberOfCols > 0 {
            return index % _numberOfCols
        }
        return 0
    }
    
    func row(index: Int) -> Int {
        if _numberOfCols > 0 {
            return index / _numberOfCols
        }
        return 0
    }
    
    
    private var _allVisibleCellModels = [ThumbGridCellModel]()
    func getAllVisibleCellModels() -> [ThumbGridCellModel] {
        
        _allVisibleCellModels.removeAll(keepingCapacity: true)
        
        for index in 0..<_numberOfElements {
            if index < _cellVisible.count, _cellVisible[index] == true {
                let newCellModel = ThumbGridCellModel(index: index)
                _allVisibleCellModels.append(newCellModel)
            }
        }
        
        return _allVisibleCellModels
    }
}

// UI Helpers for cell frame
extension GridLayout {
    
    //x, y, width, height
    
    func getX(_ index: Int) -> CGFloat {
        
        var colIndex = col(index: index)
        if _cellXArray.count > 0 {
            colIndex = min(colIndex, _cellXArray.count - 1)
            colIndex = max(colIndex, 0)
            return CGFloat(_cellXArray[colIndex])
        }
        return 0
    }
    
    func getY(_ index: Int) -> CGFloat {
        var rowIndex = row(index: index)
        if _cellYArray.count > 0 {
            rowIndex = min(rowIndex, _cellYArray.count - 1)
            rowIndex = max(rowIndex, 0)
            return CGFloat(_cellYArray[rowIndex])
        }
        return 0
    }
    
    func getWidth(_ index: Int) -> CGFloat {
        var colIndex = col(index: index)
        if _cellWidthArray.count > 0 {
            colIndex = min(colIndex, _cellWidthArray.count - 1)
            colIndex = max(colIndex, 0)
            return CGFloat(_cellWidthArray[colIndex])
        }
        return 0
    }
    
    func getHeight(_ index: Int) -> CGFloat {
        CGFloat(cellHeight)
    }
}

// internal stuff for computing 2d grid stuff
extension GridLayout {
    
    private func numberOfCols() -> Int {
        
        if _numberOfElements <= 0 { return 0 }
        
        let availableWidth = _containerFrameWithoutSafeArea.width - CGFloat(cellPaddingLeft + cellPaddingRight)
        var result = 1
        var horizontalCount = 2
        
        while horizontalCount < 1024 {
            //consider the space between the cells...
            let totalSpaceWidth = CGFloat(cellSpacingH * (horizontalCount - 1))
            
            //how much space is available for the actual content of the cells
            let totalSpaceForCells = availableWidth - totalSpaceWidth
            let expectedCellWidth = totalSpaceForCells / CGFloat(horizontalCount)
            if expectedCellWidth < CGFloat(maximumCellWidth) {
                //we found a small enoguh size to be smaller than
                //the maximum size we allow our cells to be!
                break
            } else {
                //try more cells! (they will be smaller next time)
                result = horizontalCount
                horizontalCount += 1
            }
        }
        return result
    }
    
    private func numberOfRows() -> Int { // depends on number of cols being computed...
        
        if _numberOfCols > 0 {
            var result = _numberOfElements / _numberOfCols
            if (_numberOfElements % _numberOfCols) != 0 { result += 1 }
            return result
            // x x x
            // x x x
            // x
        }
        return 0
    }
    
    private func cellWidthArray() -> [Int] {
        var result = [Int]()
        
        if _numberOfCols <= 0 { return result }
        
        //keep track of how much space we used so far!!!
        var totalSpace = Int(_containerFrameWithoutSafeArea.width) - (cellPaddingLeft + cellPaddingRight)
        
        //eliminate the space between cells...
        if _numberOfCols > 1 {
            totalSpace -= (_numberOfCols - 1) * cellSpacingH
        }
        
        let baseWidth = totalSpace / _numberOfCols
        
        for _ in 0..<_numberOfCols {
            result.append(baseWidth)
            totalSpace -= baseWidth
        }
        
        // There might be a little bit of totalSpace left...
        
        while totalSpace > 0 {
            
            //evenly distribute the remaining space
            //among the widths of the cells...
            for colIndex in 0..<_numberOfCols {
                result[colIndex] += 1
                totalSpace -= 1
                if totalSpace <= 0 { break }
            }
        }
        
        return result
    }
    
}
