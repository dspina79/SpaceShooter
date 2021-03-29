//
//  Wave.swift
//  SpaceShooter
//
//  Created by Dave Spina on 3/28/21.
//

import SpriteKit

struct Wave: Codable {
    struct WaveEnemy: Codable {
        var position: Int
        var xOffset: CGFloat
        var moveStraight: Bool
    }
    var name: String
    var enemies: [WaveEnemy]
}
