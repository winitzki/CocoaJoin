//
//  DinPhilVCViewController.m
//  Copyright (c) 2014 Sergei Winitzki. All rights reserved.
//

#import "DinPhilVCViewController.h"

@interface DinPhilVCViewController ()
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *philLabels;
- (IBAction)restart:(id)sender;

@property (strong, nonatomic) IBOutlet DiningPhilosophicalLogic *logic;
@property (strong, nonatomic) NSArray *names;
@end

@implementation DinPhilVCViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.names = @[@"A", @"B", @"C", @"D", @"E"];
    // Do any additional setup after loading the view from its nib.
    self.logic.viewController = self;
}
- (void)viewWillAppear:(BOOL)animated {
    [self.logic initializePhilosophersAndThen:^{
        // TODO: indicate readiness to begin
    }];
    
    
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)restart:(id)sender {
    [self.logic initializePhilosophersAndThen:^{
        // TODO: indicate stopping and then readiness
    }];
}

- (void)philosopher:(NSUInteger)philosopherNumber inState:(PhilosopherState)state {
    NSString *stateString = (state == Thinking) ? @"thinking" : (state == Hungry) ? @"hungry" : @"eating";
    NSString *labelText = [NSString stringWithFormat:@"%@: %@", [self.names objectAtIndex:philosopherNumber], stateString];
    UIColor *labelColor = [@[[UIColor greenColor], [UIColor redColor], [UIColor yellowColor]] objectAtIndex:state];
    [(UILabel *)[self.philLabels objectAtIndex:philosopherNumber] setText:labelText];
    [(UILabel *)[self.philLabels objectAtIndex:philosopherNumber] setBackgroundColor:labelColor];
    
}

@end
