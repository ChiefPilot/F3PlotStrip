//
//  ViewController.m
//  F3PlotStrip
//
//  Created by Brad Benson on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ViewController.h"

@implementation ViewController
@synthesize valueSlider;
@synthesize plotStrip;
@synthesize plotStripLabel;
@synthesize sliderPlotStrip;
@synthesize sliderPlotLabel;
@synthesize tempPlotStrip;
@synthesize tempPlotLabel;
@synthesize humidityPlotStrip;
@synthesize humidityPlotLabel;
@synthesize pressurePlotStrip;
@synthesize pressurePlotLabel;
@synthesize resetButton;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Configure the view
  UIImage *img = [UIImage imageNamed:@"background.png"];
  UIColor *clr = [[UIColor alloc] initWithPatternImage:img];
  [self.view setBackgroundColor:clr];
  [clr release];
  
  // Configure the reset button
  UIImage *imgBg = [UIImage imageNamed:@"RedBtnBg"];
  UIImage *imgBtnBg = [imgBg stretchableImageWithLeftCapWidth:12 topCapHeight:0];
  [resetButton setBackgroundImage:imgBtnBg 
                         forState:UIControlStateNormal];
  
  // Configure the plotter strip
  // ... This strip has high/low limits specified
  plotStrip.lowerLimit = -1.0f;
  plotStrip.upperLimit = 1.0f;
  plotStrip.capacity = 300;
  plotStrip.lineColor = [UIColor greenColor];
  plotStrip.showDot = YES;
  plotStrip.labelFormat = @"Timer-driven: (%0.02f)";
  plotStrip.label = plotStripLabel;
  
  // Configure the slider plot strip
  // ... This strip figures out the high/low limits dynamically
  sliderPlotStrip.capacity = 300;
  sliderPlotStrip.baselineValue = 0.0;
  sliderPlotStrip.lineColor = [UIColor redColor];
  sliderPlotStrip.showDot = YES;
  sliderPlotStrip.labelFormat = @"Event-driven: (%0.02f)";
  sliderPlotStrip.label = sliderPlotLabel;
  
  // Configure the temperature plot strip (sparkline)
  NSArray *array = [NSArray arrayWithObjects:[NSNumber numberWithFloat:68.1f],
                                             [NSNumber numberWithFloat:70.2f],
                                             [NSNumber numberWithFloat:71.3f],
                                             [NSNumber numberWithFloat:72.4f],
                                             [NSNumber numberWithFloat:73.5f],
                                             [NSNumber numberWithFloat:70.6f],
                                             nil];
  tempPlotStrip.showDot = YES;
  tempPlotStrip.capacity = array.count;
  tempPlotStrip.data = array;
  tempPlotStrip.lineColor = [UIColor darkGrayColor];
  tempPlotStrip.labelFormat = @"%0.1f °F";
  tempPlotStrip.label = tempPlotLabel;
  
  // Configure the humidity plot strip
  array = [NSArray arrayWithObjects:[NSNumber numberWithFloat:57.1f],
                                    [NSNumber numberWithFloat:59.2f],
                                    [NSNumber numberWithFloat:74.3f],
                                    [NSNumber numberWithFloat:68.4f],
                                    [NSNumber numberWithFloat:62.5f],
                                    [NSNumber numberWithFloat:60.6f],
                                    nil];
  humidityPlotStrip.showDot = YES;                                    
  humidityPlotStrip.capacity = array.count;
  humidityPlotStrip.data = array;
  humidityPlotStrip.lineColor = [UIColor blueColor];
  humidityPlotStrip.labelFormat = @"%0.1f %%";
  humidityPlotStrip.label = humidityPlotLabel;

  // Configure the humidity plot strip
  array = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.12f],
                                    [NSNumber numberWithFloat:1.31f],
                                    [NSNumber numberWithFloat:1.41f],
                                    [NSNumber numberWithFloat:1.35f],
                                    [NSNumber numberWithFloat:1.12f],
                                    [NSNumber numberWithFloat:1.60f],
                                    nil];
  pressurePlotStrip.showDot = YES;                                    
  pressurePlotStrip.capacity = array.count;
  pressurePlotStrip.data = array;
  pressurePlotStrip.lineColor = [UIColor yellowColor];
  pressurePlotStrip.labelFormat = @"%0.2f PSI";
  pressurePlotStrip.label = pressurePlotLabel;
  
  
  // Start the timer to provide data
  m_timer = [[NSTimer scheduledTimerWithTimeInterval:0.100f 
                                             target:self 
                                           selector:@selector(didGetTimerEvent:) 
                                           userInfo:nil 
                                            repeats:YES] retain];
}

- (void)viewDidUnload
{
  // Cancel the timer
  [m_timer invalidate];
  [m_timer release];
  
  // Clean up
  [self setPlotStrip:nil];
  [self setValueSlider:nil];
  [self setPlotStripLabel:nil];
  [self setTempPlotStrip:nil];
  [self setTempPlotLabel:nil];
  [self setHumidityPlotStrip:nil];
  [self setHumidityPlotLabel:nil];
  [self setPressurePlotStrip:nil];
  [self setPressurePlotLabel:nil];
  [self setSliderPlotStrip:nil];
  [self setSliderPlotLabel:nil];
  [self setResetButton:nil];
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  // Only portrait orientation for demo
  return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)dealloc {
  [plotStrip release];
  [valueSlider release];
  [plotStripLabel release];
  [tempPlotStrip release];
  [tempPlotLabel release];
  [humidityPlotStrip release];
  [humidityPlotLabel release];
  [pressurePlotStrip release];
  [pressurePlotLabel release];
  [sliderPlotStrip release];
  [sliderPlotLabel release];
  [resetButton release];
  [super dealloc];
}

- (void) didGetTimerEvent:(NSTimer *)a_timer
{
  // Add current slider value to plot strip
  plotStrip.value = valueSlider.value;
}

- (IBAction)didChangeSlider:(id)sender {
  // Copy the value to the plot strip
  sliderPlotStrip.value = valueSlider.value;
}

- (IBAction)didReset:(id)sender {
  // Clear the plotter strips
  [plotStrip clear];
  [sliderPlotStrip clear];
}


@end
