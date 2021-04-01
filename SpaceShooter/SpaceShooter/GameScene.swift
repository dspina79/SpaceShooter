//
//  GameScene.swift
//  SpaceShooter
//
//  Created by Dave Spina on 3/26/21.
//

import SpriteKit

enum CollisionType: UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}

class GameScene: SKScene {
    let player = SKSpriteNode(imageNamed: "player")
    
    let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")
 
    var isPlayerAlive = true
    var waveNumber = 0
    var levelNumber = 0
    
    let positions = Array(stride(from: -320, through: 320, by: 80))
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        if let particles = SKEmitterNode(fileNamed: "Starfield") {
            particles.position = CGPoint(x: 1080, y: 0)
            particles.advanceSimulationTime(60)
            particles.zPosition = -1;
            addChild(particles)
        }
        
        player.name = "Player";
        player.position.x = frame.minX + 75;
        player.zPosition = 1;
        addChild(player)
    
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = false
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        for child in children{
            if child.frame.maxX < 0 {
                if !frame.intersects(child.frame) {
                    child.removeFromParent()
                }
            }
        }
        
        let activeEnemies = children.compactMap{$0 as? EnemyNode}
        if activeEnemies.isEmpty {
            createWave()
        }
        
        for enemy in activeEnemies {
            guard frame.intersects(enemy.frame) else {
                continue
            }
            
            if enemy.lastFiredTime + 1 < currentTime {
                enemy.lastFiredTime = currentTime
                
                if Int.random(in: 0...6) == 0 {
                    enemy.fire()
                }
            }
        }
    }
    
    func createWave() {
        guard isPlayerAlive else { return }
        
        if waveNumber == waves.count {
            levelNumber += 1
            waveNumber = 0
        }
        
        let wave = waves[waveNumber]
        waveNumber += 1
        
        let minimumEnemtyType = min(enemyTypes.count, levelNumber + 1)
        let enemyType = Int.random(in: 0..<minimumEnemtyType)
        let enemyOffset: CGFloat = 100
        let enemyStartX = 600
        
        if wave.enemies.isEmpty {
            //random wave
            for (index, position) in positions.shuffled().enumerated() {
                let enemy = EnemyNode(enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: position), xOffset: enemyOffset * CGFloat(index * 3), movingStraight: true)
                addChild(enemy)
            }
        } else {
            for enemy in wave.enemies {
                let node = EnemyNode(enemyTypes[enemyType], startPosition: CGPoint(x: enemyStartX, y: positions[enemy.position]), xOffset: enemyOffset * enemy.xOffset, movingStraight: enemy.moveStraight)
                addChild(node)
            }
        }
    }
    
}
