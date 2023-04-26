//
//  ExplosionParticle.swift
//  spaceInvaders
//
//  Created by Peter Rogers on 26/04/2023.
//

import Foundation
import UIKit


class ExplosionParticle: UIView {
    var origFrame:CGRect?
    override init(frame: CGRect) {
        super.init(frame: frame)
        print(frame.debugDescription)
        origFrame = frame
       // self.setNeedsDisplay()
        
        let starPath = UIBezierPath()
        let center = CGPoint(x: frame.width/2, y: frame.height/2)
        let numberOfPoints = Int.random(in: 2...5)
        let angle = 2 * .pi / Double(numberOfPoints)
        let radius = frame.width / 2
        let startPoint = CGPoint(x: center.x, y: center.y - radius)
        starPath.move(to: startPoint)
        for i in 1..<numberOfPoints {
          let point = CGPoint(x: center.x + CGFloat(sin(Double(i) * angle) * Double(radius)), y: center.y - CGFloat(cos(Double(i) * angle) * Double(radius)))
              starPath.addLine(to: point)
        }
        starPath.close()

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = starPath.cgPath
        shapeLayer.fillColor = UIColor.yellow.cgColor
       // shapeLayer.strokeColor = UIColor.red.cgColor
       // shapeLayer.lineWidth = 2.

        self.layer.addSublayer(shapeLayer)

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
//    override func draw(_ rect: CGRect) {
//        let path = UIBezierPath()
//        print(rect.debugDescription)
//          let center = CGPoint(x: rect.midX, y: rect.midY)
//          let radius = min(rect.width, rect.height) / 2
//          let pointsOnStar = 5
//          let angle = CGFloat(4 * Double.pi / Double(pointsOnStar * 2))
//          let innerRadius = radius / 2
//
//          path.move(to: CGPoint(x: center.x, y: center.y - radius))
//
//          for i in 1...pointsOnStar {
//              let x = center.x - sin(CGFloat(i) * angle) * radius
//              let y = center.y - cos(CGFloat(i) * angle) * radius
//              path.addLine(to: CGPoint(x: x, y: y))
//
//              let x2 = center.x - sin(CGFloat(i) * angle - angle / 2) * innerRadius
//              let y2 = center.y - cos(CGFloat(i) * angle - angle / 2) * innerRadius
//              path.addLine(to: CGPoint(x: x2, y: y2))
//          }
//
//          path.close()
//          UIColor.yellow.setFill()
//          path.fill()
//       }
}
