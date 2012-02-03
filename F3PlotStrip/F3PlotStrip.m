//
//  F3PlotStrip.m
//  F3PlotStrip
//
//  Created by Brad Benson on 2/1/12.
//  Copyright (c) 2012 Flight III Systems. All rights reserved.
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
  BOOL          m_fShowDot;         // YES = show dot on most recent value
  float         *m_pHistory,        // Pointer to array of floats containing value history
                m_flUpperLimit,     // Maximum plotted value
                m_flLowerLimit,     // Minimum plotted value
                m_flHighWaterValue, // Maximum value seen in data
                m_flLowWaterValue,  // Minimum value seen in data
                m_flLineWidth;      // Width of plot line, in pixels
  int           m_iHistorySize,     // Max number of entries in history array
                m_iHistoryCount,    // Number of values in history array
                m_iHistoryIdx;      // Current position in history array
  NSString      *m_strLabelFmt;     // Label format string
  UIColor       *m_lineColor;       // Color of plot line
  UILabel       *m_valueLabel;      // Associated label for to receive value
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
    m_pHistory[ iX ] = flDefault;
  }
  
  // Reset high/low watermarks
  m_flLowWaterValue = INFINITY;    
  m_flHighWaterValue = -INFINITY;
  
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



#pragma mark - Drawing
//------------------------------------------------------------------------
//  Method: drawRect:
//    Render the view
//
- (void)drawRect:(CGRect)a_rect
{
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
  flXScale    = rectBounds.size.width / (m_iHistorySize - 1);
  flYScale    = rectBounds.size.height / fabs(flHigh - flLow);
  flMax       = rectBounds.size.height + rectBounds.origin.y;
  
  // Get stuff needed for drawing
  ctx = UIGraphicsGetCurrentContext();
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
    // Determine point for this
    flX = flXScale * iX + flOffsX; 
    flY = flMax - flYScale * (m_pHistory[iIdx] - flLow);
    CGContextAddLineToPoint(ctx, flX, flY);
    
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
    m_valueLabel.text = [NSString stringWithFormat:m_strLabelFmt, self.value];
  }
}

@end
