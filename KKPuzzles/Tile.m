//
//  Tile.m
//  KKPuzzles
//
//  Created by cris on 07/12/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "Tile.h"

@implementation Tile

-(id)initWithImage:(UIImageView*)image holder:(TileHolder*)holder {
    if(self = [super init]){
        _image = image;
        _holder = holder;
    }
    return self;
}

-(void)setHolder:(TileHolder*)holder{
    _holder.empty = true;
    _holder = holder;
    _holder.empty = false;
}

@end
