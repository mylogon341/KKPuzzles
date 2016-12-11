//
//  PuzzlesTiler.h
//  KKPuzzles
//
//  Created by kkuc on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Tile.h"

typedef struct KKGrid {
    uint8_t rows;
    uint8_t cols;
}KKGrid;

@interface PuzzlesTiler : NSObject

+(id)sharedTiler;
-(void)tileImage:(UIImage*)image withGrid:(KKGrid)grid size:(CGSize)size completion:(void (^)(NSArray<Tile*>*, NSError*))completionBlock;

@end
