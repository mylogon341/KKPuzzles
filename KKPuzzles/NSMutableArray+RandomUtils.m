//
//  NSMutableArray+RandomUtils.m
//  KKPuzzles
//
//  Created by kkuc on 06/12/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "NSMutableArray+RandomUtils.h"

@implementation NSMutableArray (RandomUtils)

-(void)shuffle
{
    NSUInteger count = [self count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSUInteger nElements = count - i;
        NSUInteger n = (arc4random() % nElements) + i;
        [self exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
}

@end
