//
//  EnemyType.swift
//  SpaceShooter
//
//  Created by Dave Spina on 3/28/21.
//

import SpriteKit

struct EnemyType: Codable {
    var name: String
    var shields: Int
    var speed: CGFloat
    var powerUpChance: Int
}
