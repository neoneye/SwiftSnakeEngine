// MIT license. Copyright (c) 2020 Simon Strandgaard. All rights reserved.
import SpriteKit

extension SKSpriteNode {

	private static let fillColor = SKColor(red: 0.75, green: 0.0, blue: 0.0, alpha: 0.15)

	func addPulseEffect(rectOf size: CGFloat, backgroundColor: SKColor = fillColor) {
		let circle = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 20)
		circle.fillColor = backgroundColor
		circle.lineWidth = 0.0
		circle.position = CGPoint(x: 0, y: 0)
		self.addChild(circle)
		let scale = SKAction.scale(to: 3.0, duration: 1.0)
		let fadeOut = SKAction.fadeOut(withDuration: 0.75)
		let pulseGroup = SKAction.sequence([scale, fadeOut])
		let repeatSequence = SKAction.repeatForever(pulseGroup)
		circle.run(repeatSequence)
	}

	func repeatPulseEffectForEver(rectOf size: CGFloat) {
		let _ = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { (timer) in
			self.addPulseEffect(rectOf: size)
		}
	}
}
