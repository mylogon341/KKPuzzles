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

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(orientationChanged)
                                                   name:UIDeviceOrientationDidChangeNotification
                                                 object:nil];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.board reload];
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)shuffleBoard:(id)sender {
    [self.board shuffle];
}

-(void)orientationChanged {
    [self.view layoutIfNeeded];
    [self.board redraw];
}

#pragma mark - Puzzle board data source
-(NSInteger)numberOfRowsOnBoard:(PuzzleBoard *)board {
    return 3;
}

-(NSInteger)numberOfColsOnBoard:(PuzzleBoard *)board {
    return 2;
}

-(UIImage *)imageForBoard:(PuzzleBoard *)board {
    return [UIImage imageNamed:@"sample.jpg"];
}

-(void)boardCompleted:(PuzzleBoard *)board {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:@"Board completed" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alert animated:true completion:nil];
}

@end
