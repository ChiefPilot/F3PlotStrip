//
//  F3PlotStrip.m
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

#import <QuartzCore/QuartzCore.h>
#import "F3PlotStrip.h"


//------------------------------------------------------------------------
//------------------------------------------------------------------------
//----------------|  F3PlotStrip class implementation  |------------------
//------------------------------------------------------------------------
//------------------------------------------------------------------------

//===[ Class extension for private-ish stuff ]============================
#pragma mark - Private-ish Extension
@interface F3PlotStrip()
{
  BOOL          m_fShowDot;             // YES = show dot on most recent value
  float         *m_pHistory,            // Pointer to array of floats containing value history
                m_flUpperLimit,         // Maximum plotted value
                m_flLowerLimit,         // Minimum plotted value
                m_flHighWaterValue,     // Maximum value seen in data
                m_flLowWaterValue,      // Minimum value seen in data
                m_flLineWidth,          // Width of plot line, in pixels
                m_flBaselineValue,      // Baseline value
                m_flBaselineWidth,      // Width/thickness of baseline (pixels)
                m_flSeparatorLineWidth; // Width/thickness of separator line (pixels)
  int           m_iHistorySize,         // Max number of entries in history array
                m_iHistoryCount,        // Number of values in history array
                m_iHistoryIdx;          // Current position in history array
  NSString      *m_strLabelFmt;         // Label format string
  UIColor       *m_lineColor,           // Color of plot line
                *m_baselineColor,       // Color of baseline
                *m_separatorColor;      // Color of vertical separator
  UILabel       *m_valueLabel;          // Associated label for to receive value
}

// Private methods
-(void) setDefaults;
-(void) updateValueLabel;

@end



//===[ Public items ]=====================================================
#pragma mark - Main Class Implementation
@implementation F3PlotStrip


#pragma mark - Sythesized Properties
//------------------------------------------------------------------------
//  Synthesized Properties
//  
@synthesize upperLimit = m_flUpperLimit;
@synthesize lowerLimit = m_flLowerLimit;
@synthesize showDot = m_fShowDot;
@synthesize lineColor = m_lineColor;
@synthesize lineWidth = m_flLineWidth;
@synthesize capacity = m_iHistorySize;
@synthesize count = m_iHistoryCount;
@synthesize label = m_valueLabel;
@synthesize labelFormat = m_strLabelFmt;
@synthesize baselineValue = m_flBaselineValue;
@synthesize baselineWidth = m_flBaselineWidth;
@synthesize baselineColor = m_baselineColor;
@synthesize separatorColor = m_separatorColor;
@synthesize separatorWidth = m_flSeparatorLineWidth;


#pragma mark - Initialization and Termination
//------------------------------------------------------------------------
//  Method: initWithFrame:
//    Initialize the view from the specified rectangle
//
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      // Set up the instance
      [self setDefaults];
    }
    return self;
}


//------------------------------------------------------------------------
//  Method: dealloc
//    Clean up instance when released
//
- (void) dealloc
{
  // Our stuff
  [m_lineColor release];
  free( m_pHistory );
  
  // Call up the chain
  [super dealloc];
}


#pragma mark - NSCoding related methods
//------------------------------------------------------------------------
//  Method: initWithCoder:
//    Initialize from supplied coding object
//
- (id) initWithCoder:(NSCoder *)a_decoder
{
  self = [super initWithCoder:a_decoder];
  if (self) {
    // Set up the instance
    [self setDefaults];
  }
  return self;
}


#pragma mark - Accessors
//------------------------------------------------------------------------
//  Method: value
//    Returns the current value associated with the plot strip
//
- (float) value
{
  // Return value at present history position
  return m_pHistory[m_iHistoryIdx];
}


//------------------------------------------------------------------------
//  Method: setValue:
//    Sets the current value of the plot, and adds the value to the
//    history.
//
- (void) setValue:(float)a_flValue
{
  // Is the value NAN?
  if( !isnan(a_flValue) ) {
    // Adjust value index and save supplied value
    m_iHistoryIdx = (m_iHistoryIdx + 1) % m_iHistorySize;
    m_iHistoryCount = MIN(m_iHistoryCount + 1, m_iHistorySize);
    m_pHistory[m_iHistoryIdx] = a_flValue;
    
    // Update high/low water limits
    m_flHighWaterValue  = MAX(m_flHighWaterValue, a_flValue);
    m_flLowWaterValue   = MIN(m_flLowWaterValue, a_flValue);

    // Update the display
    [self updateValueLabel];
    [self setNeedsDisplay];
  }
}


//------------------------------------------------------------------------
//  Method: addSeparator
//    This method adds a vertical separator to the history graph.
//
- (void) addSeparator
{
  // Adjust value index and save supplied value
  m_iHistoryIdx = (m_iHistoryIdx + 1) % m_iHistorySize;
  m_iHistoryCount = MIN(m_iHistoryCount + 1, m_iHistorySize);
  m_pHistory[m_iHistoryIdx] = NAN;
  
  // Update the display (but not the label)
  [self setNeedsDisplay];
}


//------------------------------------------------------------------------
//  Method: setUpperLimit:
//    Sets upper limit of values to be plotted
//
- (void) setUpperLimit:(float)a_flUpperLimit
{
  // Save it
  m_flUpperLimit = a_flUpperLimit;
  [self setNeedsDisplay];
}


//------------------------------------------------------------------------
//  Method: setLowerLimit:
//    Sets lower limit of values to be plotted
//
- (void) setLowerLimit:(float)a_flLowerLimit
{
  // Save it
  m_flLowerLimit = a_flLowerLimit;
  [self setNeedsDisplay];
}


//------------------------------------------------------------------------
//  Method: setCapacity:
//    Set the number of values retained.   Any previous history
//    is cleared.
//
- (void) setCapacity:(int)a_iCapacity
{
  // Save it
  m_iHistorySize = a_iCapacity;
  
  // Alloc new buffer, freeing old one if needed
  if(m_pHistory) {
    // Free old one
    free(m_pHistory);
  }
  m_pHistory = malloc(sizeof(*m_pHistory) * m_iHistorySize);
  
  // Clear the buffer
  [self clear];
}


//------------------------------------------------------------------------
//  Method: data
//    This method returns an NSArray of NSNumber objects representing
//    the data present in the plot history buffer.
//
- (NSArray *)data
{
  int               iIdx = 0;           // Index into our history buffer
  NSMutableArray    *aResult;           // Result value
  
  // Allocate and initialize the array
  aResult = [[[NSMutableArray alloc] initWithCapacity:m_iHistoryCount] autorelease];
  for(int iX = 0; iX < m_iHistoryCount; ++iX) {
    // Add current value from history to result
    [aResult addObject:[NSNumber numberWithFloat:m_pHistory[iIdx]]];
    iIdx = (iIdx + 1) % m_iHistorySize;
  }
  
  // Update the data and be done!
  [self updateValueLabel];
  return aResult;
}


//------------------------------------------------------------------------
//  Method: setData
//    This method sets the history buffer from an NSArray of 
//    NSNumber objects.
//
- (void) setData:(NSArray *)a_dataArray
{
  // Anything in the passed array?
  if(a_dataArray && a_dataArray.count) {
    // Yes, will this fit in our current buffer?
    if(a_dataArray.count > m_iHistorySize) {
      // No, adjust - this clears the existing history
      [self setCapacity:a_dataArray.count];
    }

    // Reset high/low values to the first item in the array
    // ... This ensures they will capture the actual high/low values
    // ... during the array enumeration step below.
    m_flHighWaterValue  = m_flLowWaterValue = ((NSNumber *)[a_dataArray objectAtIndex:0]).floatValue;
    
    // Copy the values
    float *p = m_pHistory;
    for(NSNumber *srcValue in a_dataArray) {
      // Copy the value and assign high/low limits
      *p = srcValue.floatValue;
      m_flHighWaterValue  = MAX(m_flHighWaterValue, *p);
      m_flLowWaterValue   = MIN(m_flLowWaterValue, *p);
      
      // Next slot...
      ++p;
    }
    
    // Set indexes etc. as needed.
    m_iHistoryCount = a_dataArray.count;
    m_iHistoryIdx = m_iHistoryCount - 1;
  }
  else {
    // Empty array - just clear our existing history
    [self clear];
  }
}


//------------------------------------------------------------------------
//  Method: setDataAsIntArray
//    This method sets the history buffer from a C-style array of 
//    integers.
//
- (void) setDataAsIntArray:(int *)a_piData 
                     count:(int)a_iNumValues
{
  // Anything in the passed array?
  if(a_piData && a_iNumValues > 0) {
    // Yes, will this fit in our current buffer?
    if(a_iNumValues > m_iHistorySize) {
      // No, adjust - this clears the existing history
      [self setCapacity:a_iNumValues];
    }
    
    // Reset high/low values to the first item in the array
    // ... This ensures they will capture the actual high/low values
    // ... during the array enumeration step below.
    m_flHighWaterValue  = m_flLowWaterValue = (float)( a_piData[0] );
    
    // Copy the values
    float *p = m_pHistory;
    for(int iX = 0; iX < a_iNumValues; ++iX) {
      // Copy the value and assign high/low limits
      *p = (float)a_piData[iX];
      m_flHighWaterValue  = MAX(m_flHighWaterValue, *p);
      m_flLowWaterValue   = MIN(m_flLowWaterValue, *p);
      
      // Next slot...
      ++p;
    }
    
    // Set indexes etc. as needed.
    m_iHistoryCount = a_iNumValues;
    m_iHistoryIdx = m_iHistoryCount - 1;
  }
  else {
    // Empty array - just clear our existing history
    [self clear];
  }
}


//------------------------------------------------------------------------
//  Method: setDataAsFloatArray
//    This method sets the history buffer from a C-style array of 
//    single precision floating point values.
//
- (void) setDataAsFloatArray:(float *)a_pflData 
                       count:(int)a_iNumValues
{
  // Anything in the passed array?
  if(a_pflData && a_iNumValues > 0) {
    // Yes, will this fit in our current buffer?
    if(a_iNumValues > m_iHistorySize) {
      // No, adjust - this clears the existing history
      [self setCapacity:a_iNumValues];
    }
    
    // Reset high/low values to the first item in the array
    // ... This ensures they will capture the actual high/low values
    // ... during the array enumeration step below.
    m_flHighWaterValue  = m_flLowWaterValue = a_pflData[0];
    
    // Copy the values
    float *p = m_pHistory;
    for(int iX = 0; iX < a_iNumValues; ++iX) {
      // Copy the value and assign high/low limits
      *p = (float)a_pflData[iX];
      m_flHighWaterValue  = MAX(m_flHighWaterValue, *p);
      m_flLowWaterValue   = MIN(m_flLowWaterValue, *p);
      
      // Next slot...
      ++p;
    }
    
    // Set indexes etc. as needed.
    m_iHistoryCount = a_iNumValues;
    m_iHistoryIdx = m_iHistoryCount - 1;
  }
  else {
    // Empty array - just clear our existing history
    [self clear];
  }
}


//------------------------------------------------------------------------
//  Method: setDataAsDoubleArray
//    This method sets the history buffer from a C-style array of 
//    double precision floating point values.
//
- (void) setDataAsDoubleArray:(double *)a_pflData 
                        count:(int)a_iNumValues
{
  // Anything in the passed array?
  if(a_pflData && a_iNumValues > 0) {
    // Yes, will this fit in our current buffer?
    if(a_iNumValues > m_iHistorySize) {
      // No, adjust - this clears the existing history
      [self setCapacity:a_iNumValues];
    }
    
    // Reset high/low values to the first item in the array
    // ... This ensures they will capture the actual high/low values
    // ... during the array enumeration step below.
    m_flHighWaterValue  = m_flLowWaterValue = (float) a_pflData[0];
    
    // Copy the values
    float *p = m_pHistory;
    for(int iX = 0; iX < a_iNumValues; ++iX) {
      // Copy the value and assign high/low limits
      *p = (float)a_pflData[iX];
      m_flHighWaterValue  = MAX(m_flHighWaterValue, *p);
      m_flLowWaterValue   = MIN(m_flLowWaterValue, *p);
      
      // Next slot...
      ++p;
    }
    
    // Set indexes etc. as needed.
    m_iHistoryCount = a_iNumValues;
    m_iHistoryIdx = m_iHistoryCount - 1;
  }
  else {
    // Empty array - just clear our existing history
    [self clear];
  }
}


//------------------------------------------------------------------------
//  Method: clear
//    Clears plot history
//
- (void) clear
{
  float     flDefault;                  // Default value
  
  // Reset history to default values
  flDefault = m_flLowerLimit + fabs(m_flUpperLimit - m_flLowerLimit) / 2;
  for(int iX = 0; iX < m_iHistorySize; ++iX) {
    // Save it
    m_pHistory[ iX ] = 0.0f; // flDefault;
  }
  
  // Reset high/low watermarks
  m_flHighWaterValue  = (isnan(m_flBaselineValue)) ? -INFINITY : m_flBaselineValue;
  m_flLowWaterValue   = (isnan(m_flBaselineValue)) ? INFINITY : m_flBaselineValue;
  
  // Reset indexes
  m_iHistoryIdx   = 0;
  m_iHistoryCount = 0;
  
  // Repaint
  [self setNeedsDisplay];
}


//------------------------------------------------------------------------
//  Method: setLabel:
//    Sets the label to receive the output value
//
-(void) setLabel:(UILabel *)a_label
{
  // Save it, then update it
  [m_valueLabel release];
  m_valueLabel = [a_label retain];
  [self updateValueLabel];
}


//------------------------------------------------------------------------
//  Method: setLabelFormat:
//    Sets the format to label to receive the output value
//
-(void) setLabelFormat:(NSString *)a_labelFormat
{
  // Save it, then update it
  [m_strLabelFmt release];
  m_strLabelFmt = [a_labelFormat retain];
  [self updateValueLabel];
}


//------------------------------------------------------------------------
//  Method: setLabel:andFormat:
//    Sets the label and associated format in one fell swoop.
//
-(void) setLabel:(UILabel *)a_label andFormat:(NSString *)a_strFmt
{
  // Save the values and update the label
  [m_valueLabel release], m_valueLabel = [a_label retain];
  [m_strLabelFmt release], m_strLabelFmt = [a_strFmt retain];
  [self updateValueLabel];
}


//------------------------------------------------------------------------
//  Method: clearBaseline
//    Removes baseline from display
//
-(void) clearBaseline
{
  // Set baseline value to NAN - this removes it from the plot
  m_flBaselineValue = NAN;
}


//------------------------------------------------------------------------
//  Method: setBaseline:
//    Sets the baseline value
//
-(void) setBaselineValue:(float)a_flValue
{
  // Update the baseline value along with high/low water limits
  m_flBaselineValue   = a_flValue;
  m_flHighWaterValue  = MAX(m_flHighWaterValue, a_flValue);
  m_flLowWaterValue   = MIN(m_flLowWaterValue, a_flValue);
  
  // Update the display
  [self setNeedsDisplay];
}



#pragma mark - Drawing
//------------------------------------------------------------------------
//  Method: drawRect:
//    Render the view
//
- (void)drawRect:(CGRect)a_rect
{
  BOOL                fSep;         // YES = last point was separator
  CGContextRef        ctx;          // Graphics context
  CGRect              rectBounds;   // Bounding rectangle adjusted for multiple of bar size
  float               flXScale,     // Scaling factor for X coordinates
                      flYScale,     // Scaling factor for Y coordinates
                      flMax,        // Max value offset
                      flOffsX,      // Offset for X coordinate
                      flX,          // X-coordinate for segment
                      flY,          // Y-coordinate for segment
                      flLow,        // Working lower limit
                      flHigh;       // Working upper limit
  int                 iIdx;         // Index into value history array
  
  // Determine upper/lower limits to be plotted
  flHigh = isnan(m_flUpperLimit) ? m_flHighWaterValue : m_flUpperLimit;
  flLow = isnan(m_flLowerLimit) ? m_flLowWaterValue : m_flLowerLimit;
  
  // How are we oriented?
  rectBounds  = CGRectInset(self.bounds, m_flLineWidth*2, m_flLineWidth*2);
  flMax       = rectBounds.size.height + rectBounds.origin.y;
  flXScale    = rectBounds.size.width / (m_iHistorySize - 1);
  flYScale    = fabs(flHigh - flLow);
  flYScale    = rectBounds.size.height / ((flYScale > 0.0f) ? flYScale : 1.0f); // fabs(flHigh - flLow);
  
  // Get stuff needed for drawing
  ctx = UIGraphicsGetCurrentContext();
  
  // Draw baseline?
  if( !isnan(m_flBaselineValue) ) {
    // Yes, do it
    CGContextSetStrokeColorWithColor(ctx, m_baselineColor.CGColor);
    CGContextSetLineWidth(ctx, m_flBaselineWidth);
    flY = flMax - (flYScale * (m_flBaselineValue - flLow));
    CGContextMoveToPoint(ctx, CGRectGetMinX(rectBounds), flY);
    CGContextAddLineToPoint(ctx, CGRectGetMaxX(rectBounds), flY);
    CGContextStrokePath(ctx);
  }
  
  // Set attributes for drawing plot line
  CGContextSetStrokeColorWithColor(ctx, m_lineColor.CGColor);
  CGContextSetLineWidth(ctx, m_flLineWidth);
  
  // Compute first point and set drawing position
  if( m_iHistoryCount == m_iHistorySize ) {
    iIdx    = (m_iHistoryIdx + 1) % m_iHistorySize;
    flOffsX = rectBounds.origin.x;
  }
  else {
    iIdx = 0;
    flOffsX = rectBounds.size.width - (flXScale * m_iHistoryCount);
  }
  flX = flOffsX;
  flY = flMax - (flYScale * (m_pHistory[iIdx] - flLow));
  CGContextMoveToPoint(ctx, flX, flY);
  
  // Loop for all values in the history buffer
  // ... For histories which contain a significantly larger number
  // ... of values, the following would be more efficient :
  //      float flStep = MAX(1.0f, m_iHistorySize / rectBounds.size.width);
  //      for(int iX = 0; iX < m_iHistoryCount; iX = round(iX + flStep)) {
  for(int iX = 0; iX < m_iHistoryCount; ++iX) {
    // Is this element a separator?
    if( isnan( m_pHistory[iIdx] ) ) {
      // Yes, stroke the previous path
      CGContextStrokePath(ctx);
      
      // Determine horizontal location for separator line
      // ... also configure context for separator
      flX = flXScale * iX + flOffsX; 
      
      // Preserve current context and draw separator line
      CGContextSaveGState(ctx);
      CGContextSetStrokeColorWithColor(ctx, m_separatorColor.CGColor);
      CGContextSetLineWidth(ctx, m_flSeparatorLineWidth);
      CGContextSetLineDash(ctx, 0.0f, NULL, 0);
      CGContextMoveToPoint(ctx, flX, CGRectGetMinY(rectBounds));
      CGContextAddLineToPoint(ctx, flX, CGRectGetMaxY(rectBounds));
      CGContextStrokePath(ctx);
      CGContextRestoreGState(ctx);
      
      // Save separator state for next real point
      fSep = YES;
    }
    else {
      // No, add the point to the plot line
      flX = flXScale * iX + flOffsX; 
      flY = flMax - flYScale * (m_pHistory[iIdx] - flLow);
      
      // Do we need to start new position?
      if(fSep) {
        // Set position for next line
        CGContextMoveToPoint(ctx, flX, flY);
      }
      else {
        // No, just draw a line
        CGContextAddLineToPoint(ctx, flX, flY);
      }
      
      // Update separator state flag
      fSep = NO;
    }
    
    // Update index to get next value from history
    // ... For histories which contain a significantly larger number
    // ... of values, the following would be more efficient :
    //        iIdx = (int)(round(iIdx + flStep)) % m_iHistorySize;
    iIdx = (iIdx + 1) % m_iHistorySize;
  }
  CGContextStrokePath(ctx);
  
  // Draw dot on current value?
  if( m_fShowDot ) {
    // Yes, do it
    CGContextSetFillColorWithColor(ctx, m_lineColor.CGColor);
    CGContextAddArc(ctx, flX, flY, m_flLineWidth*2, 0, M_PI*2, YES);
    CGContextFillPath(ctx);
  }
}


#pragma mark - Private Methods
//===[ Private Methods ]==================================================


//------------------------------------------------------------------------
//  Method: setDefaults
//    Sets default values used when instantiating an instance.
//
-(void) setDefaults
{
  // Initialization code
  m_pHistory          = NULL;
  m_lineColor         = [[UIColor blackColor] retain];
  m_fShowDot          = YES;
  m_flLineWidth       = 2.0f;
  m_valueLabel        = nil;
  m_strLabelFmt       = @"%0.1f";
  m_flLowerLimit      = NAN;
  m_flUpperLimit      = NAN;
  m_flLowWaterValue   = INFINITY;    
  m_flHighWaterValue  = -INFINITY;
  
  // Baseline items
  m_flBaselineValue   = NAN;
  m_flBaselineWidth   = 1.0f;
  m_baselineColor     = [[UIColor grayColor] retain];
  
  // Separator items
  m_flSeparatorLineWidth  = 1.0f;
  m_separatorColor        = [[UIColor grayColor] retain];
  
  // Initialize plot history
  [self setCapacity:100];
  [self clear];
  
  // Configure the view/layer
  self.layer.cornerRadius = 6.0f;
  self.clipsToBounds = YES;
}


//------------------------------------------------------------------------
//  Method: updateValueLabel
//    Updates any associated value label
//
-(void) updateValueLabel
{
  // Do we have a value label to be updated?
  if(m_valueLabel) {
    // Yes, update it
    float flValue = (isnan(self.value)) ? 0.0f : self.value;
    m_valueLabel.text = [NSString stringWithFormat:m_strLabelFmt, flValue];
  }
}

@end
