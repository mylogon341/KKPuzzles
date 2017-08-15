//
//  PuzzleBoard.m
//  KKPuzzles
//
//  Created by kkuc on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "PuzzleBoard.h"
#import "PuzzlesTiler.h"
#import "NSArray+RandomUtils.h"
#import "Tile.h"
#import "TileHolder.h"

typedef enum : NSUInteger {
   Above,
   Below,
   OnLeft,
   OnRight
} NeighbourRelation;


@interface PuzzleBoard () <UIGestureRecognizerDelegate>

@property(nonatomic) NSUInteger rowsNum;
@property(nonatomic) NSUInteger colsNum;

@end

@implementation PuzzleBoard {
   CGRect playgroundBounds;
   NSMutableArray<Tile*> *tiles;
   NSArray<TileHolder*> *holders;
   NSMutableDictionary<TileHolder*, Tile*> *currentState;
   
   NSUInteger missingTileIndex;
   
   Tile *missingTile;
   Tile *pannedTile;
   
}

@synthesize rowsNum;
@synthesize colsNum;

-(BOOL)isCompleted {
   return [self checkBoardCompleted];
}

-(void)reloadWithPosition:(NSDictionary *)positions
        missingPieceIndex:(int)missingPiece
                 complete:(void (^)(void))complete{
   
   [self reload:^{
      
      for (NSNumber * completedIndex in positions.allKeys) {
         int tileHolderPos = [[positions objectForKey:completedIndex] intValue];
         
         for (TileHolder * tileHolder in currentState.allKeys) {
            
            if (tileHolder.index == tileHolderPos && completedIndex != 0) {
               Tile * tile = tiles[completedIndex.intValue];
               [tile setHolder:tileHolder];
               currentState[tileHolder] = tile;
               break;
            }
            
         }
      }
      
      for (TileHolder*th in holders) {
         th.empty = false;
      }
      
      for (int i = (int)tiles.count-1; i >= 0; i--) {
         if (tiles[i].completedIndex == 0) {
            [tiles removeObject:tiles[i]];
         }
      }
      
      TileHolder * emptyHolder = holders[missingPiece];
      //      Tile * emptyTile = currentState[emptyHolder];
      emptyHolder.empty = true;
      currentState[emptyHolder] = nil;
      
      [self redraw:false];
   }];
   
}

-(void)reload:(void(^)(void))complete {
   
   if (!_dataSource) return;
   
   rowsNum = [self.dataSource numberOfRowsOnBoard:self];
   colsNum = [self.dataSource numberOfColsOnBoard:self];
   missingTileIndex = [self.dataSource respondsToSelector:@selector(indexOfMissingPuzzleForBoard:)] ? [self.dataSource indexOfMissingPuzzleForBoard:self] : colsNum * (rowsNum - 1);
   missingTileIndex = missingTileIndex <= rowsNum * colsNum - 1 ? missingTileIndex : colsNum * (rowsNum - 1);
   
   currentState = [NSMutableDictionary dictionary];
   
   [[PuzzlesTiler new] tileImage:[_dataSource imageForBoard:self]
                        withGrid:(KKGrid){rowsNum, colsNum}
                            size:self.frame.size
                      completion:^(NSArray<Tile*> *t) {
                         
                         NSMutableArray<Tile*> *tTiles = [NSMutableArray arrayWithArray:t];
                         NSMutableArray<TileHolder*> *tHolders = [NSMutableArray array];
                         
                         for (Tile *tile in tTiles) {
                            
                            NSUInteger index = [tTiles indexOfObject:tile];
                            
                            TileHolder *holder = [[TileHolder alloc] init];
                            holder.index = index;
                            [tHolders addObject:holder];
                            
                            tile.holder = holder;
                            tile.completedIndex = index;
                            
                            currentState[holder] = tile;
                         }
                         
                         holders = [NSArray arrayWithArray:tHolders];
                         tiles = [NSMutableArray arrayWithArray:tTiles];
                         
                         tTiles = nil;
                         tHolders = nil;
                         
                         [self redraw:false];
                         
                         if (complete) {
                            complete();
                         }
                      }];
}

-(void)redraw:(BOOL)animate {
   
   for (UIView* view in self.subviews) {
      [view removeFromSuperview];
   }
   
   if (tiles.count == 0) return;
   
   CGPoint topLeft, bottomRight;
   
   
   CGFloat tileWidth = self.frame.size.width/colsNum;
   CGFloat tileHeight = self.frame.size.height/rowsNum;
   
   for (TileHolder *holder in holders) {
      holder.position = (CGPoint){tileWidth * ((holder.index % colsNum)), tileHeight * (holder.index / colsNum)};
      
      holder.center = CGPointApplyAffineTransform(holder.position, CGAffineTransformMakeTranslation(tileWidth/2, tileHeight/2));
      
      if (holder == [holders firstObject]) { //top left
         topLeft = holder.position;
      }else if(holder == [holders lastObject]){ //bottom right
         bottomRight = CGPointApplyAffineTransform(holder.position, CGAffineTransformMakeTranslation(tileWidth, tileHeight));
      }
      
   }
   
   for (Tile *tile in tiles) {
      
      [UIView animateWithDuration:animate ? 0.6 : 0
                       animations:^{
                          tile.frame = (CGRect){tile.holder.position.x, tile.holder.position.y, tileWidth, tileHeight};
                       }];
      
      UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
      [pgr setMaximumNumberOfTouches:1];
      [pgr setDelegate:self];
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
   
   //remove missing tile
   missingTile = tiles[missingTileIndex];
   tiles[missingTileIndex].holder = nil;
   [tiles removeObject:missingTile];
   
   [self shuffleTiles];
   [self redraw:true];
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
         
         [self setUserInteractionEnabled:false];
         
         if ([self distanceFrom:empty.center to:pannedTile.center] <= [self distanceFrom:currentHolder.center to:pannedTile.center]) {
            [UIView animateWithDuration:0.2 animations:^{
               pannedTile.center = empty.center;
            } completion:^(BOOL finished) {
               pannedTile.holder = empty;
               currentState[currentHolder] = nil;
               currentState[empty] = pannedTile;
               [self setUserInteractionEnabled:true];
               pannedTile = nil;
               [self checkBoardCompleted] ? [self boardCompleted] : nil;
               
               [self updateSave];
            }];
         }else{
            [UIView animateWithDuration:0.2 animations:^{
               pannedTile.center = currentHolder.center;
            } completion:^(BOOL finished) {
               [self setUserInteractionEnabled:true];
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

-(void)updateSave{
   if ([_delegate respondsToSelector:@selector(puzzleMoveMade:missingTileIndex:)]) {
      NSMutableDictionary * pos = [NSMutableDictionary new];
      
      for (Tile * t in tiles) {
         if (!t.holder.empty) {
            [pos setObject:@(t.holder.index) forKey:@(t.completedIndex)];
         }
      }
      
      [_delegate puzzleMoveMade:pos missingTileIndex:[self getEmptyHolder].index];
   }
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

-(void)shuffleTiles {
   for (int i = 0; i < (rowsNum*colsNum*10); i++) {
      
      TileHolder *empty = [self getEmptyHolder];
      NSArray *relations = @[@(Above), @(Below), @(OnLeft), @(OnRight)];
      
      TileHolder *neighbour;
      
      while (!neighbour) {
         NeighbourRelation randomRelation = ((NSNumber*)[[NSArray arrayWithArray:relations] pickRandomObject]).integerValue;
         neighbour = [self getNeighbourFor:empty relation:randomRelation];
      }
      
      Tile *tile = currentState[neighbour];
      tile.holder = empty;
      currentState[empty] = tile;
      currentState[neighbour] = nil;
   }
}

#pragma mark UIGestureRecognizer delegate

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
   return !pannedTile;
}

@end

