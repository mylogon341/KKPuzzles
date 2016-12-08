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
    
    rowsNum = [self.dataSource numberOfRowsOnBoard:self];
    colsNum = [self.dataSource numberOfColsOnBoard:self];
    NSUInteger missingTileIndex = [self.dataSource respondsToSelector:@selector(indexOfMissingPuzzleForBoard:)] ? [self.dataSource indexOfMissingPuzzleForBoard:self] : colsNum * (rowsNum - 1);
    missingTileIndex = missingTileIndex <= rowsNum * colsNum - 1 ? missingTileIndex : colsNum * (rowsNum - 1);
    
    [[PuzzlesTiler sharedTiler] tileImage:[_dataSource imageForBoard:self] withGrid:(KKGrid){rowsNum, colsNum} size:self.frame.size completion:^(NSArray<Tile*> *t, NSError *error) {
        
        CGFloat verticalOffset = 0.0, horizontalOffset = 0.0;
        CGPoint topLeft, bottomRight;
        
        if (!error && t.count > 0) {
            horizontalOffset = (self.frame.size.width - t[0].frame.size.width * colsNum) / 2.0;
            verticalOffset = (self.frame.size.height - t[0].frame.size.height * rowsNum) / 2.0;
        }
        
        NSMutableArray<Tile*> *tTiles = [NSMutableArray arrayWithArray:t];
        NSMutableArray<TileHolder*> *tHolders = [NSMutableArray array];
        
        for (Tile *tile in tTiles) {
            
            NSUInteger index = [tTiles indexOfObject:tile];
            
            tile.frame = (CGRect){horizontalOffset + tile.frame.size.width * ((index % colsNum)), verticalOffset + tile.frame.size.height * (index / colsNum), tile.frame.size.width, tile.frame.size.height};
            
            UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            [tile setUserInteractionEnabled:true];
            [tile addGestureRecognizer:pgr];
            
            TileHolder *holder = [[TileHolder alloc] init];
            holder.index = index;
            holder.position = tile.frame.origin;
            holder.center = tile.center;
            [tHolders addObject:holder];
            
            tile.holder= holder;
            tile.completedIndex = index;
            
            [self addSubview:tile];
            
            if (tile == [tTiles firstObject]) { //top left
                topLeft = (CGPoint){CGRectGetMinX(tile.frame), CGRectGetMinY(tile.frame)};
            }else if(tile == [tTiles lastObject]){ //bottom right
                bottomRight = (CGPoint){CGRectGetMaxX(tile.frame), CGRectGetMaxY(tile.frame)};
            }
        }
        
        //remove missing tile
        missingTile = tTiles[missingTileIndex];
        [tTiles[missingTileIndex] removeFromSuperview];
        tTiles[missingTileIndex].holder = nil;
        [tTiles removeObjectAtIndex:missingTileIndex];
        
        holders = [NSArray arrayWithArray:tHolders];
        tiles = [NSArray arrayWithArray:tTiles];
        
        playgroundBounds = CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);
        
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

-(void)boardCompleted {
    //add missing tile
    [self addSubview:missingTile];
    [self setUserInteractionEnabled:false];
    [self.delegate respondsToSelector:@selector(boardCompleted:)] ? [self.delegate boardCompleted:self] : nil;
}

@end
