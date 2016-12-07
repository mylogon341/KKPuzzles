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
    NSUInteger missingTileIndex = [self.dataSource respondsToSelector:@selector(indexOfMissingPuzzleForBoard:)] ? [self.dataSource indexOfMissingPuzzleForBoard:self] : rowsNum * (colsNum - 1);
    missingTileIndex = missingTileIndex <= rowsNum * colsNum - 1 ? missingTileIndex : rowsNum * (colsNum - 1);
    
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
            
            tile.frame = (CGRect){horizontalOffset + tile.frame.size.width * ((index % colsNum)), verticalOffset + tile.frame.size.height * (index / rowsNum), tile.frame.size.width, tile.frame.size.height};
            
            UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
            [tile setUserInteractionEnabled:true];
            [tile addGestureRecognizer:pgr];
            
            TileHolder *holder = [[TileHolder alloc] init];
            holder.index = index;
            holder.position = tile.frame.origin;
            holder.center = tile.center;
            [tHolders addObject:holder];
            
            tile.holder= holder;
            
            [self addSubview:tile];
            
            if (tile == [tTiles firstObject]) { //top left
                topLeft = (CGPoint){CGRectGetMinX(tile.frame), CGRectGetMinY(tile.frame)};
            }else if(tile == [tTiles lastObject]){ //bottom right
                bottomRight = (CGPoint){CGRectGetMaxX(tile.frame), CGRectGetMaxY(tile.frame)};
            }
        }
        
        //remove missing tile
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

            break;
        }
            
        case UIGestureRecognizerStateEnded:{
            
            TileHolder *empty = [self getEmptyHolder];
            TileHolder *currentHolder = ((Tile*)sender.view).holder;

            if ([self distanceFrom:empty.center to:sender.view.center] <= [self distanceFrom:currentHolder.center to:sender.view.center]) {
                [UIView animateWithDuration:0.2 animations:^{
                    sender.view.center = empty.center;
                } completion:^(BOOL finished) {
                    ((Tile*)sender.view).holder = empty;
                }];
            }else{
                [UIView animateWithDuration:0.2 animations:^{
                    sender.view.center = currentHolder.center;
                }];
            }
            
            break;
        }
            
        default:
            break;
    }
    
    CGPoint center = sender.view.center;
    CGPoint translation = [sender translationInView:sender.view];
    
    switch (direction) {
        case UIPanGestureRecognizerDirectionUp: {
            
            TileHolder *neighbour = [self getNeighbourFor:((Tile*)sender.view).holder relation:Above];
            if (!neighbour) return;
            if (neighbour.empty) {
                center = CGPointMake(center.x,
                                     center.y + translation.y);
                
                //control playground bounds
                sender.view.center = center;
                if (CGRectGetMaxY(sender.view.frame) >= CGRectGetMaxY(playgroundBounds)) {
                    sender.view.center = (CGPoint){sender.view.center.x, CGRectGetMaxY(playgroundBounds) - sender.view.frame.size.height / 2};
                }
                if (CGRectGetMinY(sender.view.frame) <= CGRectGetMinY(playgroundBounds)) {
                    sender.view.center = (CGPoint){sender.view.center.x, CGRectGetMinY(playgroundBounds) + sender.view.frame.size.height / 2};
                }
                
                //control nearest tiles bounds
                //above
                TileHolder *nextNeighbour = [self getNeighbourFor:neighbour relation:Above];
                if (nextNeighbour) {
                    if (CGRectGetMinY(sender.view.frame) <= nextNeighbour.position.y + sender.view.frame.size.height) {
                        sender.view.center = neighbour.center;
                    }
                }
                //below
                TileHolder *belowNeighbour = [self getNeighbourFor:((Tile*)sender.view).holder relation:Below];
                if (belowNeighbour) {
                    if (CGRectGetMaxY(sender.view.frame) >= belowNeighbour.position.y) {
                        sender.view.center = ((Tile*)sender.view).holder.center;
                    }
                }
                
            }
            break;
        }
        case UIPanGestureRecognizerDirectionDown: {
            
            TileHolder *neighbour = [self getNeighbourFor:((Tile*)sender.view).holder relation:Below];
            if (!neighbour) return;
            if (neighbour.empty) {
                center = CGPointMake(center.x,
                                     center.y + translation.y);
                
                //control playground bounds
                sender.view.center = center;
                if (CGRectGetMaxY(sender.view.frame) >= CGRectGetMaxY(playgroundBounds)) {
                    sender.view.center = (CGPoint){sender.view.center.x, CGRectGetMaxY(playgroundBounds) - sender.view.frame.size.height / 2};
                }
                if (CGRectGetMinY(sender.view.frame) <= CGRectGetMinY(playgroundBounds)) {
                    sender.view.center = (CGPoint){sender.view.center.x, CGRectGetMinY(playgroundBounds) + sender.view.frame.size.height / 2};
                }
                
                //control nearest tiles bounds
                //below
                TileHolder *nextNeighbour = [self getNeighbourFor:neighbour relation:Below];
                if (nextNeighbour) {
                    if (CGRectGetMaxY(sender.view.frame) >= nextNeighbour.position.y) {
                        sender.view.center = neighbour.center;
                    }
                }
                //above
                TileHolder *aboveNeighbour = [self getNeighbourFor:((Tile*)sender.view).holder relation:Above];
                if (aboveNeighbour) {
                    if (CGRectGetMinY(sender.view.frame) <= aboveNeighbour.position.y + sender.view.frame.size.height) {
                        sender.view.center = ((Tile*)sender.view).holder.center;
                    }
                }

            }
            break;
        }
        case UIPanGestureRecognizerDirectionLeft: {
            
            TileHolder *neighbour = [self getNeighbourFor:((Tile*)sender.view).holder relation:OnLeft];
            if (!neighbour) return;
            if (neighbour.empty) {
                center = CGPointMake(center.x + translation.x,
                                     center.y);
                
                //control playground bounds
                sender.view.center = center;
                if (CGRectGetMaxX(sender.view.frame) >= CGRectGetMaxX(playgroundBounds)) {
                    sender.view.center = (CGPoint){CGRectGetMaxX(playgroundBounds) - sender.view.frame.size.width / 2, sender.view.center.y};
                }
                if (CGRectGetMinX(sender.view.frame) <= CGRectGetMinX(playgroundBounds)) {
                    sender.view.center = (CGPoint){CGRectGetMinX(playgroundBounds) + sender.view.frame.size.width / 2, sender.view.center.y};
                }
                
                //control nearest tiles bounds
                //left
                TileHolder *nextNeighbour = [self getNeighbourFor:neighbour relation:OnLeft];
                if (nextNeighbour) {
                    if (CGRectGetMinX(sender.view.frame) <= nextNeighbour.position.x + sender.view.frame.size.width) {
                        sender.view.center = neighbour.center;
                    }
                }
                //right
                TileHolder *rightNeighbour = [self getNeighbourFor:((Tile*)sender.view).holder relation:OnRight];
                if (rightNeighbour) {
                    if (CGRectGetMaxX(sender.view.frame) >= rightNeighbour.position.x) {
                        sender.view.center = ((Tile*)sender.view).holder.center;
                    }
                }

            }
            break;
        }
        case UIPanGestureRecognizerDirectionRight: {
            
            TileHolder *neighbour = [self getNeighbourFor:((Tile*)sender.view).holder relation:OnRight];
            if (!neighbour) return;
            if (neighbour.empty) {
                center = CGPointMake(center.x + translation.x,
                                     center.y);
                
                //control playground bounds
                sender.view.center = center;
                if (CGRectGetMaxX(sender.view.frame) >= CGRectGetMaxX(playgroundBounds)) {
                    sender.view.center = (CGPoint){CGRectGetMaxX(playgroundBounds) - sender.view.frame.size.width / 2, sender.view.center.y};
                }
                if (CGRectGetMinX(sender.view.frame) <= CGRectGetMinX(playgroundBounds)) {
                    sender.view.center = (CGPoint){CGRectGetMinX(playgroundBounds) + sender.view.frame.size.width / 2, sender.view.center.y};
                }
                
                //control nearest tiles bounds
                //right
                TileHolder *nextNeighbour = [self getNeighbourFor:neighbour relation:OnRight];
                if (nextNeighbour) {
                    if (CGRectGetMaxX(sender.view.frame) >= nextNeighbour.position.x) {
                        sender.view.center = neighbour.center;
                    }
                }
                //left
                TileHolder *leftNeighbour = [self getNeighbourFor:((Tile*)sender.view).holder relation:OnLeft];
                if (leftNeighbour) {
                    if (CGRectGetMinX(sender.view.frame) <= leftNeighbour.position.x + sender.view.frame.size.width) {
                        sender.view.center = ((Tile*)sender.view).holder.center;
                    }
                }
            }
            break;
        }
        default: {
            break;
        }
    }
    
    [sender setTranslation:CGPointZero inView:sender.view];
}

-(TileHolder*)getNeighbourFor:(TileHolder*)holder relation:(NeighbourRelation)relation {
    switch (relation) {
        case Above: {
            
            NSInteger aboveIndex = holder.index - rowsNum;
            if (aboveIndex >= 0) {
                return holders[aboveIndex];
            }
            break;
        }
        case Below: {
            
            NSInteger aboveIndex = holder.index + rowsNum;
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

@end
