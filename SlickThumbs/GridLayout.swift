//
//  GridLayout.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/15/22.
//

import SwiftUI

protocol ThumbGridConforming: Identifiable {
    var index: Int { get }
}

func rangesOverlap(_ start1: Int, _ end1: Int,
                   _ start2: Int, _ end2: Int) -> Bool {
    return start1 <= end2 && start2 <= end1
}

protocol GridLayoutDelegate: AnyObject {
    func cellsDidEnterScreen(_ startIndex: Int, _ endIndex: Int)
    func cellsDidLeaveScreen(_ startIndex: Int, _ endIndex: Int)
}

class GridLayout {
    
    struct ThumbGridCellModel: ThumbGridConforming {
        let index: Int
        var id: Int {
            return index
        }
    }
    
    weak var delegate: GridLayoutDelegate?
    
    private(set) var width: CGFloat = 256
    private(set) var height: CGFloat = 256
    
    private let maximumCellWidth = 100
    private let cellHeight = 100
    
    private let cellPaddingLeft = 24
    private let cellPaddingRight = 24
    private let cellSpacingH = 9
    
    private let cellPaddingTop = 24
    private let cellPaddingBottom = 128
    private let cellSpacingV = 9
    
    private var _scrollContentFrame = CGRect.zero
    private var _containerFrameWithoutSafeArea = CGRect.zero
    private var _containerFrame = CGRect.zero // expanded to include safe area
    
    private var _numberOfElements = 0
    private var _numberOfRows = 0
    private var _numberOfCols = 0
    private var _cellWidthArray = [Int]()
    private var _cellXArray = [Int]()
    private var _cellYArray = [Int]()
    
    private var _rowVisible = [Bool]()
    private var _cellVisible = [Bool]()
    
    private var _firstIndexOnScreen = 0
    private var _lastIndexOnScreen = 0
    
    func clear() {
        _numberOfElements = 0
        _numberOfRows = 0
        _numberOfCols = 0
        _cellWidthArray = [Int]()
        _cellXArray = [Int]()
        _cellYArray = [Int]()
        
        _rowVisible = [Bool]()
        _cellVisible = [Bool]()
        
        _firstIndexOnScreen = 0
        _lastIndexOnScreen = 0
    }
    
    func registerList(_ containerGeometry: GeometryProxy, _ numberOfElements: Int) -> Bool {
        
        var newContainerFrame = containerGeometry.frame(in: .global)
        _containerFrameWithoutSafeArea = newContainerFrame
        
        // factor in the safe area!!!
        let left = containerGeometry.safeAreaInsets.leading
        let right = containerGeometry.safeAreaInsets.trailing
        let top = containerGeometry.safeAreaInsets.top
        let bottom = containerGeometry.safeAreaInsets.bottom
        
        newContainerFrame = CGRect(x: newContainerFrame.minX - left,
                                   y: newContainerFrame.minY - top,
                                   width: newContainerFrame.width + left + right,
                                   height: newContainerFrame.height + top + bottom)
        
        if (numberOfElements != _numberOfElements) || (newContainerFrame != _containerFrame) {
            clear()
            _numberOfElements = numberOfElements
            _containerFrame = newContainerFrame
            computeSizeAndPopulateGrid()
            return true
        }
        
        return false
    }
    
    func registerContent(_ scrollContentGeometry: GeometryProxy) {
        let scrollContentFrame = scrollContentGeometry.frame(in: .global)
        _scrollContentFrame = scrollContentFrame
        handleScrollContentDidChangePosition(_containerFrame, _scrollContentFrame)
    }
    
    private static let onScreenPadding = -64
    private func handleScrollContentDidChangePosition(_ containerFrame: CGRect, _ scrollContentFrame: CGRect) {
        
        let contentTop = Int(containerFrame.minY - scrollContentFrame.minY) - Self.onScreenPadding
        let contentBottom = Int(containerFrame.maxY - scrollContentFrame.minY) + Self.onScreenPadding
        
        var shouldUpdateFirstAndLastIndex = false
        for rowIndex in 0..<_numberOfRows {
            
            let cellTop = _cellYArray[rowIndex]
            let cellBottom = cellTop + cellHeight
            let overlap = rangesOverlap(contentTop, contentBottom,
                                        cellTop, cellBottom)
            
            let cellStartIndex = index(rowIndex: rowIndex, colIndex: 0)
            let cellEndIndex = index(rowIndex: rowIndex, colIndex: _numberOfCols - 1)
            
            if overlap {
                if _rowVisible[rowIndex] == false {
                    _rowVisible[rowIndex] = true
                    
                    for colIndex in 0..<_numberOfCols {
                        let cellIndex = index(rowIndex: rowIndex, colIndex: colIndex)
                        _cellVisible[cellIndex] = true
                    }
                    
                    delegate?.cellsDidEnterScreen(cellStartIndex, cellEndIndex)
                    shouldUpdateFirstAndLastIndex = true
                }
            } else {
                
                if _rowVisible[rowIndex] == true {
                    _rowVisible[rowIndex] = false
                    
                    for colIndex in 0..<_numberOfCols {
                        let cellIndex = index(rowIndex: rowIndex, colIndex: colIndex)
                        _cellVisible[cellIndex] = false
                    }
                    
                    delegate?.cellsDidLeaveScreen(cellStartIndex, cellEndIndex)
                    shouldUpdateFirstAndLastIndex = true
                }
            }
        }
        if shouldUpdateFirstAndLastIndex {
            refreshFirstAndLastIndex()
        }
    }
    
    func computeSizeAndPopulateGrid() {
        _numberOfCols = numberOfCols()
        _numberOfRows = numberOfRows() // this depends on _numberOfCols
        _cellWidthArray = cellWidthArray() // this depends on _numberOfCols
        
        width = round(_containerFrameWithoutSafeArea.width)
        height = CGFloat((_numberOfRows * cellHeight) + (cellPaddingTop + cellPaddingBottom))
        if _numberOfRows > 1 {
            height += CGFloat((_numberOfRows - 1) * cellSpacingV)
        }
        
        buildXArray()
        buildYArray()
        buildVisibilityArrays()
    }
    
    private func buildXArray() {
        if _cellXArray.count != _numberOfCols {
            _cellXArray = [Int](repeating: 0, count: _numberOfCols)
        }
        
        var cellX = cellPaddingLeft
        var indexX = 0
        while indexX < _numberOfCols {
            _cellXArray[indexX] = cellX
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
            cellY += cellHeight + cellSpacingV
            indexY += 1
        }
    }
    
    private func buildVisibilityArrays() {
        let numberOfCells = _numberOfCols * _numberOfRows
        if _cellVisible.count != numberOfCells {
            _cellVisible = [Bool](repeating: false, count: numberOfCells)
        }
        
        if _rowVisible.count != _numberOfRows {
            _rowVisible = [Bool](repeating: false, count: _numberOfRows)
        }
    }
    
    func isAnyRowVisible() -> Bool {
        for rowIndex in 0..<_numberOfRows {
            if _rowVisible[rowIndex] {
                return true
            }
        }
        return false
    }
    
    func refreshFirstAndLastIndex() {
        
        _firstIndexOnScreen = 0
        _lastIndexOnScreen = 0
        
        var found = false
        for rowIndex in 0..<_numberOfRows {
            if _rowVisible[rowIndex] {
                if found == false {
                    found = true
                    _firstIndexOnScreen = firstIndexOnRow(rowIndex)
                    _lastIndexOnScreen = lastIndexOnRow(rowIndex)
                } else {
                    _lastIndexOnScreen = lastIndexOnRow(rowIndex)
                }
            }
        }
    }
    
    func index(rowIndex: Int, colIndex: Int) -> Int {
        return rowIndex * _numberOfCols + colIndex
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
    
    private func firstIndexOnRow(_ rowIndex: Int) -> Int {
        return _numberOfCols * rowIndex
    }
    
    private func lastIndexOnRow(_ rowIndex: Int) -> Int {
        return (_numberOfCols * rowIndex) + (_numberOfCols - 1)
    }
    
    func firstIndexOnScreen() -> Int {
        return _firstIndexOnScreen
    }
    
    func lastIndexOnScreen() -> Int {
        return _lastIndexOnScreen
    }
    
    private var _allVisibleCellModels = [ThumbGridCellModel]()
    func getAllVisibleCellModels() -> [ThumbGridCellModel] {
        
        _allVisibleCellModels.removeAll(keepingCapacity: true)
        for index in 0..<_numberOfElements {
            if _cellVisible[index] {
                _allVisibleCellModels.append(ThumbGridCellModel(index: index))
            }
        }
        
        return _allVisibleCellModels
    }
    
    
}

extension GridLayout {
    func getX(_ index: Int) -> CGFloat {
        let colIndex = col(index: index)
        if colIndex < 0 {
            if _cellXArray.count > 0 {
                return CGFloat(_cellXArray[0])
            }
            return 0
        }
        if colIndex >= _cellXArray.count {
            if _cellXArray.count > 0 {
                return CGFloat(_cellXArray[_cellXArray.count - 1])
            }
            return 0
        }
        
        return CGFloat(_cellXArray[colIndex])
    }
    
    func getY(_ index: Int) -> CGFloat {
        let rowIndex = row(index: index)
        if rowIndex < 0 {
            if _cellYArray.count > 0 {
                return CGFloat(_cellYArray[0])
            }
            return 0
        }
        if rowIndex >= _cellYArray.count {
            if _cellYArray.count > 0 {
                return CGFloat(_cellYArray[_cellYArray.count - 1])
            }
            return 0
        }
        
        return CGFloat(_cellYArray[rowIndex])
    }
    
    func getWidth(_ index: Int) -> CGFloat {
        let colIndex = col(index: index)
        if colIndex < 0 {
            if _cellWidthArray.count > 0 {
                return CGFloat(_cellWidthArray[0])
            }
            return 0
        }
        if colIndex >= _cellWidthArray.count {
            if _cellWidthArray.count > 0 {
                return CGFloat(_cellWidthArray[_cellWidthArray.count - 1])
            }
            return 0
        }
        return CGFloat(_cellWidthArray[colIndex])
    }
    
    func getHeight(_ index: Int) -> CGFloat {
        return CGFloat(cellHeight)
    }
}

extension GridLayout {
    
    private func numberOfCols() -> Int {
        
        let screenWidth = _containerFrameWithoutSafeArea.width - CGFloat(cellPaddingLeft + cellPaddingRight)
        var result = 1
        
        var horizontalCount = 2
        while true {
            
            let totalSpacingWidth = CGFloat((horizontalCount - 1) * cellSpacingH)
            let totalSpaceForCells = screenWidth - totalSpacingWidth
            let expectedCellWidth = totalSpaceForCells / CGFloat(horizontalCount)
            
            if expectedCellWidth < CGFloat(maximumCellWidth) {
                break
            } else {
                result = horizontalCount
                horizontalCount += 1
            }
        }
        
        return result
    }
    
    private func numberOfRows() -> Int {
        var result = _numberOfElements / _numberOfCols
        if (_numberOfElements % _numberOfCols) != 0 { result += 1 }
        return result
    }
    
    private func cellWidthArray() -> [Int] {
        
        var result = [Int]()
        
        var totalSpace = Int(_containerFrameWithoutSafeArea.width)
        totalSpace -= cellPaddingLeft
        totalSpace -= cellPaddingRight
        
        if _numberOfCols > 1 {
            totalSpace -= ((_numberOfCols - 1) * cellSpacingH)
        }
        
        let baseWidth = totalSpace / _numberOfCols
        for _ in 0..<_numberOfCols {
            result.append(baseWidth)
            totalSpace -= baseWidth
        }
        
        //we might have a little bit of space left over
        //evenly distribute the remaining space
        
        while totalSpace > 0 {
            for i in 0..<_numberOfCols {
                result[i] += 1
                totalSpace -= 1
                if totalSpace <= 0 {
                    break
                }
            }
        }
        
        return result
    }
    
}
