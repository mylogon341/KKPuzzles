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
   
   //calculate zoom that aspect fits grid size
   float heightRatio = size.height/image.size.height;
   float widthRatio = size.width/image.size.width;
   float scaleRatio = image.size.height > image.size.width ? heightRatio : widthRatio;
   
   //calculate tile size
   float tileWidth = grid.cols != 0 ? floor(image.size.width/grid.cols) : floor(image.size.width);
   float tileHeight = grid.rows != 0 ? floor(image.size.height/grid.rows) : floor(image.size.height);
   
   EKTilesMaker *tilesMaker = [EKTilesMaker new];
   [tilesMaker setTileSize:(CGSize){tileWidth,tileHeight}];
   [tilesMaker setOutputFileType:OutputFileTypeJPG];
   [tilesMaker createTiles:image
                     tiles:^(NSArray<UIImage*>* tiles){
                        
                        NSMutableArray *ret = [NSMutableArray array];
                        for (UIImage *tile in tiles) {
                           
                           //create tile image view
                           Tile *tile = [[Tile alloc] initWithImage:tile];
                           tile.contentMode = UIViewContentModeScaleAspectFill;
                           
                           [tile setFrame:(CGRect){0.0, 0.0, floor(scaleRatio * tileWidth), floor(scaleRatio * tileHeight)}];
                           [ret addObject:tile];
                        }
                        completionBlock(ret.copy);
                     }];
}

@end
