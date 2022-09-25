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
    
    var totalExpectedCount: Int {
        return allEmojis.count
    }
    
    func clear() {
        thumbModelList.removeAll()
    }
    
    func thumModel(_ index: Int) -> ThumbModel? {
        if index >= 0 && index < thumbModelList.count {
            return thumbModelList[index]
        }
        return nil
    }
    
    private func simulateRangeFetchComplete(at index: Int, withCount count: Int) {
        
        let emojisArray = Array(allEmojis)
        let capacity = index + count
        
        if capacity <= 0 { return }
        if count > 8192 { return }
        
        if thumbModelList.capacity < capacity {
            thumbModelList.reserveCapacity(capacity)
        }
        while thumbModelList.count < capacity {
            thumbModelList.append(nil)
        }
        
        var index = index
        while index < capacity {
            if index >= 0 && index < totalExpectedCount, thumbModelList[index] == nil {
                let newModel = ThumbModel(index: index, emoji: String(emojisArray[index]))
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
