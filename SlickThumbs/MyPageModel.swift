//
//  MyPageModel.swift
//  SlickThumbs
//
//  Created by Nick Raptis on 9/15/22.
//

import Foundation

enum ThumbError: Error {
    case any
}

class MyPageModel {
    
    private var list = [ThumbModel?]()
    
    private let allEmojis = "🚙🤗🦊🪗🪕🎻🐻‍❄️🚘🚕🏈⚾️🙊🙉🌲😄😁😆🚖🏎🚚🛻🎾🏐🥏🏓🥁😋🛩🚁🦓🦍🦧😌😛😎🥸🤩🦬🐃🦙🐐☹️😣😖😭🦣🦏🐪⛴🚢🚂🚝🚅😟😕🙁😤🎺🐎🐖🐏🐑🐶🐱🐭🍀🍁🍄🌾☁️🌦🌧⛈😅😂🤣🥲☺️🚛🚐🚓🥺😢🦎🦖🦕🥰😘😗😙🛸🚲☔️🐻🐼🐘🦛😍😚😠😡🤯💦🌊☂️🚤🛥🛳🚆🦇🐢🐍🐅🐆🛫🛬🏍🛶⛵️😳🥶😥🚗😓🐨🐯🦅🦉🐫🦒🙃😉🥳😏🐓🐁❄️💨💧🐰🦁🐮🥌🏂😔🏀⚽️🎼🎤🎹🪘🐥🐣🐂🐄🐵🙈🤭🤫🥀🌨🌫🦮🐈🦤😯😧✈️🚊🚔😝😜🤪🤨🐀🐒🦆🧐🤓🕊🦝🦨🦡😫😩🚉😴🤮🌺🌸😬🙄🥱🚀🚇🛺😞🤥😷🦌🐕🌴🌿☘️☀️🌤⛅️🌥😀😃🐩🦢🥅⛷🎳🚑🚒🚜🌷🌹🌼😇🙂🤧🦘🦩🦫🦦😊🤒🤠🐹🐷🐸🐲🌩🌪🦙🐐🦥🐿🦔💐🌻⛳️"
    
    func clear() {
        list.removeAll()
    }
    
    var totalExpectedCount: Int {
        // this should come from web service
        return allEmojis.count
    }
    
    func thumbModel(at index: Int) -> ThumbModel? {
        if index >= 0 && index < list.count {
            return list[index]
        }
        return nil
    }
    
    private func simulateRangeFetchComplete(at index: Int, withCount count: Int) {
        
        let emojisArray = Array(allEmojis)
        let newCapacity = index + count
        
        while list.count < newCapacity {
            list.append(nil)
        }
        
        var index = index
        while index < newCapacity {
            if index >= 0 && index < emojisArray.count {
                // spawn a new model
                let newModel = ThumbModel(index: index,
                                          image: String(emojisArray[index]))
                list[index] = newModel
            }
            index += 1
        }
    }
    
    func fetch(at index: Int, withCount count: Int, completion: @escaping (Result<Void, ThumbError>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: TimeInterval.random(in: 0.25...2.5))
            DispatchQueue.main.async {
                
                self.simulateRangeFetchComplete(at: index, withCount: count)
                completion(.success(()))
            }
        }
    }
    
    
}
