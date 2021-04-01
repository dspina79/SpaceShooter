//
//  EnemyNode.swift
//  SpaceShooter
//
//  Created by Dave Spina on 3/28/21.
//

import SpriteKit

class EnemyNode: SKSpriteNode {
    var type: EnemyType
    var lastFiredTime = Double.zero
    var shields: Int
    
    init(_ type: EnemyType, startPosition: CGPoint, xOffset: CGFloat, movingStraight: Bool) {
        self.type = type
        self.shields = type.shields
        let texture = SKTexture(imageNamed: type.name)
    
        super.init(texture: texture, color: .white, size: texture.size())
        self.physicsBody = SKPhysicsBody(texture: texture, size: texture.size())
        self.physicsBody?.categoryBitMask = CollisionType.enemy.rawValue
        self.physicsBody?.collisionBitMask = CollisionType.player.rawValue | CollisionType.playerWeapon.rawValue
        self.physicsBody?.contactTestBitMask = CollisionType.player.rawValue | CollisionType.playerWeapon.rawValue
        
        self.name = "Enemy"
        self.position = CGPoint(x: startPosition.x + xOffset, y: startPosition.y)
        self.configureMovement(movingStraight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not doing this!")
    }
    
    func configureMovement(_ movingStraight: Bool) {
        let path = UIBezierPath()
        path.move(to: CGPoint.zero)
        if (movingStraight) {
            path.addLine(to: CGPoint(x: -10000, y: .zero))
        } else {
            path.addCurve(to: CGPoint(x: -3500, y: .zero), controlPoint1: CGPoint(x: 0, y: -position.y * 4), controlPoint2: CGPoint(x: -10000, y: -position.y))
        }
        
        let movement = SKAction.follow(path.cgPath, asOffset: true, orientToPath: true, speed: self.type.speed)
        let sequence = SKAction.sequence([movement, .removeFromParent()])
        run(sequence)
    }
    
    func fire() {
        let weaponType = "\(type.name)Weapon"
        let weapon = SKSpriteNode(imageNamed: weaponType)
        weapon.name = "enemyWeapon"
        weapon.position = position
        weapon.zRotation = zRotation
        
        parent?.addChild(weapon)
        // add the child before adding the push
        weapon.physicsBody = SKPhysicsBody(rectangleOf: weapon.size)
        weapon.physicsBody?.categoryBitMask = CollisionType.enemyWeapon.rawValue
        weapon.physicsBody?.collisionBitMask = CollisionType.player.rawValue
        weapon.physicsBody?.mass = 0.001
        
        let speed: CGFloat = 1
        let adjustedRoation = zRotation + (CGFloat.pi / 2)
        let deltaX = speed * cos(adjustedRoation)
        let deltaY = speed * sin(adjustedRoation)
        
        weapon.physicsBody?.applyImpulse(CGVector(dx: deltaX, dy: deltaY))
    }
}
