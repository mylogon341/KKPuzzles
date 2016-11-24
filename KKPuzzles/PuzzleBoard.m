//
//  PuzzleBoard.m
//  KKPuzzles
//
//  Created by cris on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "PuzzleBoard.h"
#import "PuzzlesTiler.h"
#import <SpriteKit/SpriteKit.h>

static const uint32_t tileSpriteCategory = 0x1 << 0;

@interface PuzzleBoard ()

@property(nonatomic, strong) SKView *contentView;
@property(nonatomic, strong) SKScene *scene;

@end

@implementation PuzzleBoard

-(void)setDataSource:(id<PuzzleBoardDataSource>)dataSource {
    
    if (_dataSource != dataSource) {
        _dataSource = dataSource;
        if (_dataSource) {
//            [self reloadBoard];
        }
    }
}

-(void)reloadBoard {
       
    [_contentView removeFromSuperview];
    
    if (!_dataSource) {
        return;
    }
    
    _contentView = [[SKView alloc] initWithFrame:self.frame];
    _contentView.showsFPS = NO;
    _contentView.showsNodeCount = NO;
    _contentView.ignoresSiblingOrder = YES;

    _scene = [[SKScene alloc] initWithSize:self.frame.size];
    _scene.physicsWorld.gravity = (CGVector){0, 0};
    _scene.scaleMode = SKSceneScaleModeResizeFill;

    [_contentView presentScene:_scene];
    
    [self addSubview:_contentView];
    
    NSUInteger rowsNum = [self.dataSource numberOfRowsOnBoard:self];
    NSUInteger colsNum = [self.dataSource numberOfColsOnBoard:self];

    [[PuzzlesTiler sharedTiler] tileImage:[_dataSource imageForBoard:self] withGrid:(KKGrid){rowsNum, colsNum} size:_contentView.frame.size completion:^(NSArray<UIImage*> *tiles, NSError *error) {
        
        for (UIImage *tile in tiles) {
            
            //create sprite
            SKSpriteNode *lionSprite = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithCGImage:tile.CGImage]];
            lionSprite.anchorPoint = (CGPoint){0.0, 0.0};
            lionSprite.position = (CGPoint){lionSprite.size.width * (([tiles indexOfObject:tile] % colsNum)), lionSprite.size.height * ([tiles indexOfObject:tile] / rowsNum)};

            //add physics body
            lionSprite.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:lionSprite.frame.size];
            lionSprite.physicsBody.allowsRotation = NO;
            lionSprite.physicsBody.categoryBitMask = tileSpriteCategory;
            lionSprite.physicsBody.contactTestBitMask = tileSpriteCategory;
            [_scene addChild: lionSprite];

        }
        
    }];

    
    [self setNeedsLayout];
}

@end
