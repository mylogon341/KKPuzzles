//
//  PuzzlesTiler.m
//  KKPuzzles
//
//  Created by cris on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "PuzzlesTiler.h"
#import <EKTilesMaker/EKTilesMaker.h>

@implementation PuzzlesTiler

+(id)sharedTiler {
    static PuzzlesTiler *sharedTiler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTiler = [[self alloc] init];
    });
    return sharedTiler;
}

-(void)tileImage:(UIImage *)image withGrid:(KKGrid)grid size:(CGSize)size completion:(void (^)(NSArray<UIImage *> *, NSError*))completionBlock{
    
    //set tiles destination path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directoryPath = [paths objectAtIndex:0];
    NSString *tilesDestinationPath = [directoryPath stringByAppendingPathComponent:@"tiles"];
    NSString *prefix = @"tile";
    
    [[NSFileManager defaultManager] removeItemAtPath:tilesDestinationPath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:tilesDestinationPath withIntermediateDirectories:false attributes:nil error:nil];
    
    NSString *imagePath = [tilesDestinationPath stringByAppendingPathComponent:@"orig.png"];
    NSError *error = nil;
    [UIImagePNGRepresentation(image) writeToFile:imagePath options:(NSDataWritingAtomic) error:&error];

    //check if file succesfully written
    if (error){
        completionBlock(nil, error);
        return;
    }
    
    //calculate zoom that aspect fits grid size
    float heightRatio = size.height/image.size.height;
    float widthRatio = size.width/image.size.width;
    float zoom = image.size.height > image.size.width ? heightRatio : widthRatio;
    
    //calculate tile size
    float tileWidth = grid.cols != 0 ? ceil(image.size.width/grid.cols*zoom) : ceil(image.size.width*zoom);
    float tileHeight = grid.rows != 0 ? ceil(image.size.height/grid.rows*zoom) : ceil(image.size.height*zoom);

    EKTilesMaker *tilesMaker = [EKTilesMaker new];
    [tilesMaker setSourceImagePath:imagePath];
    [tilesMaker setOutputFolderPath:tilesDestinationPath];
    [tilesMaker setOutputFileName:prefix];
    [tilesMaker setZoomLevels:@[@(zoom)]];
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
            [ret addObject:[UIImage imageWithContentsOfFile:[tilesDestinationPath stringByAppendingPathComponent:tileFile]]];
        }
        
        completionBlock([NSArray arrayWithArray:ret], nil);
    }];
    
    [tilesMaker createTiles];
}


@end
