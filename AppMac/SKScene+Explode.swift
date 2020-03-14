// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit

extension SKScene {
	func explode(at point: CGPoint, for duration: TimeInterval, color: SKColor = SKColor.red, zPosition: CGFloat = 0, completion block: @escaping () -> Swift.Void) {
		if let explosion = SKEmitterNode(fileNamed: "Explosion") {
			explosion.particlePosition = point
			explosion.zPosition = zPosition
			explosion.particleColorSequence = SKKeyframeSequence(keyframeValues: [color], times: [1])
			explosion.particleLifetime = CGFloat(duration)
			self.addChild(explosion)
			// Don't forget to remove the emitter node after the explosion
			run(SKAction.wait(forDuration: duration), completion: {
				explosion.removeFromParent()
				block()
			})
		}
	}
}
