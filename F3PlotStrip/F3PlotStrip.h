//
//  F3PlotStrip.h
//  Copyright (c) 2012 by Brad Benson
//  All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following 
//  conditions are met:
//    1.  Redistributions of source code must retain the above copyright
//        notice this list of conditions and the following disclaimer.
//    2.  Redistributions in binary form must reproduce the above copyright 
//        notice, this list of conditions and the following disclaimer in 
//        the documentation and/or other materials provided with the 
//        distribution.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
//  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
//  COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
//  OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
//  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
//  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
//  OF SUCH DAMAGE.
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
@property (readwrite, nonatomic)          float     baselineValue;    // Baseline value, shown as horizontal line
@property (readwrite, nonatomic, retain)  UIColor   *baselineColor;   // Color of baseline
@property (readwrite, nonatomic)          float     baselineWidth;    // Thickness of baseline (pixels)
@property (readwrite, nonatomic, retain)  UIColor   *separatorColor;  // Color of vertical separators
@property (readwrite, nonatomic)          float     separatorWidth;   // Width of separator (pixels)

// Public methods
-(void) clear;                                      // Clears plot history
-(void) addSeparator;                               // Adds separator line to history
-(NSArray *) data;                                  // Gets array of data
-(void) setData:(NSArray *)a_dataArray;             // Sets plot data
-(void) setDataAsIntArray:(int *)a_piData           // Sets plot data from array of integers
                    count:(int)a_iNumValues;
-(void) setDataAsFloatArray:(float *)a_pflData      // Sets plot data from array of floats
                      count:(int)a_iNumValues;
-(void) setDataAsDoubleArray:(double *)a_pflData    // Sets plot data from array of doubles
                       count:(int) a_iNumValues;
-(void) setLabel:(UILabel *)a_label       // Sets associated UILabel and format to receive value
       andFormat:(NSString *)a_strFmt;
-(void) clearBaseline;                    // Clear baseline value

@end
