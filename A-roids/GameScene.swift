//
//  GameScene.swift
//  A-roids
//
//  Created by David Reed on 7/15/14.
//  Copyright (c) 2014 Dave's App Dungeon. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate{
    var ship = SKSpriteNode()
    var background_sprite = SKSpriteNode()
    var rotate_speed = CGFloat(M_PI)
    var start_x = CGFloat(0.0)
    var start_y = CGFloat(0.0)
    var end_x = CGFloat(0.0)
    var end_y = CGFloat(0.0)
    
    let labelsize:CGFloat = 30.0
    
    var gameover_label = SKLabelNode()
    var restart_label = SKLabelNode()
    var top_label = SKLabelNode()
    var bottom_label = SKLabelNode()

    
    var score = 0
    var high_score = 0
    var start_lifes = 3
    var lifes_left = 0
    let rock_value = 100
    var rocks_left = 5
    var rocks_increase_per_level = 3
    var level = 0
    var rock_count = 0
    
    var game_over = false
    var respawning = false
    var highscore_soundplayed = false
    var spawn_count = 0
    let spawn_limit = 200
    
    let ship_scale: CGFloat = 0.14
   
    
    var ship_velocity:CGFloat = 0.0
    var ship_max_velocity:CGFloat = 28.0
    var missile_speed:CGFloat = 800.0
    let acceleration_factor:CGFloat = 1100
   
    
    let explosion1_atlas = SKTextureAtlas(named:"explosion1.atlas")
    var explosion1_array = Array<SKTexture>()
    var explosion1_sprite = SKSpriteNode()
    
    let explosion2_atlas = SKTextureAtlas(named:"explosion2.atlas")
    var explosion2_array = Array<SKTexture>()
    var explosion2_sprite = SKSpriteNode()
    
    let rock_category:UInt32 = 0x1 << 0
    let missile_category:UInt32 = 0x1 << 1
    let ship_category:UInt32 = 0x1 << 2
    
    
    var shield = SKShapeNode()
    var fireEmmiter = SKEmitterNode()
    var av_player = AVAudioPlayer()
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
   

    
   
    let rock_types = ["asteroid_blue", "asteroid_brown", "asteroid_blend"]
    var shield_colors = [SKColor.clearColor(), SKColor.whiteColor(), SKColor.cyanColor(), SKColor.greenColor(), SKColor.yellowColor(), SKColor.orangeColor(), SKColor.redColor()].reverse()
    
    var shield_index = 0

    override func didMoveToView(view: SKView)
    {
        self.backgroundColor = SKColor.blackColor()
        ship = SKSpriteNode(imageNamed:"Spaceship.png")
        background_sprite = SKSpriteNode(imageNamed:"space_background.png")
        background_sprite.zPosition = 0
        background_sprite.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
        
        ship.physicsBody = SKPhysicsBody(rectangleOfSize: ship.size)
        ship.physicsBody.categoryBitMask = ship_category
        ship.physicsBody.contactTestBitMask = rock_category
        ship.physicsBody.dynamic = true
        ship.physicsBody.mass = 20
        ship.physicsBody.linearDamping = 0.8
        
       
        ship.xScale = ship_scale
        ship.yScale = ship_scale
        
        shield = SKShapeNode(circleOfRadius: ship.size.width / 2 + 7)
        shield.lineWidth = 1
        shield.zPosition = 7
        
        
        let spawn_interval = 2.20
        var timer = NSTimer.scheduledTimerWithTimeInterval(spawn_interval, target: self, selector: Selector("spawnRock"), userInfo: nil, repeats: true)
        let top_margin:CGFloat = 44
        let bottom_margin:CGFloat = 20
        top_label.position = CGPoint(x:CGRectGetMidX(self.frame), y: self.frame.height - top_margin)
        bottom_label.position = CGPoint(x:CGRectGetMidX(self.frame), y: bottom_margin)
        top_label.fontSize = labelsize
        bottom_label.fontSize = labelsize
        top_label.zPosition = 1
        bottom_label.zPosition = 1
        
        
        let highscore_data = userDefaults.integerForKey("highscore")
        high_score = highscore_data
            
        
    
        startGame()
        
        var numberOfSprites = 31

        for (var i = 1; i < numberOfSprites; i++)
        {
            let texture_name = "GlowingExplosion" + String(i)
            let explosion_frame = explosion1_atlas.textureNamed(texture_name)
            explosion1_array.append(explosion_frame)
            
        }
        
        explosion1_sprite = SKSpriteNode(texture:explosion1_array[28])
        explosion1_sprite.xScale = 0.6
        explosion1_sprite.yScale = 0.6
      
        self.addChild(explosion1_sprite)
        numberOfSprites = 36
        
        for (var i = 1; i < numberOfSprites; i++)
        {
            let texture_name = "MeteorBlast" + String(i)
            let explosion_frame = explosion2_atlas.textureNamed(texture_name)
            explosion2_array.append(explosion_frame)
            
        }
        
        explosion2_sprite = SKSpriteNode(texture:explosion2_array[34])
        explosion2_sprite.xScale = 0.9
        explosion2_sprite.yScale = 0.9
        
        self.addChild(explosion2_sprite)
        
        
        
        let fireEmmitterPath:NSString = NSBundle.mainBundle().pathForResource("thrusterParticles", ofType: "sks")

        
        fireEmmiter = NSKeyedUnarchiver.unarchiveObjectWithFile(fireEmmitterPath) as SKEmitterNode
        
        var thrustSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("thruster_sound", ofType: "m4a"))
        
        // Removed deprecated use of AVAudioSessionDelegate protocol
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
        AVAudioSession.sharedInstance().setActive(true, error: nil)
        
        var error:NSError?
        av_player = AVAudioPlayer(contentsOfURL: thrustSound, error: &error)
      
        
        
       
    }
    
    func startGame()
    {
        score = 0
        level = 0
        lifes_left = start_lifes
        highscore_soundplayed = false
        shield_index = 0
        adjustShield()
        nextLevel()
        spawnRock()
        game_over = false //really for game over
        
    }
    
    func nextLevel()
    {
        respawning = true
        self.removeAllChildren()

        level += 1
        rock_count = 0
        rocks_left = rocks_increase_per_level * level
        
        drawLabels()

        self.addChild(top_label)
        self.addChild(bottom_label)
        self.addChild(explosion1_sprite)
        self.addChild(explosion2_sprite)
        self.addChild(shield)
        shield.hidden = true
        
      
        self.addChild(background_sprite)
        self.addChild(ship)

        centerShip()
    }
    
    
    func centerShip(){
       
        ship.physicsBody.velocity = CGVectorMake(0,0)
        thrusting = false
        ship.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        ship.zRotation = 0
        drawLabels()
        
    }
    
    func drawLabels()
    {
        top_label.text = " High Score: " + String(high_score) + "   Score: " + String(score)
            + "    Lives: " + String(lifes_left)
       
        bottom_label.text = "Level: " + String(level) + "    Rocks: " + String(rocks_left)

    }
    
    
 
    
    
    func spawnRock()
    {
        if game_over || rock_count >= rocks_increase_per_level * level{
            return
        }
        rock_count += 1
        let index = Int(arc4random_uniform(UInt32(3)))
        let rock_string = rock_types[index]
        let rock = SKSpriteNode(imageNamed: rock_string)
        rock.name = "asteroid"
        
        let xpos = arc4random_uniform(UInt32(self.size.width))
        let ypos = arc4random_uniform(UInt32(self.size.height))
        

        let angle = arc4random_uniform(UInt32(360))
        let rad = Float(angle) * Float(M_PI/180)
        let dirs = getForward(rad)
        let x_dir = CGFloat(dirs.x)
        let y_dir = CGFloat(dirs.y)
        
        let speed = CGFloat(arc4random_uniform(400) + 300)
  
       
        let rotate_val = arc4random_uniform(15)
        let rotate_speed = CGFloat(rotate_val) - 3.0 // slow it down and give it a chance to spin counter clockwise
      
        
        rock.position = CGPoint(x: CGFloat(xpos), y:CGFloat(ypos))
        rock.zPosition = 3
        let shrink_factor: CGFloat = 0.70
        rock.xScale = shrink_factor
        rock.yScale = shrink_factor
        
        rock.physicsBody = SKPhysicsBody(circleOfRadius: rock.size.width/2)
        rock.physicsBody.dynamic = true
        rock.physicsBody.categoryBitMask = rock_category
        rock.physicsBody.contactTestBitMask = missile_category
        rock.physicsBody.collisionBitMask = 0
        rock.physicsBody.velocity = CGVectorMake(speed * x_dir, speed * y_dir)
        rock.physicsBody.angularVelocity = rotate_speed
        rock.physicsBody.mass = 900
        rock.physicsBody.friction = 175
        
        self.addChild(rock)
    }
    
    
    func adjustShield(){
        shield.glowWidth = CGFloat(8.0 -  shield_index) * 2.0
        shield.strokeColor = shield_colors[shield_index]
        //shield.hidden = false
    }
    
    func didBeginContact(contact: SKPhysicsContact){
        // Body1 and 2 depend on the categoryBitMask << 0 und << 1
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        if ((ship_category == contact.bodyA.categoryBitMask || ship_category == contact.bodyB.categoryBitMask)
        && (rock_category == contact.bodyA.categoryBitMask || rock_category == contact.bodyB.categoryBitMask)){
          //it's a ship-rock collision
            if respawning{
                return
            }
            
            //your shield was hit, but may still have power
            if shield_index < shield_colors.count - 1{
                respawning = true
                spawn_count = 0
                shield_index += 1
                adjustShield()
                return
            }
            
            lifes_left -= 1
            explosion2_sprite.position = ship.position
            let animateAction = SKAction.animateWithTextures(explosion2_array, timePerFrame: 0.06)
            self.runAction(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
              explosion2_sprite.runAction(animateAction)
             if lifes_left == 0{
                gameover_label.text = "Game Over"
                gameover_label.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
                gameover_label.fontSize = 70
                restart_label.text = "touch to restart"
                restart_label.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame) - 45)
                restart_label.fontSize = 30
                restart_label.fontName = "Helvetica"
                restart_label.fontColor = SKColor.yellowColor()
                restart_label.name = "restart"
                self.addChild(gameover_label);
                self.addChild(restart_label);
                game_over = true
                ship.removeFromParent()
              
                userDefaults.setObject(high_score, forKey: "highscore")
             }
            else
            {
               // you lose a life, but game is not over
                respawning = true
                spawn_count = 0
                shield_index = 0 // renew shield
                adjustShield()
                centerShip()
            }

            

        }
        else
        {
            if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
                firstBody = contact.bodyA
                secondBody = contact.bodyB
            }
            else
            {
                firstBody = contact.bodyB
                secondBody = contact.bodyA
            }
        
        
            missileDidCollideWithRock(contact.bodyA.node as SKSpriteNode, rock: contact.bodyB.node as SKSpriteNode)
        }
    }
    
    
    
    func missileDidCollideWithRock(missile:SKSpriteNode, rock:SKSpriteNode){
        
        explosion1_sprite.position = rock.position
 
       
        let animateAction = SKAction.animateWithTextures(explosion1_array, timePerFrame: 0.02)
        self.explosion1_sprite.runAction(animateAction);
        self.runAction(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
        
        missile.removeFromParent()
        rock.removeFromParent()
        score += rock_value
        if score > high_score && !highscore_soundplayed  && high_score > rock_value{
            self.runAction(SKAction.playSoundFileNamed("fanfare.wav", waitForCompletion: false))
            highscore_soundplayed = true
        }
        high_score = max(score, high_score)

        rocks_left -= 1
        drawLabels()
        if rocks_left == 0 {
            self.runAction(SKAction.playSoundFileNamed("win_trumpet.wav", waitForCompletion: false))
            nextLevel()
        }
       

    }
    
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent!) {
        for touch: AnyObject in touches {
            
            let location = touch.locationInNode(self)
            let touchedNode = nodeAtPoint(location)
            
            let nodeName: String? = touchedNode.name
            var spot: CGPoint = touch.locationInView(self.view)
            
            end_x = spot.x;
            end_y = spot.y;
            var direction: Float = 1.0
            var rotate_amount:CGFloat = 0.0
            var multiplier: CGFloat = 0.025
            
            //see if it's vertical or horizontal
            let x_change = abs(start_y - end_y)
            let y_change = abs(start_x - end_x)
            var changer: CGFloat
            var start: CGFloat
            var end: CGFloat
            
            if  x_change > y_change{
                changer = x_change
                start = start_x
                end = end_x
            }
            else
            {
                changer = y_change
                start = start_y
                end = end_y
            }
            
            
            //see if it is to rotate cw or ccw
            if start < end {
                    direction = -1.0
            }
            
            // the longer the drag, the faster the rotate
            rotate_amount = changer * multiplier
            let degrees = rotate_amount * CGFloat(direction)
            ship.zRotation += CGFloat(degrees)
            start_x = end_x
            start_y = end_y
            
            
        }
    }
    

    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent!) {
       super.touchesBegan(touches, withEvent: event)
        
       for touch: AnyObject in touches {
        
           let location = touch.locationInNode(self)
           let touchedNode = nodeAtPoint(location)
        
        
            if touchedNode.name != nil{
                let nodeName: NSString = touchedNode.name
                if nodeName.containsString("restart"){
                    startGame()
                }
            }
            else
            {
               var spot: CGPoint = touch.locationInView(self.view)
            
               start_x = spot.x;
               start_y = spot.y
            }
        }
      
    }
    
    func getForward(rad: Float) -> (x: Float, y: Float) {
        let x_dir = sinf(rad)
        let y_dir = cosf(rad)
        return (x_dir, y_dir)
    }
    
   
    
    
    

    func checkSpawn()
    {

        if respawning{
            spawn_count += 1
           
            if spawn_count < spawn_limit {
                if spawn_count % 5 == 0{
                 //ship.hidden = !ship.hidden
                 shield.hidden = !shield.hidden
                }
            }
            else
            {
                respawning = false
                ship.hidden = false
                shield.hidden = true
            }
            
        }
    }
    
    
   
    
    
    func torusize(thing: SKSpriteNode)
    {
      
        var x = thing.position.x
        var y = thing.position.y
        
        var newx = x
        var newy = y
        
        if y <= 0 {
            newy = CGFloat(screenHeight) - thing.size.height
        }
        else if y >= CGFloat(screenHeight){
            newy = 0 + thing.size.height
        }
        
        if x <= 0 {
            newx = CGFloat(screenWidth) - thing.size.width
           
        }
        else if x >= CGFloat(screenWidth){
            newx = 0 + thing.size.width
        }
        
        if x != newx || y != newy{
            thing.position = CGPointMake(newx, newy)
        }
    
    }
    
    func thrust()
    {
        ship_velocity += acceleration_factor
        if !av_player.playing{
            av_player.prepareToPlay()
            av_player.play()
            av_player.numberOfLoops = -1
           
        }
        let thrust_volume:Float = 1.0
        av_player.volume = thrust_volume
        
        let ways = getForward(Float(ship.zRotation))
        let x_dir = CGFloat(ways.x)
        let y_dir = CGFloat(ways.y)
        ship.physicsBody.applyForce(CGVectorMake(-x_dir * ship_velocity, y_dir * ship_velocity))
        ship.physicsBody.angularVelocity = 0.0 // stop spinning
        
        if fireEmmiter.parent == nil{
            self.addChild(fireEmmiter)
        }

        fireEmmiter.particleBirthRate = 270.50
        fireEmmiter.name = "fireEmmiter"
        fireEmmiter.zPosition = 5
        
        fireEmmiter.emissionAngle = ship.zRotation - (3.14/2) //rotate 90 degress which is pi over 2 
            

    }

    
    
   
    override func update(currentTime: CFTimeInterval) {
        
        if game_paused{
            return
        }
        
        shield.position = ship.position
        torusize(ship)
        checkSpawn()
        
        if restart_game{
            restart_game = false
            startGame()
        }
        
        
        if reset_highscore{
            reset_highscore = false
            userDefaults.setObject(0, forKey: "highscore")
            high_score = 0
            userDefaults.setObject(high_score, forKey: "highscore")
            drawLabels()
        }

        if thrusting && !game_over{
           thrust()
        }
        else
        {
            ship_velocity = 0
            
            // let the particles and the volume dissipate insteade of just cutting out
            if fireEmmiter.particleBirthRate > 0{
                fireEmmiter.particleBirthRate -= 10
            }
            if av_player.volume > 0{
                av_player.volume -= 0.05
            }

        }

        // keep the emitter in tow if it is still emitting
        if fireEmmiter.particleBirthRate > 0{
            let xrad:CGFloat = 20
            let yrad:CGFloat = 25

            let dirs = getForward(Float(ship.zRotation))

            let x_offset: CGFloat = CGFloat(dirs.x) * xrad
            let y_offset: CGFloat = CGFloat(dirs.y) * yrad
            fireEmmiter.position = CGPointMake(ship.position.x + x_offset, ship.position.y - y_offset)
        }
        
        // adjust the shield so the ship is centered within it
        if !shield.hidden{
            let xrad:CGFloat = 2
            let yrad:CGFloat = 1.25
            let dirs = getForward(Float(ship.zRotation))
            let x_offset: CGFloat = CGFloat(dirs.x) * xrad
            let y_offset: CGFloat = CGFloat(dirs.y) * yrad
            shield.position = CGPointMake(ship.position.x + x_offset, ship.position.y + y_offset)
        }
    
        

       
        self.enumerateChildNodesWithName("asteroid") {
            node, stop in
            let spritenode = node as SKSpriteNode
            self.torusize(spritenode)
        }
      
        
        
        if fire_bullet && !game_over{
            fire_bullet = false
            self.runAction(SKAction.playSoundFileNamed("missile.mp3", waitForCompletion: false))
            let missile = SKSpriteNode(imageNamed:"shot1")
            
            let radius:CGFloat = 26 //adjust to suit, too close to the ship causes kickback
            let dirs = getForward(Float(ship.zRotation))
            
            let x_offset: CGFloat = CGFloat(dirs.x) * radius
            let y_offset: CGFloat = CGFloat(dirs.y) * radius
            
            missile.position.x = ship.position.x - x_offset
            missile.position.y = ship.position.y + y_offset
            
            let missile_range:Float = 650
            
            let x_distance = CGFloat(missile_range * dirs.x)
            let y_distance = CGFloat(missile_range * dirs.y)
           
            let x_destination = missile.position.x - x_distance
            let y_destination = missile.position.y + y_distance
            let missile_destination = CGPointMake(x_destination, y_destination)
            
            missile.physicsBody = SKPhysicsBody(circleOfRadius: missile.size.width / 2)
            missile.physicsBody.dynamic = true
            missile.physicsBody.categoryBitMask = missile_category
            missile.physicsBody.contactTestBitMask = rock_category
            missile.physicsBody.linearDamping = 0
            missile.physicsBody.mass = 0
            self.addChild(missile)
            missile.zPosition = 6
           
            let moveit = SKAction.moveTo(missile_destination, duration: 1.0)
            let killit = SKAction.removeFromParent()
            
            var moveandkill = SKAction.sequence([moveit, killit])
            missile.runAction(moveandkill)
          
        }
        
    
    }
}
