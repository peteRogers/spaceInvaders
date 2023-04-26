//
//  StartView.swift
//  spaceInvaders
//
//  Created by Peter Rogers on 25/04/2023.
//

import Foundation
import UIKit


class StartView: UIView {

    weak var delegate: StartViewDelegate?

    let button = UIButton(type: .system)
     
     override init(frame: CGRect) {
         super.init(frame: frame)
         
         // Set up the button
         button.setTitle("START", for: .normal)
         button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
         button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 50)
         
         // Add the button to the view
         addSubview(button)
         
         // Set up constraints for the button
         button.translatesAutoresizingMaskIntoConstraints = false
         button.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
         button.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
     }
     
     required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
     
     @objc func buttonTapped() {
         delegate?.startViewDidSendMessage("Hello from CustomView!")
         self.alpha = 0
     }
    
    func activate(){
        self.alpha = 1
    }
    
   
}
