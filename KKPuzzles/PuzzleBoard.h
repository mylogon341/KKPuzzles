//
//  PuzzleBoard.h
//  KKPuzzles
//
//  Created by cris on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PuzzleBoard;
@protocol PuzzleBoardDataSource <NSObject>

-(NSInteger)numberOfRowsOnBoard:(PuzzleBoard*)board;
-(NSInteger)numberOfColsOnBoard:(PuzzleBoard*)board;
-(UIImage*)imageForBoard:(PuzzleBoard*)board;

@optional
-(NSIndexPath*)indexOfMissingPuzzleForBoard:(PuzzleBoard*)board;

@end

@protocol PuzzleBoardDelegate <NSObject>
@optional
-(void)boardCompleted:(PuzzleBoard*)board;

@end

@interface PuzzleBoard : UIView

@property(nonatomic, weak) IBOutlet __nullable id<PuzzleBoardDataSource> dataSource;
@property(nonatomic, weak) IBOutlet __nullable id<PuzzleBoardDelegate> delegate;
@property(nonatomic, readonly, getter=isCompleted) BOOL completed;

-(void)shuffle;

@end
