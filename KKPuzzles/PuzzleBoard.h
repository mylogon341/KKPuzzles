//
//  PuzzleBoard.h
//  KKPuzzles
//
//  Created by kkuc on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PuzzleBoard;
@protocol PuzzleBoardDataSource <NSObject>

-(NSInteger)numberOfRowsOnBoard:(PuzzleBoard* _Nonnull)board;
-(NSInteger)numberOfColsOnBoard:(PuzzleBoard* _Nonnull)board;
-(UIImage* _Nonnull)imageForBoard:(PuzzleBoard* _Nonnull)board;
@optional
-(NSUInteger)indexOfMissingPuzzleForBoard:(PuzzleBoard* _Nonnull)board;

@end

@protocol PuzzleBoardDelegate <NSObject>
@optional
-(void)boardCompleted:(PuzzleBoard* _Nonnull)board;
-(void)puzzleMoveMade:(NSDictionary* _Nonnull)positions missingTileIndex:(int)missingTileIndex;

@end

@interface PuzzleBoard : UIView

@property(nonatomic, assign) IBOutlet __nullable id<PuzzleBoardDataSource> dataSource;
@property(nonatomic, assign) IBOutlet __nullable id<PuzzleBoardDelegate> delegate;
@property(nonatomic, readonly, getter=isCompleted) BOOL completed;

-(void)shuffle;
-(void)reload:(void(^)(void))complete;
-(void)reloadWithPosition:(NSDictionary*)positions missingPieceIndex:(int)missingPiece complete:(void(^)(void))complete;
-(void)redraw:(BOOL)animate;

@end
