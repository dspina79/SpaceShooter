//
//  GameScene.swift
//  SpaceShooter
//
//  Created by Dave Spina on 3/26/21.
//

import CoreMotion
import SpriteKit

enum CollisionType: UInt32 {
    case player = 1
    case playerWeapon = 2
    case enemy = 4
    case enemyWeapon = 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var score: Int = 0
    let motionManager = CMMotionManager()
    let player = SKSpriteNode(imageNamed: "player")
    
    let waves = Bundle.main.decode([Wave].self, from: "waves.json")
    let enemyTypes = Bundle.main.decode([EnemyType].self, from: "enemy-types.json")
 
    var isPlayerAlive = true
    var waveNumber = 0
    var levelNumber = 0
    var playerShields = 10
    
    let positions = Array(stride(from: -320, through: 320, by: 80))
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        if let particles = SKEmitterNode(fileNamed: "Starfield") {
            particles.position = CGPoint(x: 1080, y: 0)
            particles.advanceSimulationTime(60)
            particles.zPosition = -1;
            addChild(particles)
        }
   
        let scoreNode = SKLabelNode(text: "Score: \(self.score)")
        scoreNode.name = "score"
        scoreNode.zPosition = 100
        scoreNode.position = CGPoint(x: frame.maxX - 500, y: frame.minY + 20)
        scoreNode.fontColor = .white
        scoreNode.fontSize = CGFloat(20)
        addChild(scoreNode)
        
        player.name = "Player";
        player.position.x = frame.minX + 75;
        player.zPosition = 1;
        addChild(player)
    
        player.physicsBody = SKPhysicsBody(texture: player.texture!, size: player.texture!.size())
        player.physicsBody?.categoryBitMask = CollisionType.player.rawValue
        player.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        player.physicsBody?.isDynamic = false
        
        motionManager.startAccelerometerUpdates()
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if let accelerometerData = motionManager.accelerometerData {
            player.position.y = CGFloat(accelerometerData.acceleration.x * 50)
        }
        
        if player.position.y < frame.minY {
            player.position.y = frame.minY
        } else if player.position.y > frame.maxY {
            player.position.y = frame.maxY
        }
        
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
    
    override func sceneDidLoad() {
        
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isPlayerAlive else { return }
        
        let shot = SKSpriteNode(imageNamed: "playerWeapon")
        shot.position = player.position
        shot.name = "playerWeapon"
        shot.physicsBody = SKPhysicsBody(rectangleOf: shot.size)
        shot.physicsBody?.categoryBitMask = CollisionType.playerWeapon.rawValue
        shot.physicsBody?.collisionBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        shot.physicsBody?.contactTestBitMask = CollisionType.enemy.rawValue | CollisionType.enemyWeapon.rawValue
        
        addChild(shot)
        
        let movement = SKAction.move(to: CGPoint(x: 1900, y: shot.position.y), duration: 5)
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        shot.run(sequence)
    }
    
    func updateScore() {
        if let scoreNode = self.childNode(withName: "score") as? SKLabelNode {
            scoreNode.text = "Score: \(self.score)"
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        let sortedNodes = [nodeA, nodeB].sorted{
            $0.name ?? "" < $1.name ?? ""
        } // this will be sorted into enemy, enemyWeapon, player, playerWeapon
        
        let firstNode = sortedNodes[0]
        let secondNode = sortedNodes[1]
        
        if secondNode.name == "player" {
            guard isPlayerAlive else { return }
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = firstNode.position
                addChild(explosion)
            }
            
            playerShields -= 1
            if playerShields == 0 {
                gameOver()
                secondNode.removeFromParent()
            }
            
            firstNode.removeFromParent()
        } else if let enemy = firstNode as? EnemyNode {
            enemy.shields -= 1
            if enemy.shields == 0 {
                if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                    explosion.position = enemy.position
                    addChild(explosion)
                }
                score += (10 ^ enemy.type.shields)
                updateScore()
                firstNode.removeFromParent()
                
            }
            
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = enemy.position
                addChild(explosion)
            }
            
            secondNode.removeFromParent()
        } else {
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                explosion.position = secondNode.position
                addChild(explosion)
            }
            
            firstNode.removeFromParent()
            secondNode.removeFromParent()
        }
        
        
    }
    
    func gameOver() {
        isPlayerAlive = false
        
        if let explosion = SKEmitterNode(fileNamed: "Explosion") {
            explosion.position = player.position
            addChild(explosion)
        }
        
        let gameOver = SKSpriteNode(imageNamed: "gameOver")
        
        addChild(gameOver) // centered by default
    }
    
}
