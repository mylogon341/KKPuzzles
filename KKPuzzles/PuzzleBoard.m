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
    
    if (!_dataSource) return;
    
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

    [[PuzzlesTiler sharedTiler] tileImage:[_dataSource imageForBoard:self] withGrid:(KKGrid){rowsNum, colsNum} size:_contentView.frame.size completion:^(NSArray<SKSpriteNode*> *tiles, NSError *error) {
        
        CGFloat verticalOffset = 0.0, horizontalOffset = 0.0;
        
        if (!error && tiles.count > 0) {
            horizontalOffset = (self.frame.size.width - tiles[0].size.width * colsNum) / 2.0;
            verticalOffset = (self.frame.size.height - tiles[0].size.height * rowsNum) / 2.0;
        }
        
        for (SKSpriteNode *tile in tiles) {
        
            tile.position = (CGPoint){horizontalOffset + tile.size.width * (([tiles indexOfObject:tile] % colsNum)), verticalOffset + tile.size.height * ([[[tiles reverseObjectEnumerator] allObjects] indexOfObject:tile] / rowsNum)};
            
            //add physics body
            tile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:tile.frame.size];
            tile.physicsBody.allowsRotation = NO;
            tile.physicsBody.categoryBitMask = tileSpriteCategory;
            tile.physicsBody.contactTestBitMask = tileSpriteCategory;
            
           [_scene addChild: tile];
        }
        
    }];

    
    [self setNeedsLayout];
}

@end
