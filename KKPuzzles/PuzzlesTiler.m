//
//  PuzzlesTiler.m
//  KKPuzzles
//
//  Created by kkuc on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "PuzzlesTiler.h"
#import <EKTilesMaker/EKTilesMaker.h>
#import "UIImage+Crop.h"

@implementation PuzzlesTiler

+(id)sharedTiler {
   static PuzzlesTiler *sharedTiler = nil;
   static dispatch_once_t onceToken;
   dispatch_once(&onceToken, ^{
      sharedTiler = [[self alloc] init];
   });
   return sharedTiler;
}

-(void)tileImage:(UIImage *)image withGrid:(KKGrid)grid size:(CGSize)size completion:(void (^)(NSArray<Tile *> *))completionBlock{
   
   
   EKTilesMaker *tilesMaker = [EKTilesMaker new];
   [tilesMaker setOutputFileType:OutputFileTypeJPG];
   [tilesMaker createTiles:image
                      cols:grid.cols
                      rows:grid.rows
                      size:size
                     tiles:^(NSArray<UIImage*>*tiles,CGRect tileRect){
                        
                        NSMutableArray *ret = [NSMutableArray array];
                        for (UIImage *t in tiles) {
                           
                           //create tile image view
                           Tile *tile = [[Tile alloc] initWithImage:t];
                           tile.contentMode = UIViewContentModeScaleAspectFill;
                           
                           [tile setFrame:tileRect];
                           [ret addObject:tile];
                        }
                        completionBlock(ret.copy);
                     }];
}

@end
