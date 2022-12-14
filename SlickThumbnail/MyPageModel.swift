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
    
    private let allEmojis = "🚙🤗🦊🪗🪕🎻🐻‍❄️🚘🚕🏈⚾️🙊🙉🌲😄😁😆🚖🏎🚚🛻🎾🏐🥏🏓🥁😋🛩🚁🦓🦍🦧😌😛😎🥸🤩🦬🐃🦙🐐☹️😣😖😭🦣🦏🐪⛴🚢🚂🚝🚅😟😕🙁😤🎺🐎🐖🐏🐑🐶🐱🐭🍀🍁🍄🌾☁️🌦🌧⛈😅😂🤣🥲☺️🚛🚐🚓🥺😢🦎🦖🦕🥰😘😗😙🛸🚲☔️🐻🐼🐘🦛😍😚😠😡🤯💦🌊☂️🚤🛥🛳🚆🦇🐢🐍🐅🐆🛫🛬🏍🛶⛵️😳🥶😥🚗😓🐨🐯🦅🦉🐫🦒🙃😉🥳😏🐓🐁❄️💨💧🐰🦁🐮🥌🏂😔🏀⚽️🎼🎤🎹🪘🐥🐣🐂🐄🐵🙈🤭🤫🥀🌨🌫🦮🐈🦤😯😧✈️🚊🚔😝😜🤪🤨🐀🐒🦆🧐🤓🕊🦝🦨🦡😫😩🚉😴🤮🌺🌸😬🙄🥱🚀🚇🛺😞🤥😷🦌🐕🌴🌿☘️☀️🌤⛅️🌥😀😃🐩🦢🥅⛷🎳🚑🚒🚜🌷🌹🌼😇🙂🤧🦘🦩🦫🦦😊🤒🤠🐹🐷🐸🐲🌩🌪🦙🐐🦥🐿🦔💐🌻⛳️"
    
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
