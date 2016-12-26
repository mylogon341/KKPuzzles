//
//  NSArray+RandomUtils.m
//  KKPuzzles
//
//  Created by kkuc on 06/12/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "NSArray+RandomUtils.h"

@implementation NSArray (RandomUtils)

-(id)pickRandomObject {
    NSUInteger count = self.count;
    
    if (count)
        return [self objectAtIndex:arc4random_uniform((unsigned int)count)];
    else
        return nil;
}

@end
