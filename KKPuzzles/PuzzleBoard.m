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
#import "NSMutableArray+RandomUtils.h"

@interface PuzzleBoard () <SKSceneDelegate, SKPhysicsContactDelegate>

@property(nonatomic, strong) SKView *contentView;
@property(nonatomic, strong) SKScene *scene;
@property(nonatomic, strong) SKSpriteNode *selectedNode;

@end

@implementation PuzzleBoard {
    CGRect playgroundBounds;
    NSSet *tileCenters;
    NSDictionary<NSValue*, SKNode*> *completedState;
    NSDictionary<NSValue*, SKNode*> *shuffledState;
}

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
    _scene.delegate = self;
    _scene.physicsWorld.contactDelegate = self;
    _scene.scaleMode = SKSceneScaleModeResizeFill;

    [_contentView presentScene:_scene];
    
    [self addSubview:_contentView];
    
    NSUInteger rowsNum = [self.dataSource numberOfRowsOnBoard:self];
    NSUInteger colsNum = [self.dataSource numberOfColsOnBoard:self];
    NSUInteger missingTileIndex = [self.dataSource respondsToSelector:@selector(indexOfMissingPuzzleForBoard:)] ? [self.dataSource indexOfMissingPuzzleForBoard:self] : rowsNum * (colsNum - 1);
    missingTileIndex = missingTileIndex <= rowsNum * colsNum - 1 ? missingTileIndex : rowsNum * (colsNum - 1);
    
    [[PuzzlesTiler sharedTiler] tileImage:[_dataSource imageForBoard:self] withGrid:(KKGrid){rowsNum, colsNum} size:_contentView.frame.size completion:^(NSArray<SKSpriteNode*> *tiles, NSError *error) {
        
        CGFloat verticalOffset = 0.0, horizontalOffset = 0.0;
        CGPoint topLeft, bottomRight;
        
        if (!error && tiles.count > 0) {
            horizontalOffset = (self.frame.size.width - tiles[0].size.width * colsNum) / 2.0;
            verticalOffset = (self.frame.size.height - tiles[0].size.height * rowsNum) / 2.0;
        }
        
        NSMutableSet *centers = [NSMutableSet set];
        NSMutableDictionary *completed = [NSMutableDictionary dictionary];
        
        for (SKSpriteNode *tile in tiles) {
            
            tile.name = @"tile";
            tile.position = (CGPoint){horizontalOffset + tile.size.width * (([tiles indexOfObject:tile] % colsNum)), verticalOffset + tile.size.height * ([[[tiles reverseObjectEnumerator] allObjects] indexOfObject:tile] / rowsNum)};
            
            NSValue *center = [NSValue valueWithCGPoint:(CGPoint){CGRectGetMidX(tile.frame), CGRectGetMidY(tile.frame)}];
            completed[center] = tile;
            [centers addObject:center];
            
            if (tile == [tiles firstObject]) { //top left
                topLeft = (CGPoint){CGRectGetMinX(tile.frame), CGRectGetMaxY(tile.frame)};
            }else if(tile == [tiles lastObject]){ //bottom right
                bottomRight = (CGPoint){CGRectGetMaxX(tile.frame), CGRectGetMinY(tile.frame)};
            }
            
            //add physics body
            tile.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:tile.frame.size];
            tile.physicsBody.allowsRotation = false;
            
           [_scene addChild: tile];
        }
        
        tileCenters = [NSSet setWithSet:centers];
        completedState = [NSDictionary dictionaryWithDictionary:completed];
        
        [tiles[missingTileIndex] removeFromParent];
        playgroundBounds = CGRectMake(topLeft.x, bottomRight.y, bottomRight.x - topLeft.x, topLeft.y - bottomRight.y);
        
        [self shuffle];

    }];

    
    [self setNeedsLayout];
}

-(void)shuffle{
    NSMutableArray *centers = [NSMutableArray arrayWithArray:[completedState allKeys]];
    NSMutableArray *tiles = [NSMutableArray arrayWithArray:[completedState allValues]];
    
    [centers shuffle];
    [tiles shuffle];
    
    shuffledState = [NSDictionary dictionaryWithObjects:[NSArray arrayWithArray:tiles] forKeys:[NSArray arrayWithArray:centers]];
}

#pragma mark - SKPhysicsContact delegate

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint positionInScene = [touch locationInNode:self.scene];
    
    SKSpriteNode *touchedNode = (SKSpriteNode *)[self.scene nodeAtPoint:positionInScene];
    ![_selectedNode isEqual:touchedNode] ? _selectedNode = touchedNode : nil;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint positionInScene = [touch locationInNode:self.scene];
    CGPoint previousPosition = [touch previousLocationInNode:self.scene];
    CGPoint position = [_selectedNode position];

    CGFloat dx = positionInScene.x - previousPosition.x;
    CGFloat dy = positionInScene.y - previousPosition.y;
    
    if (fabs(dx) > fabs(dy)) {
        
        //control playground bounds
        if (CGRectGetMinX(_selectedNode.frame) + dx <= CGRectGetMinX(playgroundBounds) || CGRectGetMaxX(_selectedNode.frame) + dx >= CGRectGetMaxX(playgroundBounds)) return;
        [_selectedNode setPosition:CGPointMake(position.x + dx, position.y)];

    }else{
        
        //control playground bounds
        if (CGRectGetMinY(_selectedNode.frame) + dy <= CGRectGetMinY(playgroundBounds) || CGRectGetMaxY(_selectedNode.frame) + dy >= CGRectGetMaxY(playgroundBounds)) return;
        [_selectedNode setPosition:CGPointMake(position.x, position.y + dy)];
    }
}

-(void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene {
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", @"tile"];
    NSArray *tiles = [scene.children filteredArrayUsingPredicate:predicate];
    
    for (SKNode *tile in tiles) {
        //control playground bounds
        if (CGRectGetMinX(tile.frame) <= CGRectGetMinX(playgroundBounds)) {
            [tile setPosition:(CGPoint){CGRectGetMinX(playgroundBounds), tile.frame.origin.y}];
        }
        if (CGRectGetMaxX(tile.frame) >= CGRectGetMaxX(playgroundBounds)) {
            [tile setPosition:(CGPoint){CGRectGetMaxX(playgroundBounds) - tile.frame.size.width, tile.frame.origin.y}];
        }
        if (CGRectGetMinY(tile.frame) <= CGRectGetMinY(playgroundBounds)) {
            [tile setPosition:(CGPoint){tile.frame.origin.x, CGRectGetMinY(playgroundBounds)}];
        }
        if (CGRectGetMaxY(tile.frame) >= CGRectGetMaxY(playgroundBounds)) {
            [tile setPosition:(CGPoint){tile.frame.origin.x, CGRectGetMaxY(playgroundBounds) - tile.frame.size.height}];
        }
    }
}


@end
