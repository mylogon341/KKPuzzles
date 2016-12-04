//
//  PuzzlesTiler.m
//  KKPuzzles
//
//  Created by cris on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "PuzzlesTiler.h"
#import <EKTilesMaker/EKTilesMaker.h>
#import "UIImage+Crop.h"
#import <SpriteKit/SpriteKit.h>

@implementation PuzzlesTiler

+(id)sharedTiler {
    static PuzzlesTiler *sharedTiler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTiler = [[self alloc] init];
    });
    return sharedTiler;
}

-(void)tileImage:(UIImage *)image withGrid:(KKGrid)grid size:(CGSize)size completion:(void (^)(NSArray<SKSpriteNode *> *, NSError*))completionBlock{

    //set tiles destination path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths objectAtIndex:0];
    NSString *tilesDestinationPath = [directoryPath stringByAppendingPathComponent:@"tiles"];
    NSString *prefix = @"tile";
    
    [[NSFileManager defaultManager] removeItemAtPath:tilesDestinationPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:tilesDestinationPath withIntermediateDirectories:false attributes:nil error:nil];
    
    NSString *imagePath = [tilesDestinationPath stringByAppendingPathComponent:@"orig.png"];
    NSError *error = nil;
    
    //calculate zoom that aspect fits grid size
    float heightRatio = size.height/image.size.height;
    float widthRatio = size.width/image.size.width;
    float scaleRatio = image.size.height > image.size.width ? heightRatio : widthRatio;
    
    //calculate tile size
    float tileWidth = grid.cols != 0 ? floor(image.size.width/grid.cols) : floor(image.size.width);
    float tileHeight = grid.rows != 0 ? floor(image.size.height/grid.rows) : floor(image.size.height);
    
    [UIImagePNGRepresentation(image) writeToFile:imagePath options:(NSDataWritingAtomic) error:&error];

    //check if file succesfully written
    if (error){
        completionBlock(nil, error);
        return;
    }

    EKTilesMaker *tilesMaker = [EKTilesMaker new];
    [tilesMaker setSourceImagePath:imagePath];
    [tilesMaker setOutputFolderPath:tilesDestinationPath];
    [tilesMaker setOutputFileName:prefix];
    [tilesMaker setTileSize:(CGSize){tileWidth,tileHeight}];
    [tilesMaker setOutputFileType:OutputFileTypePNG];
    [tilesMaker setCompletionBlock:^{
        
        //remove original image from disk
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:&error];
        
        //check if file succesfully removed
        if (error){
            completionBlock(nil, error);
            return;
        }
        
        NSArray *tileFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tilesDestinationPath error:&error];
        
        if (error){
            completionBlock(nil, error);
            return;
        }
        
        NSMutableArray *ret = [NSMutableArray array];
        for (NSString *tileFile in tileFiles) {
                        
            //create sprite
            SKSpriteNode *tile = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithCGImage:[UIImage imageWithContentsOfFile:[tilesDestinationPath stringByAppendingPathComponent:tileFile]].CGImage]];
            [tile setSize:(CGSize){floor(scaleRatio * tileWidth), floor(scaleRatio * tileHeight)}];
            tile.anchorPoint = (CGPoint){0.0, 0.0};

            [ret addObject:tile];
        }
        
        completionBlock([NSArray arrayWithArray:ret], nil);
    }];
    
    [tilesMaker createTiles];
}


@end
