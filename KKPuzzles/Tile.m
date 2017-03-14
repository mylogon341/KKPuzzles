//
//  Tile.m
//  KKPuzzles
//
//  Created by kkuc on 07/12/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "Tile.h"

@implementation Tile

-(id)init{
    if (self = [super init]) {
        _holder = nil;
    }
    return self;
}

-(void)setHolder:(TileHolder*)holder{
    //old holder set to empty
    _holder.empty = true;
    
    //new holder assigned and marked as not empty
    _holder = holder;
    _holder.empty = false;
}

@end
