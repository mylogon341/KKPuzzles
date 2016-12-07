
//  TileHolder.h
//  KKPuzzles
//
//  Created by cris on 07/12/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TileHolder : NSObject

@property(nonatomic) NSUInteger index;
@property(nonatomic) CGPoint position;
@property(nonatomic) CGPoint center;
@property(nonatomic) Boolean empty;

@end
