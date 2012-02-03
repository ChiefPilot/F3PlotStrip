//
//  F3PlotStrip.h
//  F3PlotStrip
//
//  Created by Brad Benson on 2/1/12.
//  Copyright (c) 2012 Flight III Systems. All rights reserved.
//


//---> Get required headers <---------------------------------------------
#import <UIKit/UIKit.h>



//------------------------------------------------------------------------
//------------------------------------------------------------------------
//-----------------|  F3PlotStrip class definition  |---------------------
//------------------------------------------------------------------------
//------------------------------------------------------------------------
@interface F3PlotStrip : UIView

// Properties governing the actual plot
@property (readwrite, nonatomic)  int       capacity;     // Capacity of plot history
@property (readonly, nonatomic)   int       count;        // # of values in history
@property (readwrite, nonatomic)  float     value;        // Most recent value
@property (assign, nonatomic)     NSArray   *data;        // All data in history buffer
@property (readwrite, nonatomic)  float     upperLimit;   // Upper limit; displayed values clamped to this
@property (readwrite, nonatomic)  float     lowerLimit;   // Lower limit; displayed values clamped to this
@property (readwrite, nonatomic)  BOOL      showDot;      // YES = draw dot on most current value
@property (retain, nonatomic)     UIColor   *lineColor;   // Color of plot line
@property (readwrite, nonatomic)  float     lineWidth;    // Width of plot line, in pixels
@property (retain, nonatomic)     UILabel   *label;       // Associated UILabel view (may be nil)
@property (retain, nonatomic)     NSString  *labelFormat; // Format string for UILabel text (may be nil)

// Public methods
-(void) clear;                            // Clears plot history
-(NSArray *) data;                        // Gets array of data
-(void) setData:(NSArray *)a_dataArray;   // Sets complete plot data
-(void) setLabel:(UILabel *)a_label       // Sets associated UILabel and format to receive value
       andFormat:(NSString *)a_strFmt;

@end
