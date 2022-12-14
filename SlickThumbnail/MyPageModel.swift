//
//  MyPageModel.swift
//  SlickThumbnail
//
//  Created by Nick Raptis on 9/23/22.
//

import Foundation

enum ServiceError: Error {
    case any
}

class MyPageModel {
    
    private let allEmojis = "๐๐ค๐ฆ๐ช๐ช๐ป๐ปโโ๏ธ๐๐๐โพ๏ธ๐๐๐ฒ๐๐๐๐๐๐๐ป๐พ๐๐ฅ๐๐ฅ๐๐ฉ๐๐ฆ๐ฆ๐ฆง๐๐๐๐ฅธ๐คฉ๐ฆฌ๐๐ฆ๐โน๏ธ๐ฃ๐๐ญ๐ฆฃ๐ฆ๐ชโด๐ข๐๐๐๐๐๐๐ค๐บ๐๐๐๐๐ถ๐ฑ๐ญ๐๐๐๐พโ๏ธ๐ฆ๐งโ๐๐๐คฃ๐ฅฒโบ๏ธ๐๐๐๐ฅบ๐ข๐ฆ๐ฆ๐ฆ๐ฅฐ๐๐๐๐ธ๐ฒโ๏ธ๐ป๐ผ๐๐ฆ๐๐๐ ๐ก๐คฏ๐ฆ๐โ๏ธ๐ค๐ฅ๐ณ๐๐ฆ๐ข๐๐๐๐ซ๐ฌ๐๐ถโต๏ธ๐ณ๐ฅถ๐ฅ๐๐๐จ๐ฏ๐ฆ๐ฆ๐ซ๐ฆ๐๐๐ฅณ๐๐๐โ๏ธ๐จ๐ง๐ฐ๐ฆ๐ฎ๐ฅ๐๐๐โฝ๏ธ๐ผ๐ค๐น๐ช๐ฅ๐ฃ๐๐๐ต๐๐คญ๐คซ๐ฅ๐จ๐ซ๐ฆฎ๐๐ฆค๐ฏ๐งโ๏ธ๐๐๐๐๐คช๐คจ๐๐๐ฆ๐ง๐ค๐๐ฆ๐ฆจ๐ฆก๐ซ๐ฉ๐๐ด๐คฎ๐บ๐ธ๐ฌ๐๐ฅฑ๐๐๐บ๐๐คฅ๐ท๐ฆ๐๐ด๐ฟโ๏ธโ๏ธ๐คโ๏ธ๐ฅ๐๐๐ฉ๐ฆข๐ฅโท๐ณ๐๐๐๐ท๐น๐ผ๐๐๐คง๐ฆ๐ฆฉ๐ฆซ๐ฆฆ๐๐ค๐ค ๐น๐ท๐ธ๐ฒ๐ฉ๐ช๐ฆ๐๐ฆฅ๐ฟ๐ฆ๐๐ปโณ๏ธ"
    
    private var thumbModelList = [ThumbModel?]()
    
    func thumbModel(at index: Int) -> ThumbModel? {
        if index >= 0 && index < thumbModelList.count {
            return thumbModelList[index]
        }
        return nil
    }
    
    func clear() {
        thumbModelList.removeAll()
    }
    
    var totalExpectedCount: Int {
        return 118
    }
    
    private func simulateRangeFetchComplete(at index: Int, withCount count: Int) {
        let newCapacity = index + count
        
        if newCapacity <= 0 { return }
        guard count > 0 else { return }
        guard index < allEmojis.count else { return }
        if count > 8192 { return }
        
        let emojisArray = Array(allEmojis)
        
        while thumbModelList.count < newCapacity {
            thumbModelList.append(nil)
        }
        
        var index = index
        while index < newCapacity {
            if index >= 0 && index < emojisArray.count, thumbModelList[index] == nil {
                let newModel = ThumbModel(index: index, image: String(emojisArray[index]))
                thumbModelList[index] = newModel
            }
            index += 1
        }
    }
    
    func fetch(at index: Int, withCount count: Int, completion: @escaping ( Result<Void, ServiceError> ) -> Void) {
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: TimeInterval.random(in: 0.25...2.5))
            DispatchQueue.main.async {
                self.simulateRangeFetchComplete(at: index, withCount: count)
                completion(.success( () ))
            }
        }
        
    }
    
}
