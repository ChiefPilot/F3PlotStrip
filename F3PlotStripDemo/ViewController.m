//
//  ViewController.m
//  F3PlotStrip
//
//  Created by Brad Benson on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ViewController.h"

@interface ViewController()
{
@private
    NSTimer     *m_timer;       // Timer for updating values
}

@property (weak, nonatomic) IBOutlet UISlider       *valueSlider;
@property (weak, nonatomic) IBOutlet F3PlotStrip    *plotStrip;
@property (weak, nonatomic) IBOutlet UILabel        *plotStripLabel;
@property (weak, nonatomic) IBOutlet F3PlotStrip    *sliderPlotStrip;
@property (weak, nonatomic) IBOutlet UILabel        *sliderPlotLabel;
@property (weak, nonatomic) IBOutlet F3PlotStrip    *tempPlotStrip;
@property (weak, nonatomic) IBOutlet UILabel        *tempPlotLabel;
@property (weak, nonatomic) IBOutlet F3PlotStrip    *humidityPlotStrip;
@property (weak, nonatomic) IBOutlet UILabel        *humidityPlotLabel;
@property (weak, nonatomic) IBOutlet F3PlotStrip    *pressurePlotStrip;
@property (weak, nonatomic) IBOutlet UILabel        *pressurePlotLabel;
@property (weak, nonatomic) IBOutlet UIButton       *resetButton;

- (void) didGetTimerEvent:(NSTimer *)a_timer;
- (IBAction)didChangeSlider:(id)sender;
- (IBAction)didReset:(id)sender;
@end




@implementation ViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Configure the view
  UIImage *img = [UIImage imageNamed:@"background.png"];
  UIColor *clr = [[UIColor alloc] initWithPatternImage:img];
  [self.view setBackgroundColor:clr];
  
  // Configure the reset button
  UIImage *imgBg = [UIImage imageNamed:@"RedBtnBg"];
  UIImage *imgBtnBg = [imgBg stretchableImageWithLeftCapWidth:12 topCapHeight:0];
  [self.resetButton setBackgroundImage:imgBtnBg
                              forState:UIControlStateNormal];
  
  // Configure the plotter strip
  // ... This strip has high/low limits specified
  self.plotStrip.lowerLimit = -1.0f;
  self.plotStrip.upperLimit = 1.0f;
  self.plotStrip.capacity = 300;
  self.plotStrip.lineColor = [UIColor greenColor];
  self.plotStrip.showDot = YES;
  self.plotStrip.labelFormat = @"Timer-driven: (%0.02f)";
  self.plotStrip.label = self.plotStripLabel;
  
  // Configure the slider plot strip
  // ... This strip figures out the high/low limits dynamically
  self.sliderPlotStrip.capacity = 300;
  self.sliderPlotStrip.baselineValue = 0.0;
  self.sliderPlotStrip.lineColor = [UIColor redColor];
  self.sliderPlotStrip.showDot = YES;
  self.sliderPlotStrip.labelFormat = @"Event-driven w/baseline: (%0.02f)";
  self.sliderPlotStrip.label = self.sliderPlotLabel;
  
  // Configure the temperature plot strip (sparkline)
  NSArray *array = [NSArray arrayWithObjects:[NSNumber numberWithFloat:68.1f],
                                             [NSNumber numberWithFloat:70.2f],
                                             [NSNumber numberWithFloat:71.3f],
                                             [NSNumber numberWithFloat:72.4f],
                                             [NSNumber numberWithFloat:73.5f],
                                             [NSNumber numberWithFloat:70.6f],
                                             nil];
  self.tempPlotStrip.showDot = YES;
  self.tempPlotStrip.capacity = (int)array.count;
  self.tempPlotStrip.data = array;
  self.tempPlotStrip.lineColor = [UIColor darkGrayColor];
  self.tempPlotStrip.labelFormat = @"%0.1f °F";
  self.tempPlotStrip.label = self.tempPlotLabel;
  
  // Configure the humidity plot strip
  array = [NSArray arrayWithObjects:[NSNumber numberWithFloat:57.1f],
                                    [NSNumber numberWithFloat:59.2f],
                                    [NSNumber numberWithFloat:74.3f],
                                    [NSNumber numberWithFloat:68.4f],
                                    [NSNumber numberWithFloat:62.5f],
                                    [NSNumber numberWithFloat:60.6f],
                                    nil];
  self.humidityPlotStrip.showDot = YES;
  self.humidityPlotStrip.capacity = (int)array.count;
  self.humidityPlotStrip.data = array;
  self.humidityPlotStrip.lineColor = [UIColor blueColor];
  self.humidityPlotStrip.labelFormat = @"%0.1f %%";
  self.humidityPlotStrip.label = self.humidityPlotLabel;

  // Configure the humidity plot strip
  array = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.12f],
                                    [NSNumber numberWithFloat:1.31f],
                                    [NSNumber numberWithFloat:1.41f],
                                    [NSNumber numberWithFloat:1.35f],
                                    [NSNumber numberWithFloat:1.12f],
                                    [NSNumber numberWithFloat:1.60f],
                                    nil];
  self.pressurePlotStrip.showDot = YES;
  self.pressurePlotStrip.capacity = (int)array.count;
  self.pressurePlotStrip.data = array;
  self.pressurePlotStrip.lineColor = [UIColor yellowColor];
  self.pressurePlotStrip.labelFormat = @"%0.2f PSI";
  self.pressurePlotStrip.label = self.pressurePlotLabel;
  
  
  // Start the timer to provide data
  m_timer = [NSTimer scheduledTimerWithTimeInterval:0.100f 
                                             target:self 
                                           selector:@selector(didGetTimerEvent:) 
                                           userInfo:nil 
                                            repeats:YES];
}

- (void) didGetTimerEvent:(NSTimer *)a_timer
{
  // Add current slider value to plot strip
  self.plotStrip.value = self.valueSlider.value;
}

- (IBAction)didChangeSlider:(id)sender {
  // Copy the value to the plot strip
  self.sliderPlotStrip.value = self.valueSlider.value;
}

- (IBAction)didReset:(id)sender {
  // Clear the plotter strips
  [self.plotStrip clear];
  [self.sliderPlotStrip clear];
}


@end
