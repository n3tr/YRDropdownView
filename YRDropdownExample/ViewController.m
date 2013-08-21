//
//  ViewController.m
//  YRDropdownViewExample
//
//  Created by Eli Perkins on 1/27/12.
//  Copyright (c) 2012 One Mighty Roar. All rights reserved.
//

#import "ViewController.h"
#import "YRDropdownView.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize demoView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setDemoView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; // (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)showInView:(id)sender {
    YRDropdownView *dropdown = [YRDropdownView dropdownInView:demoView title:@"Test" detail:@"TEsTStsjf  sijfios fsdoi fjsidf jsdiofjiosjfosjoi dsjfosj oifjsosejfos jfisdof siodfodsfoidso" image:[UIImage imageNamed:@"dropdown-alert.png"] animated:YES];
    dropdown.hideAfter = 3;
    dropdown.backgroundColors = @[[UIColor darkGrayColor],[UIColor blackColor]];
    dropdown.titleTextColor = [UIColor whiteColor];
    dropdown.titleTextShadowColor = [UIColor clearColor];
    dropdown.titleFontSize = 14.0f;
    dropdown.titleLabel.textAlignment = NSTextAlignmentCenter;
    dropdown.dismissOnTap = NO;
    [YRDropdownView presentDropdown:dropdown];
}

- (IBAction)showInWindow:(id)sender {
	UIActivityIndicatorView *accessoryView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[accessoryView startAnimating];
	
    YRDropdownView *dropdown = [YRDropdownView dropdownInView:self.view.window title:@"Warning" detail:@"Loading" accessoryView:accessoryView animated:NO];
    dropdown.hideAfter = 0;
    [YRDropdownView presentDropdown:dropdown];
}

- (IBAction)hide:(id)sender {
    [YRDropdownView hideDropdownInView:demoView animated:YES];
}

@end
