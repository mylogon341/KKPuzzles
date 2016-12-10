//
//  Tile.h
//  KKPuzzles
//
//  Created by cris on 07/12/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TileHolder.h"

@interface Tile : UIImageView

@property (nonatomic, strong) TileHolder* holder;
@property (nonatomic) NSUInteger completedIndex;

@end
