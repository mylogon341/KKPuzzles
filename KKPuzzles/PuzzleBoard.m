//
//  PuzzleBoard.m
//  KKPuzzles
//
//  Created by cris on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "PuzzleBoard.h"
#import "PuzzlesTiler.h"
#import "NSMutableArray+RandomUtils.h"
#import "Tile.h"
#import "TileHolder.h"

@interface PuzzleBoard ()

@end

@implementation PuzzleBoard {
    CGRect playgroundBounds;
    NSArray<Tile*> *tiles;
    NSArray<TileHolder*> *holders;
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
    
    if (!_dataSource) return;
    
    NSUInteger rowsNum = [self.dataSource numberOfRowsOnBoard:self];
    NSUInteger colsNum = [self.dataSource numberOfColsOnBoard:self];
    NSUInteger missingTileIndex = [self.dataSource respondsToSelector:@selector(indexOfMissingPuzzleForBoard:)] ? [self.dataSource indexOfMissingPuzzleForBoard:self] : rowsNum * (colsNum - 1);
    missingTileIndex = missingTileIndex <= rowsNum * colsNum - 1 ? missingTileIndex : rowsNum * (colsNum - 1);
    
    [[PuzzlesTiler sharedTiler] tileImage:[_dataSource imageForBoard:self] withGrid:(KKGrid){rowsNum, colsNum} size:self.frame.size completion:^(NSArray<UIImageView*> *images, NSError *error) {
        
        CGFloat verticalOffset = 0.0, horizontalOffset = 0.0;
        CGPoint topLeft, bottomRight;
        
        if (!error && images.count > 0) {
            horizontalOffset = (self.frame.size.width - images[0].frame.size.width * colsNum) / 2.0;
            verticalOffset = (self.frame.size.height - images[0].frame.size.height * rowsNum) / 2.0;
        }
        
        NSMutableArray<Tile*> *tTiles = [NSMutableArray array];
        NSMutableArray<TileHolder*> *tHolders = [NSMutableArray array];
        
        for (UIImageView *tileImage in images) {
            
            NSUInteger index = [images indexOfObject:tileImage];
            
            tileImage.frame = (CGRect){horizontalOffset + tileImage.frame.size.width * ((index % colsNum)), verticalOffset + tileImage.frame.size.height * (index / rowsNum), tileImage.frame.size.width, tileImage.frame.size.height};
            
            UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            [tileImage setUserInteractionEnabled:true];
            [tileImage addGestureRecognizer:pgr];
            
            TileHolder *holder = [[TileHolder alloc] init];
            holder.index = index;
            holder.position = tileImage.frame.origin;
            holder.center = tileImage.center;
            [tHolders addObject:holder];
            
            Tile *tile = [[Tile alloc] initWithImage:tileImage holder:holder];
            [tTiles addObject:tile];
            
            [self addSubview:tileImage];
            
            if (tileImage == [images firstObject]) { //top left
                topLeft = (CGPoint){CGRectGetMinX(tileImage.frame), CGRectGetMaxY(tileImage.frame)};
            }else if(tileImage == [images lastObject]){ //bottom right
                bottomRight = (CGPoint){CGRectGetMaxX(tileImage.frame), CGRectGetMinY(tileImage.frame)};
            }
        }
        
        //remove missing tile
        [tTiles[missingTileIndex].image removeFromSuperview];
        tTiles[missingTileIndex].holder = nil;
        [tTiles removeObjectAtIndex:missingTileIndex];
        
        holders = [NSArray arrayWithArray:tHolders];
        tiles = [NSArray arrayWithArray:tTiles];
        
        playgroundBounds = CGRectMake(topLeft.x, bottomRight.y, bottomRight.x - topLeft.x, topLeft.y - bottomRight.y);
        
    }];

    
    [self setNeedsLayout];
}

-(void)handlePan:(UIPanGestureRecognizer*)sender;
{
    
    typedef NS_ENUM(NSUInteger, UIPanGestureRecognizerDirection) {
        UIPanGestureRecognizerDirectionUndefined,
        UIPanGestureRecognizerDirectionUp,
        UIPanGestureRecognizerDirectionDown,
        UIPanGestureRecognizerDirectionLeft,
        UIPanGestureRecognizerDirectionRight
    };
    
    static UIPanGestureRecognizerDirection direction = UIPanGestureRecognizerDirectionUndefined;
    
    if(sender.state == UIGestureRecognizerStateBegan){
        CGPoint velocity = [sender velocityInView:sender.view];
        
        BOOL isVerticalGesture = fabs(velocity.y) > fabs(velocity.x);
        
        if (isVerticalGesture) {
            if (velocity.y > 0) {
                direction = UIPanGestureRecognizerDirectionDown;
            } else {
                direction = UIPanGestureRecognizerDirectionUp;
            }
        }
        
        else {
            if (velocity.x > 0) {
                direction = UIPanGestureRecognizerDirectionRight;
            } else {
                direction = UIPanGestureRecognizerDirectionLeft;
            }
        }
    }

    CGPoint center = sender.view.center;
    CGPoint translation = [sender translationInView:sender.view];
    
    switch (direction) {
        case UIPanGestureRecognizerDirectionUp: {
            center = CGPointMake(center.x,
                                 center.y + translation.y);
            break;
        }
        case UIPanGestureRecognizerDirectionDown: {
            center = CGPointMake(center.x,
                                 center.y + translation.y);
            break;
        }
        case UIPanGestureRecognizerDirectionLeft: {
            center = CGPointMake(center.x + translation.x,
                                 center.y);
            break;
        }
        case UIPanGestureRecognizerDirectionRight: {
            center = CGPointMake(center.x + translation.x,
                                 center.y);
            break;
        }
        default: {
            break;
        }
    }
    
    sender.view.center = center;
    [sender setTranslation:CGPointZero inView:sender.view];
}

@end
