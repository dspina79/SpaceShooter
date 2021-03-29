//
//  Bundle-Decoding.swift
//  SpaceShooter
//
//  Created by Dave Spina on 3/28/21.
//

import Foundation

extension Bundle {
    func decode<T: Decodable>(_ type: T.Type, from file: String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("Failed to locate file in the bundle")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Could not load data.")
        }
        
        let decoder = JSONDecoder()
        
        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("Failed to decode data.")
        }
        
        return loaded
    }
}
