//
//  ViewController.h
//  F3PlotStrip
//
//  Created by Brad Benson on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "F3PlotStrip.h"

@interface ViewController : UIViewController
{
  @private
    NSTimer     *m_timer;       // Timer for updating values
}

@property (retain, nonatomic) IBOutlet UISlider *valueSlider;
@property (retain, nonatomic) IBOutlet F3PlotStrip *plotStrip;
@property (retain, nonatomic) IBOutlet UILabel *plotStripLabel;
@property (retain, nonatomic) IBOutlet F3PlotStrip *sliderPlotStrip;
@property (retain, nonatomic) IBOutlet UILabel *sliderPlotLabel;
@property (retain, nonatomic) IBOutlet F3PlotStrip *tempPlotStrip;
@property (retain, nonatomic) IBOutlet UILabel *tempPlotLabel;
@property (retain, nonatomic) IBOutlet F3PlotStrip *humidityPlotStrip;
@property (retain, nonatomic) IBOutlet UILabel *humidityPlotLabel;
@property (retain, nonatomic) IBOutlet F3PlotStrip *pressurePlotStrip;
@property (retain, nonatomic) IBOutlet UILabel *pressurePlotLabel;
@property (retain, nonatomic) IBOutlet UIButton *resetButton;

- (void) didGetTimerEvent:(NSTimer *)a_timer;
- (IBAction)didChangeSlider:(id)sender;
- (IBAction)didReset:(id)sender;

@end
