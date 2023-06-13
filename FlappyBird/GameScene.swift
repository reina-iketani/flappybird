//
//  GameScene.swift
//  FlappyBird
//
//  Created by Reina Iketani on 2023/06/06.
//

import SpriteKit
import AVFoundation

var soundPlayer: AVAudioPlayer!


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var heartNode:SKNode!
    
    //衝突判定カテゴリー追加
    let birdCategory: UInt32 = 1 << 0
    let groundCategory: UInt32 = 1 << 1
    let wallCategory:  UInt32 = 1 << 2
    let itemuScoreCategory:  UInt32 = 1 << 3
    let scoreCategory:UInt32 = 1 << 4
    
    //スコア用
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaluts:UserDefaults = UserDefaults.standard
    
    var itemscore = 0
    var itemScoreLavelNode:SKLabelNode!
    

    //SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        //背景色
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁ようのノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //heart
        heartNode = SKNode()
        scrollNode.addChild(heartNode)
        
        //各種スプライトを生成する処理をメソッドに分ける
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupHeart()
        
        //スコアラベルの設定
        setupScoreLabel()
        
        
        
    }
    
    func setupGround(){
        
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール、元の位置繰り返す処理
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        
        //groundのスプライトを配置する
        for i in 0..<needNumber {
            //テクスチャを指定してスプライトを作成する
            let sprite = SKSpriteNode(texture: groundTexture)
        
            //スプライトの表示する位置を指定すr
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )
        
            //スプライトにアクション設定する
            sprite.run(repeatScrollGround)
            
            //スプライトに物理体を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size() )
            
            //衝突のカテゴリー設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            //衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            
            
            //シーンにスプライトを追加する
            scrollNode.addChild(sprite)
        
        }
    }
    
    func setupCloud(){
        
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud" )
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.width / cloudTexture.size().width) + 2
        
        //スクロールするあくしょんを作成
        //左から画像一枚分スクロールするアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        //元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        //左と元の位置を繰り返し
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        
        //スプライト配置
        for i in 0..<needCloudNumber{
            //スプライトの表示する位置を指定する
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )
            
            
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            
            //スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = self.frame.size.width + wallTexture.size().width
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクション
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間の大きさを鳥のサイズの４倍とする
        let slitLength = birdSize.height * 4
        
        //隙間いちの上下の振れ幅を６０pt
        let random_y_range: CGFloat = 60
        
        //空の中央位置を取得（y)
        let groundSize = SKTexture(imageNamed: "ground").size()
        let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        
        //空の中央位置を基準にして下側の壁の中央いちを取得
        let under_wall_center_y = sky_center_y - slitLength / 2 - wallTexture.size().height / 2
        
        //壁を生成するアクションを生成
        let createWallanimation = SKAction.run({
            //壁をまとめるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50//雲より手前、地面より奥
            
            //下側のかべの中央いちにランダム値を足して、下側の表示位置を決定する
            let random_y = CGFloat.random(in: -random_y_range...random_y_range)
            let under_wall_y = under_wall_center_y + random_y
            
            //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //下側の壁に物理体を設定する
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            under.physicsBody?.isDynamic = false
            
            //壁をまとめるノードに下側の壁を追加
            wall.addChild(under)
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slitLength)
            
            //上側の壁に物理体を作成
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            upper.physicsBody?.isDynamic = false
            
            //壁をまとめるノードに上側の壁を追加
            wall.addChild(upper)
            
            //スコアカウント用の透明な壁を作成
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
            
            //透明な物理たいを設定する
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.isDynamic = false
            
            //壁をまとめるノードに透明な壁を追加
            wall.addChild(scoreNode)
            
            //壁をまとめるノードにアニメーションを設定
            wall.run(wallAnimation)
            
            //壁を表示するノードに今回作成した壁を追加
            self.wallNode.addChild(wall)
            
            
        
        })
        //次の壁までの時間まちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁さくせい->時間まち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallanimation,waitAnimation]))
        
        //壁を表示するノードに壁の作成を無限に繰り返すアクションを作成設定
        wallNode.run(repeatForeverAnimation)
        
    }
    
    func setupHeart() {
        // ハートの画像を読み込む
        let heartTexture = SKTexture(imageNamed: "heart")
        heartTexture.filteringMode = .linear
        
        // ハートのサイズ
        let heartSize = CGSize(width: 20, height: 20)
        
        let movingDistance = self.frame.size.width + heartTexture.size().width
        // 画面外まで移動するアクションを作成
        let moveHeart = SKAction.moveBy(x: -movingDistance, y: 0, duration: 9)
        
        let removeHeart = SKAction.removeFromParent()
        let heartAnimation = SKAction.sequence([moveHeart, removeHeart])
        
        
        
        // ハートを生成して配置
        let createHeart = SKAction.run {
            
            let heart = SKSpriteNode(texture: heartTexture, size: heartSize)
            
            let randomY = CGFloat.random(in: self.frame.height / 2 ... self.frame.height * 2 / 3)
            heart.position = CGPoint(x: self.frame.size.width + heartSize.width, y: randomY )
            heart.zPosition = -30 // 鳥より手前、地面より奥
            heart.physicsBody = SKPhysicsBody(rectangleOf: heartSize)
            heart.physicsBody?.categoryBitMask = self.itemuScoreCategory
            heart.physicsBody?.isDynamic = false
            heart.run(heartAnimation)
            self.heartNode.addChild(heart)
        }
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createHeart, waitAnimation]))
        heartNode.run(repeatForeverAnimation)
        
        
    }

    
    
    func setupBird(){
        //鳥の画像を２種類読み込む
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //２種類のテクスチャを交互に変更するアニメーションを作成
        let textureAnimation = SKAction.animate(with: [birdTextureA,birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)
        
        //物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //カテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory | itemuScoreCategory
       
        
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
        
    }
    
    //画面タップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            //鳥の速度を０にする
            bird.physicsBody?.velocity = CGVector.zero
            
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
            
        }
        
        
    }
    
    //SKPhysicsContactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        
        //ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0{
            return
        }
        
        //heartと衝突
        if contact.bodyA.categoryBitMask == itemuScoreCategory || contact.bodyB.categoryBitMask == itemuScoreCategory {
                // heartに衝突した場合、itemscoreを増やす
                print("itemScoreUp")
                itemscore += 1
                // スコアを更新する
                itemScoreLavelNode.text = "ItemScore: \(itemscore)"
                PowerupSound()
                contact.bodyA.node?.removeFromParent()
                
            }
        
        else if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコアカウント用の透明な壁と衝突した
            print("ScoreUP")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            
            //ベストスコア更新か確認する
            var bestScore = userDefaluts.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaluts.set(bestScore, forKey: "BEST")
            }
            
            
            
        } else {
            //壁か地面と衝突した
            print("GameOver")
            
            scrollNode.speed = 0
            
            //衝突後は地面と反発するのみとする（リスタートするまで壁と反発させない）
            bird.physicsBody?.collisionBitMask = groundCategory
            
            //鳥が衝突した時の高さをもとに、鳥が地面に落ちるまでの秒数＋１を計算
            let duration = bird.position.y / 400.0 + 1.0
            
            //指定秒数分、鳥をくるくる回転させる。（回転速度は１周/秒）
            let roll = SKAction.rotate(byAngle: 2.0 * Double.pi * duration, duration: duration)
            bird.run(roll, completion: {
                //回転が終わったら鳥の動きを止める
                self.bird.speed = 0
            })
            
        }
        
        
        
    }
    
    func restart() {
        
        
        //スコアを０にする
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemscore = 0
        itemScoreLavelNode.text = "Item Score:\(itemscore)"
        
        //鳥を初期位置に戻し、壁と地面の両方に反発するように戻す
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0
        
        //全ての壁を取り除く
        wallNode.removeAllChildren()
        
        //鳥の羽ばたきを戻す
        bird.speed = 1
        
        //スクロールを再開させる
        scrollNode.speed = 1
        
        
        
    }
    
    func setupScoreLabel(){
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height-60)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        //ベストスコア表示を作成
        let bestScore = userDefaluts.integer(forKey: "BEST")
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height-90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        //itemscoreラベル表示
        itemscore = 0
        itemScoreLavelNode = SKLabelNode()
        itemScoreLavelNode.fontColor = UIColor.black
        itemScoreLavelNode.position = CGPoint(x: 10, y: self.frame.size.height-120)
        itemScoreLavelNode.zPosition = 100
        itemScoreLavelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLavelNode.text = "Item Score:\(itemscore)"
        self.addChild(itemScoreLavelNode)
    }
    
    func PowerupSound() {
        guard let url = Bundle.main.url(forResource: "powerup01", withExtension: "mp3") else {
            print("Failed to find sound file")
            return
        }
        
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: url)
            soundPlayer?.play()
        } catch {
            print("Failed to create audio player")
        }
    }
    
    
    
}
