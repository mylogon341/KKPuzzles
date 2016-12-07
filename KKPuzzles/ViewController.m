//
//  ViewController.m
//  KKPuzzles
//
//  Created by cris on 20/11/16.
//  Copyright © 2016 Krzysztof Kuc. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <PuzzleBoardDelegate, PuzzleBoardDataSource>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.board reloadBoard];

}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Puzzle board data source
-(NSInteger)numberOfRowsOnBoard:(PuzzleBoard *)board {
    return 3;
}

-(NSInteger)numberOfColsOnBoard:(PuzzleBoard *)board {
    return 3;
}

-(UIImage *)imageForBoard:(PuzzleBoard *)board {
    return [UIImage imageNamed:@"sample.jpg"];
}

@end
