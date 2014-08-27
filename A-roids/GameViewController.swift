//
//  GameViewController.swift
//  A-roids
//
//  Created by David Reed on 7/15/14.
//  Copyright (c) 2014 Dave's App Dungeon. All rights reserved.
//

import UIKit
import SpriteKit

var thrusting =  false
var fire_bullet = false
var game_paused = false
var restart_game = false
var scene = SKScene()
var screenWidth: CGFloat = 0.0
var screenHeight: CGFloat = 0.0
var reset_highscore = false


extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        
        let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks")
        
        var sceneData = NSData.dataWithContentsOfFile(path, options: .DataReadingMappedIfSafe, error: nil)
        var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
        
        archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
        let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
        archiver.finishDecoding()
        return scene
    }
}



class GameViewController: UIViewController {
    
   

    override func viewDidLoad() {
        super.viewDidLoad()

        if let thescene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            scene = thescene
           
            let skView = self.view as SKView
            //skView.showsFPS = true
            //skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            
            skView.presentScene(scene)
        }
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        screenWidth = self.view.bounds.size.width
        screenHeight = self.view.bounds.size.height
    }
    
    @IBAction func thrustDown(sender : UIButton) {
         thrusting = true
        
    }
    
    @IBAction func thrustUp(sender : UIButton) {
        thrusting = false
    }
    
    @IBAction func fire(sender : UIButton) {
        fire_bullet = true
    }
    
    @IBAction func restart(sender : UIButton) {
        game_paused = true
        
        var alert = UIAlertController(title: "Game Paused", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Restart Game", style: .Destructive, handler: {
            action in
            restart_game = true
            game_paused = false
        
        }))
        alert.addAction(UIAlertAction(title: "Clear High Score", style: .Default, handler: {
            action in reset_highscore = true
            game_paused = false
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in game_paused = false}))
     
    
    }
   
    
   
    override func shouldAutorotate() -> Bool {
        return false
    }

   

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
}
