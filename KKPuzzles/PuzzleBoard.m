//
//  PuzzleBoard.m
//  KKPuzzles
//
//  Created by kkuc on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "PuzzleBoard.h"
#import "PuzzlesTiler.h"
#import "NSMutableArray+RandomUtils.h"
#import "Tile.h"
#import "TileHolder.h"

typedef enum : NSUInteger {
    Above,
    Below,
    OnLeft,
    OnRight
} NeighbourRelation;

@interface PuzzleBoard ()

@property(nonatomic) NSUInteger rowsNum;
@property(nonatomic) NSUInteger colsNum;

@end

@implementation PuzzleBoard {
    CGRect playgroundBounds;
    NSArray<Tile*> *tiles;
    NSArray<TileHolder*> *holders;
    
    Tile *missingTile;
    Tile *pannedTile;
}

@synthesize rowsNum;
@synthesize colsNum;

-(BOOL)isCompleted {
    return [self checkBoardCompleted];
}

-(void)reload {
    
    if (!_dataSource) return;
    
    rowsNum = [self.dataSource numberOfRowsOnBoard:self];
    colsNum = [self.dataSource numberOfColsOnBoard:self];
    NSUInteger missingTileIndex = [self.dataSource respondsToSelector:@selector(indexOfMissingPuzzleForBoard:)] ? [self.dataSource indexOfMissingPuzzleForBoard:self] : colsNum * (rowsNum - 1);
    missingTileIndex = missingTileIndex <= rowsNum * colsNum - 1 ? missingTileIndex : colsNum * (rowsNum - 1);
    
    [[PuzzlesTiler sharedTiler] tileImage:[_dataSource imageForBoard:self] withGrid:(KKGrid){rowsNum, colsNum} size:self.frame.size completion:^(NSArray<Tile*> *t, NSError *error) {
        
        NSMutableArray<Tile*> *tTiles = [NSMutableArray arrayWithArray:t];
        NSMutableArray<TileHolder*> *tHolders = [NSMutableArray array];
        
        for (Tile *tile in tTiles) {
            
            NSUInteger index = [tTiles indexOfObject:tile];
            
            TileHolder *holder = [[TileHolder alloc] init];
            holder.index = index;
            [tHolders addObject:holder];
            
            tile.holder= holder;
            tile.completedIndex = index;
        }
        
        //remove missing tile
        missingTile = tTiles[missingTileIndex];
        tTiles[missingTileIndex].holder = nil;
        [tTiles removeObjectAtIndex:missingTileIndex];
        
        holders = [NSArray arrayWithArray:tHolders];
        tiles = [NSArray arrayWithArray:tTiles];
        
        [self shuffle];
        [self redraw];
    }];
}

-(void)redraw {
    
    for (UIView* view in self.subviews) {
        [view removeFromSuperview];
    }
    
    if (tiles.count == 0) return;
   
    CGPoint topLeft, bottomRight;
    
    CGFloat horizontalOffset = (self.frame.size.width - tiles[0].frame.size.width * colsNum) / 2.0;
    CGFloat verticalOffset = (self.frame.size.height - tiles[0].frame.size.height * rowsNum) / 2.0;
    CGFloat tileWidth = tiles[0].frame.size.width;
    CGFloat tileHeight = tiles[0].frame.size.height;
    
    for (TileHolder *holder in holders) {
        holder.position = (CGPoint){horizontalOffset + tileWidth * ((holder.index % colsNum)), verticalOffset + tileHeight * (holder.index / colsNum)};
        holder.center = CGPointApplyAffineTransform(holder.position, CGAffineTransformMakeTranslation(tileWidth/2, tileHeight/2));
        
        if (holder == [holders firstObject]) { //top left
            topLeft = holder.position;
        }else if(holder == [holders lastObject]){ //bottom right
            bottomRight = CGPointApplyAffineTransform(holder.position, CGAffineTransformMakeTranslation(tileWidth, tileHeight));
        }

    }
    
    for (Tile *tile in tiles) {
        
        tile.frame = (CGRect){tile.holder.position.x, tile.holder.position.y, tileWidth, tileHeight};
        
        UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [tile setUserInteractionEnabled:true];
        [tile addGestureRecognizer:pgr];
        
        [self addSubview:tile];
    }

    playgroundBounds = CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
    [self setUserInteractionEnabled:true];
    [self setNeedsLayout];
    
}

-(void)boardCompleted {
    //add missing tile
    missingTile.center = [self getEmptyHolder].center;
    [self addSubview:missingTile];
    [self setUserInteractionEnabled:false];
    [self.delegate respondsToSelector:@selector(boardCompleted:)] ? [self.delegate boardCompleted:self] : nil;
}

-(void)shuffle {
    tiles = [self shuffleTiles];
    [self redraw];
}


#pragma mark Utils

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
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            
            if (pannedTile) return;
            pannedTile = (Tile*)sender.view;
            
            CGPoint velocity = [sender velocityInView:pannedTile];
            
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

            break;
        }
            
        case UIGestureRecognizerStateEnded:{
            
            TileHolder *empty = [self getEmptyHolder];
            TileHolder *currentHolder = pannedTile.holder;

            if ([self distanceFrom:empty.center to:pannedTile.center] <= [self distanceFrom:currentHolder.center to:pannedTile.center]) {
                [UIView animateWithDuration:0.2 animations:^{
                    pannedTile.center = empty.center;
                } completion:^(BOOL finished) {
                    pannedTile.holder = empty;
                    pannedTile = nil;
                    [self checkBoardCompleted] ? [self boardCompleted] : nil;
                }];
            }else{
                [UIView animateWithDuration:0.2 animations:^{
                    pannedTile.center = currentHolder.center;
                } completion:^(BOOL finished) {
                    pannedTile = nil;
                }];
            }
            break;
        }
            
        default:
            break;
    }
    
    CGPoint center = pannedTile.center;
    CGPoint translation = [sender translationInView:pannedTile];
    
    switch (direction) {
        case UIPanGestureRecognizerDirectionUp: {
            
            TileHolder *neighbour = [self getNeighbourFor:pannedTile.holder relation:Above];
            if (!neighbour) return;
            if (neighbour.empty) {
                center = CGPointMake(center.x,
                                     center.y + translation.y);
                
                //control playground bounds
                pannedTile.center = center;
                if (CGRectGetMaxY(pannedTile.frame) >= CGRectGetMaxY(playgroundBounds)) {
                    pannedTile.center = (CGPoint){pannedTile.center.x, CGRectGetMaxY(playgroundBounds) - pannedTile.frame.size.height / 2};
                }
                if (CGRectGetMinY(pannedTile.frame) <= CGRectGetMinY(playgroundBounds)) {
                    pannedTile.center = (CGPoint){pannedTile.center.x, CGRectGetMinY(playgroundBounds) + pannedTile.frame.size.height / 2};
                }
                
                //control nearest tiles bounds
                //above
                TileHolder *nextNeighbour = [self getNeighbourFor:neighbour relation:Above];
                if (nextNeighbour) {
                    if (CGRectGetMinY(pannedTile.frame) <= nextNeighbour.position.y + pannedTile.frame.size.height) {
                        pannedTile.center = neighbour.center;
                    }
                }
                //below
                TileHolder *belowNeighbour = [self getNeighbourFor:pannedTile.holder relation:Below];
                if (belowNeighbour) {
                    if (CGRectGetMaxY(pannedTile.frame) >= belowNeighbour.position.y) {
                        pannedTile.center = pannedTile.holder.center;
                    }
                }
                
            }
            break;
        }
        case UIPanGestureRecognizerDirectionDown: {
            
            TileHolder *neighbour = [self getNeighbourFor:pannedTile.holder relation:Below];
            if (!neighbour) return;
            if (neighbour.empty) {
                center = CGPointMake(center.x,
                                     center.y + translation.y);
                
                //control playground bounds
                pannedTile.center = center;
                if (CGRectGetMaxY(pannedTile.frame) >= CGRectGetMaxY(playgroundBounds)) {
                    pannedTile.center = (CGPoint){pannedTile.center.x, CGRectGetMaxY(playgroundBounds) - pannedTile.frame.size.height / 2};
                }
                if (CGRectGetMinY(pannedTile.frame) <= CGRectGetMinY(playgroundBounds)) {
                    pannedTile.center = (CGPoint){pannedTile.center.x, CGRectGetMinY(playgroundBounds) + pannedTile.frame.size.height / 2};
                }
                
                //control nearest tiles bounds
                //below
                TileHolder *nextNeighbour = [self getNeighbourFor:neighbour relation:Below];
                if (nextNeighbour) {
                    if (CGRectGetMaxY(pannedTile.frame) >= nextNeighbour.position.y) {
                        pannedTile.center = neighbour.center;
                    }
                }
                //above
                TileHolder *aboveNeighbour = [self getNeighbourFor:pannedTile.holder relation:Above];
                if (aboveNeighbour) {
                    if (CGRectGetMinY(pannedTile.frame) <= aboveNeighbour.position.y + pannedTile.frame.size.height) {
                        pannedTile.center = pannedTile.holder.center;
                    }
                }

            }
            break;
        }
        case UIPanGestureRecognizerDirectionLeft: {
            
            TileHolder *neighbour = [self getNeighbourFor:pannedTile.holder relation:OnLeft];
            if (!neighbour) return;
            if (neighbour.empty) {
                center = CGPointMake(center.x + translation.x,
                                     center.y);
                
                //control playground bounds
                pannedTile.center = center;
                if (CGRectGetMaxX(pannedTile.frame) >= CGRectGetMaxX(playgroundBounds)) {
                    pannedTile.center = (CGPoint){CGRectGetMaxX(playgroundBounds) - pannedTile.frame.size.width / 2, pannedTile.center.y};
                }
                if (CGRectGetMinX(pannedTile.frame) <= CGRectGetMinX(playgroundBounds)) {
                    pannedTile.center = (CGPoint){CGRectGetMinX(playgroundBounds) + pannedTile.frame.size.width / 2, pannedTile.center.y};
                }
                
                //control nearest tiles bounds
                //left
                TileHolder *nextNeighbour = [self getNeighbourFor:neighbour relation:OnLeft];
                if (nextNeighbour) {
                    if (CGRectGetMinX(pannedTile.frame) <= nextNeighbour.position.x + pannedTile.frame.size.width) {
                        pannedTile.center = neighbour.center;
                    }
                }
                //right
                TileHolder *rightNeighbour = [self getNeighbourFor:pannedTile.holder relation:OnRight];
                if (rightNeighbour) {
                    if (CGRectGetMaxX(pannedTile.frame) >= rightNeighbour.position.x) {
                        pannedTile.center = pannedTile.holder.center;
                    }
                }

            }
            break;
        }
        case UIPanGestureRecognizerDirectionRight: {
            
            TileHolder *neighbour = [self getNeighbourFor:pannedTile.holder relation:OnRight];
            if (!neighbour) return;
            if (neighbour.empty) {
                center = CGPointMake(center.x + translation.x,
                                     center.y);
                
                //control playground bounds
                pannedTile.center = center;
                if (CGRectGetMaxX(pannedTile.frame) >= CGRectGetMaxX(playgroundBounds)) {
                    pannedTile.center = (CGPoint){CGRectGetMaxX(playgroundBounds) - pannedTile.frame.size.width / 2, pannedTile.center.y};
                }
                if (CGRectGetMinX(pannedTile.frame) <= CGRectGetMinX(playgroundBounds)) {
                    pannedTile.center = (CGPoint){CGRectGetMinX(playgroundBounds) + pannedTile.frame.size.width / 2, pannedTile.center.y};
                }
                
                //control nearest tiles bounds
                //right
                TileHolder *nextNeighbour = [self getNeighbourFor:neighbour relation:OnRight];
                if (nextNeighbour) {
                    if (CGRectGetMaxX(pannedTile.frame) >= nextNeighbour.position.x) {
                        pannedTile.center = neighbour.center;
                    }
                }
                //left
                TileHolder *leftNeighbour = [self getNeighbourFor:pannedTile.holder relation:OnLeft];
                if (leftNeighbour) {
                    if (CGRectGetMinX(pannedTile.frame) <= leftNeighbour.position.x + pannedTile.frame.size.width) {
                        pannedTile.center = pannedTile.holder.center;
                    }
                }
            }
            break;
        }
        default: {
            break;
        }
    }
    
    [sender setTranslation:CGPointZero inView:pannedTile];
}

-(TileHolder*)getNeighbourFor:(TileHolder*)holder relation:(NeighbourRelation)relation {
    switch (relation) {
        case Above: {
            
            NSInteger aboveIndex = holder.index - colsNum;
            if (aboveIndex >= 0) {
                return holders[aboveIndex];
            }
            break;
        }
        case Below: {
            
            NSInteger aboveIndex = holder.index + colsNum;
            if (aboveIndex <= holders.count - 1) {
                return holders[aboveIndex];
            }
            break;
        }
        case OnLeft: {
            
            if ((signed int)((holder.index % colsNum) - 1) >= 0) {
                return holders[holder.index - 1];
            }
            break;
        }
        case OnRight: {
            
            if ((signed int)((holder.index % colsNum) + 1) <= colsNum - 1) {
                return holders[holder.index + 1];
            }
            break;
        }
        default:
            break;
    }
    
    return nil;
}

-(TileHolder*)getEmptyHolder {
    for (TileHolder *holder in holders)
        if (holder.empty) return holder;
    return nil;
}

-(float)distanceFrom:(CGPoint)point1 to:(CGPoint)point2
{
    CGFloat xDist = (point2.x - point1.x);
    CGFloat yDist = (point2.y - point1.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

-(Boolean)checkBoardCompleted {
    for (Tile *tile in tiles)
        if (tile.completedIndex != tile.holder.index) return false;
    return true;
}

-(NSArray*)shuffleTiles {
    
    NSMutableArray<Tile*> *sTiles = [NSMutableArray arrayWithArray:tiles];
    NSMutableArray<TileHolder*> *sHolders = [NSMutableArray arrayWithArray:holders];
    NSMutableArray<TileHolder*> *tHolders = [NSMutableArray arrayWithArray:holders];

    [sTiles shuffle];
    [sHolders shuffle];
    
    for (Tile *tile in sTiles) {
        TileHolder *holder = [sHolders objectAtIndex:[sTiles indexOfObject:tile]];
        tile.holder = holder;
        [tHolders removeObject:holder];
    }
    
    for (TileHolder *holder in holders) {
        holder.empty = NO;
    }
    
    [tHolders firstObject].empty = YES;
    
    return [NSArray arrayWithArray:sTiles];

}

@end
