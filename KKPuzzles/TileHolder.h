
//  TileHolder.h
//  KKPuzzles
//
//  Created by kkuc on 07/12/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TileHolder : NSObject <NSCopying>

@property(nonatomic) NSUInteger index;
@property(nonatomic) CGPoint position;
@property(nonatomic) CGPoint center;
@property(nonatomic) BOOL empty;

@end
