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
    BOOL            _fShowDot;              // YES = show dot on most recent value
    float           *_pHistory,             // Pointer to array of floats containing value history
                    _flUpdatePeriod,        // Update period (seconds per update)
                    _flUpperLimit,          // Maximum plotted value
                    _flLowerLimit,          // Minimum plotted value
                    _flHighWaterValue,      // Maximum value seen in data
                    _flLowWaterValue,       // Minimum value seen in data
                    _flLineWidth,           // Width of plot line, in pixels
                    _flBaselineValue,       // Baseline value
                    _flBaselineWidth,       // Width/thickness of baseline (pixels)
                    _flSeparatorLineWidth;  // Width/thickness of separator line (pixels)
    int             _iHistorySize,          // Max number of entries in history array
                    _iHistoryCount,         // Number of values in history array
                    _iHistoryIdx;           // Current position in history array
    NSString        *_strLabelFmt;          // Label format string
    NSTimeInterval  _lastUpdateTimestamp;   // Timestamp of last update
    UIColor         *_lineColor,            // Color of plot line
                    *_baselineColor,        // Color of baseline
                    *_separatorColor;       // Color of vertical separator
    UILabel         *_valueLabel;           // Associated label for to receive value
}

@end



#pragma mark - Main Class Implementation
@implementation F3PlotStrip


#pragma mark - Initialization and Termination

//-----------------------------------------------------------------------
//  Method: init
//      Default initializer
//
-(id) init
{
    // Call parent first
    self = [super init];
    if (self) {
        // Set up the instance
        [self setDefaults];
    }
    return self;
}


//-----------------------------------------------------------------------
//  Method: initWithFrame:
//    Initialize the view from the specified rectangle
//
- (id)initWithFrame:(CGRect)frame
{
    // Call parent first
    self = [super initWithFrame:frame];
    if (self) {
        // Set up the instance
        [self setDefaults];
    }
    return self;
}


//-----------------------------------------------------------------------
//  Method: dealloc
//    Clean up instance when released
//
- (void) dealloc
{
    // Our stuff
    free( _pHistory );
}


#pragma mark - NSCoding related methods
//-----------------------------------------------------------------------
//  Method: initWithCoder:
//    Initialize from supplied coding object
//
- (id) initWithCoder:(NSCoder *)a_decoder
{
    // Call parent first
    self = [super initWithCoder:a_decoder];
    if (self) {
        // Set up the instance
        [self setDefaults];
    }
    return self;
}


#pragma mark - Accessors
//-----------------------------------------------------------------------
//  Method: value
//    Returns the current value associated with the plot strip
//
- (float) value
{
    // Return value at present history position
    return _pHistory[_iHistoryIdx];
}


//-----------------------------------------------------------------------
//  Method: setValue:
//    Sets the current value of the plot, and adds the value to the
//    history.
//
- (void) setValue:(float)a_flValue
{
    // Is the value NAN?
    if( !isnan(a_flValue) ) {
        // Adjust value index and save supplied value
        _iHistoryIdx = (_iHistoryIdx + 1) % _iHistorySize;
        _iHistoryCount = MIN(_iHistoryCount + 1, _iHistorySize);
        _pHistory[_iHistoryIdx] = a_flValue;
        
        // Update high/low water limits
        _flHighWaterValue  = MAX(_flHighWaterValue, a_flValue);
        _flLowWaterValue   = MIN(_flLowWaterValue, a_flValue);
        
        // Update the display
        [self updateDisplay];
    }
}


//-----------------------------------------------------------------------
//  Method: setUpdateRateFps
//      Sets maximum update rate, in frames per second
//
-(void) setUpdateRateFps:(float)a_updateRateFps
{
    // Compute update period
    _flUpdatePeriod = (a_updateRateFps && a_updateRateFps != NAN) ? 1.0 / a_updateRateFps : 0.013f;
}


//-----------------------------------------------------------------------
//  Method: addSeparator
//    This method adds a vertical separator to the history graph.
//
- (void) addSeparator
{
    // Adjust value index and save supplied value
    _iHistoryIdx = (_iHistoryIdx + 1) % _iHistorySize;
    _iHistoryCount = MIN(_iHistoryCount + 1, _iHistorySize);
    _pHistory[_iHistoryIdx] = NAN;
    
    // Update the display (but not the label)
    [self setNeedsDisplay];
}


//-----------------------------------------------------------------------
//  Method: setUpperLimit:
//    Sets upper limit of values to be plotted
//
- (void) setUpperLimit:(float)a_flUpperLimit
{
    // Save it
    _flUpperLimit = a_flUpperLimit;
    [self updateDisplay];
}


//-----------------------------------------------------------------------
//  Method: setLowerLimit:
//    Sets lower limit of values to be plotted
//
- (void) setLowerLimit:(float)a_flLowerLimit
{
    // Save it
    _flLowerLimit = a_flLowerLimit;
    [self updateDisplay];
}


//-----------------------------------------------------------------------
//  Method: setCapacity:
//    Set the number of values retained.   Any previous history
//    is cleared.
//
- (void) setCapacity:(int)a_iCapacity
{
    // Save it
    _iHistorySize = a_iCapacity;
    
    // Alloc new buffer, freeing old one if needed
    if(_pHistory) {
        // Free old one
        free(_pHistory);
    }
    _pHistory = malloc(sizeof(*_pHistory) * _iHistorySize);
    
    // Clear the buffer
    [self clear];
}


//-----------------------------------------------------------------------
//  Method: data
//    This method returns an NSArray of NSNumber objects representing
//    the data present in the plot history buffer.
//
- (NSArray *)data
{
    int               iIdx = 0;           // Index into our history buffer
    NSMutableArray    *aResult;           // Result value
    
    // Allocate and initialize the array
    aResult = [[NSMutableArray alloc] initWithCapacity:_iHistoryCount];
    for(int iX = 0; iX < _iHistoryCount; ++iX) {
        // Add current value from history to result
        [aResult addObject:[NSNumber numberWithFloat:_pHistory[iIdx]]];
        iIdx = (iIdx + 1) % _iHistorySize;
    }

    // Done!
    return aResult;
}


//-----------------------------------------------------------------------
//  Method: setData
//    This method sets the history buffer from an NSArray of
//    NSNumber objects.
//
- (void) setData:(NSArray *)a_dataArray
{
    // Anything in the passed array?
    if(a_dataArray && a_dataArray.count) {
        // Yes, will this fit in our current buffer?
        if(a_dataArray.count > _iHistorySize) {
            // No, adjust - this clears the existing history
            [self setCapacity:a_dataArray.count];
        }
        
        // Reset high/low values to the first item in the array
        // ... This ensures they will capture the actual high/low values
        // ... during the array enumeration step below.
        _flHighWaterValue  = _flLowWaterValue = ((NSNumber *)[a_dataArray objectAtIndex:0]).floatValue;
        
        // Copy the values
        float *p = _pHistory;
        for(NSNumber *srcValue in a_dataArray) {
            // Copy the value and assign high/low limits
            *p = srcValue.floatValue;
            _flHighWaterValue  = MAX(_flHighWaterValue, *p);
            _flLowWaterValue   = MIN(_flLowWaterValue, *p);
            
            // Next slot...
            ++p;
        }
        
        // Set indexes etc. as needed.
        _iHistoryCount = a_dataArray.count;
        _iHistoryIdx = _iHistoryCount - 1;
    }
    else {
        // Empty array - just clear our existing history
        [self clear];
    }
}


//-----------------------------------------------------------------------
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
        if(a_iNumValues > _iHistorySize) {
            // No, adjust - this clears the existing history
            [self setCapacity:a_iNumValues];
        }
        
        // Reset high/low values to the first item in the array
        // ... This ensures they will capture the actual high/low values
        // ... during the array enumeration step below.
        _flHighWaterValue  = _flLowWaterValue = (float)( a_piData[0] );
        
        // Copy the values
        float *p = _pHistory;
        for(int iX = 0; iX < a_iNumValues; ++iX) {
            // Copy the value and assign high/low limits
            *p = (float)a_piData[iX];
            _flHighWaterValue  = MAX(_flHighWaterValue, *p);
            _flLowWaterValue   = MIN(_flLowWaterValue, *p);
            
            // Next slot...
            ++p;
        }
        
        // Set indexes etc. as needed.
        _iHistoryCount = a_iNumValues;
        _iHistoryIdx = _iHistoryCount - 1;
        
        // Repaint
        [self setNeedsDisplay];
    }
    else {
        // Empty array - just clear our existing history
        [self clear];
    }
}


//-----------------------------------------------------------------------
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
        if(a_iNumValues > _iHistorySize) {
            // No, adjust - this clears the existing history
            [self setCapacity:a_iNumValues];
        }
        
        // Reset high/low values to the first item in the array
        // ... This ensures they will capture the actual high/low values
        // ... during the array enumeration step below.
        _flHighWaterValue  = _flLowWaterValue = a_pflData[0];
        
        // Copy the values
        float *p = _pHistory;
        for(int iX = 0; iX < a_iNumValues; ++iX) {
            // Copy the value and assign high/low limits
            *p = (float)a_pflData[iX];
            _flHighWaterValue  = MAX(_flHighWaterValue, *p);
            _flLowWaterValue   = MIN(_flLowWaterValue, *p);
            
            // Next slot...
            ++p;
        }
        
        // Set indexes etc. as needed.
        _iHistoryCount = a_iNumValues;
        _iHistoryIdx = _iHistoryCount - 1;
        
        // Repaint
        [self setNeedsDisplay];
    }
    else {
        // Empty array - just clear our existing history
        [self clear];
    }
}


//-----------------------------------------------------------------------
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
        if(a_iNumValues > _iHistorySize) {
            // No, adjust - this clears the existing history
            [self setCapacity:a_iNumValues];
        }
        
        // Reset high/low values to the first item in the array
        // ... This ensures they will capture the actual high/low values
        // ... during the array enumeration step below.
        _flHighWaterValue  = _flLowWaterValue = (float) a_pflData[0];
        
        // Copy the values
        float *p = _pHistory;
        for(int iX = 0; iX < a_iNumValues; ++iX) {
            // Copy the value and assign high/low limits
            *p = (float)a_pflData[iX];
            _flHighWaterValue  = MAX(_flHighWaterValue, *p);
            _flLowWaterValue   = MIN(_flLowWaterValue, *p);
            
            // Next slot...
            ++p;
        }
        
        // Set indexes etc. as needed.
        _iHistoryCount = a_iNumValues;
        _iHistoryIdx = _iHistoryCount - 1;
        
        // Repaint
        [self setNeedsDisplay];
    }
    else {
        // Empty array - just clear our existing history
        [self clear];
    }
}


//-----------------------------------------------------------------------
//  Method: clear
//    Clears plot history
//
- (void) clear
{
    float     flDefault;                  // Default value
    
    // Reset history to default values
    flDefault = _flLowerLimit + fabs(_flUpperLimit - _flLowerLimit) / 2;
    for(int iX = 0; iX < _iHistorySize; ++iX) {
        // Save it
        _pHistory[ iX ] = 0.0f; // flDefault;
    }
    
    // Reset high/low watermarks
    _flHighWaterValue  = (isnan(_flBaselineValue)) ? -INFINITY : _flBaselineValue;
    _flLowWaterValue   = (isnan(_flBaselineValue)) ? INFINITY : _flBaselineValue;
    
    // Reset indexes
    _iHistoryIdx   = 0;
    _iHistoryCount = 0;
    
    // Repaint
    [self setNeedsDisplay];
}


//-----------------------------------------------------------------------
//  Method: setLabel:
//    Sets the label to receive the output value
//
-(void) setLabel:(UILabel *)a_label
{
    // Save it, then update it
    _valueLabel = a_label;
    [self updateValueLabel];
}


//-----------------------------------------------------------------------
//  Method: setLabelFormat:
//    Sets the format to label to receive the output value
//
-(void) setLabelFormat:(NSString *)a_labelFormat
{
    // Save it, then update it
    _strLabelFmt = a_labelFormat;
    [self updateValueLabel];
}


//-----------------------------------------------------------------------
//  Method: setLabel:andFormat:
//    Sets the label and associated format in one fell swoop.
//
-(void) setLabel:(UILabel *)a_label andFormat:(NSString *)a_strFmt
{
    // Save the values and update the label
    _valueLabel = a_label;
    _strLabelFmt = a_strFmt;
    [self updateValueLabel];
}


//-----------------------------------------------------------------------
//  Method: clearBaseline
//    Removes baseline from display
//
-(void) clearBaseline
{
    // Set baseline value to NAN - this removes it from the plot
    _flBaselineValue = NAN;
    
    // Repaint
    [self setNeedsDisplay];
}


//-----------------------------------------------------------------------
//  Method: setBaseline:
//    Sets the baseline value
//
-(void) setBaselineValue:(float)a_flValue
{
    // Update the baseline value along with high/low water limits
    _flBaselineValue   = a_flValue;
    _flHighWaterValue  = MAX(_flHighWaterValue, a_flValue);
    _flLowWaterValue   = MIN(_flLowWaterValue, a_flValue);
    
    // Repaint
    [self setNeedsDisplay];
}



#pragma mark - Drawing
//-----------------------------------------------------------------------
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
    flHigh = isnan(_flUpperLimit) ? _flHighWaterValue : _flUpperLimit;
    flLow = isnan(_flLowerLimit) ? _flLowWaterValue : _flLowerLimit;
    
    // How are we oriented?
    rectBounds  = CGRectInset(self.bounds, _flLineWidth*2, _flLineWidth*2);
    flMax       = rectBounds.size.height + rectBounds.origin.y;
    flXScale    = rectBounds.size.width / (_iHistorySize - 1);
    flYScale    = fabs(flHigh - flLow);
    flYScale    = rectBounds.size.height / ((flYScale > 0.0f) ? flYScale : 1.0f); // fabs(flHigh - flLow);
    
    // Get stuff needed for drawing
    ctx = UIGraphicsGetCurrentContext();
    
    // Draw baseline?
    if( !isnan(_flBaselineValue) ) {
        // Yes, do it
        CGContextSetStrokeColorWithColor(ctx, _baselineColor.CGColor);
        CGContextSetLineWidth(ctx, _flBaselineWidth);
        flY = flMax - (flYScale * (_flBaselineValue - flLow));
        CGContextMoveToPoint(ctx, CGRectGetMinX(rectBounds), flY);
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rectBounds), flY);
        CGContextStrokePath(ctx);
    }
    
    // Set attributes for drawing plot line
    CGContextSetStrokeColorWithColor(ctx, _lineColor.CGColor);
    CGContextSetLineWidth(ctx, _flLineWidth);
    
    // Compute first point and set drawing position
    if( _iHistoryCount == _iHistorySize ) {
        iIdx    = (_iHistoryIdx + 1) % _iHistorySize;
        flOffsX = rectBounds.origin.x;
    }
    else {
        iIdx = 0;
        flOffsX = rectBounds.size.width - (flXScale * _iHistoryCount);
    }
    flX = flOffsX;
    flY = flMax - (flYScale * (_pHistory[iIdx] - flLow));
    CGContextMoveToPoint(ctx, flX, flY);
    
    // Loop for all values in the history buffer
    // ... For histories which contain a significantly larger number
    // ... of values, the following would be more efficient :
    float flStep = MAX(1.0f, _iHistorySize / rectBounds.size.width);
    for(int iX = 0; iX < _iHistoryCount; iX = round(iX + flStep)) {
        // Is this element a separator?
        if( isnan( _pHistory[iIdx] ) ) {
            // Yes, stroke the previous path
            CGContextStrokePath(ctx);
            
            // Determine horizontal location for separator line
            // ... also configure context for separator
            flX = flXScale * iX + flOffsX;
            
            // Preserve current context and draw separator line
            CGContextSaveGState(ctx);
            CGContextSetStrokeColorWithColor(ctx, _separatorColor.CGColor);
            CGContextSetLineWidth(ctx, _flSeparatorLineWidth);
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
            flY = flMax - flYScale * (_pHistory[iIdx] - flLow);
            
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
        iIdx = (int)(round(iIdx + flStep)) % _iHistorySize;
    }
    CGContextStrokePath(ctx);
    
    // Draw dot on current value?
    if( _fShowDot ) {
        // Yes, do it
        CGContextSetFillColorWithColor(ctx, _lineColor.CGColor);
        CGContextAddArc(ctx, flX, flY, _flLineWidth*2, 0, M_PI*2, YES);
        CGContextFillPath(ctx);
    }
}


#pragma mark - Unpublished items

//-----------------------------------------------------------------------
//  Method: setDefaults
//    Sets default values used when instantiating an instance.
//
-(void) setDefaults
{
    // Initialization code
    _pHistory               = NULL;
    _lineColor              = [UIColor blackColor];
    _fShowDot               = YES;
    _flLineWidth            = 2.0f;
    _valueLabel             = nil;
    _strLabelFmt            = @"%0.1f";
    _flLowerLimit           = NAN;
    _flUpperLimit           = NAN;
    _flLowWaterValue        = INFINITY;
    _flHighWaterValue       = -INFINITY;
    _lastUpdateTimestamp    = 0.0;
    
    // Baseline items
    _flBaselineValue    = NAN;
    _flBaselineWidth    = 1.0f;
    _baselineColor      = [UIColor grayColor];
    
    // Separator items
    _flSeparatorLineWidth   = 1.0f;
    _separatorColor         = [UIColor grayColor];
    
    // Initialize plot history
    [self setCapacity:100];
    [self clear];
    
    // Configure the view/layer
    self.layer.cornerRadius = 6.0f;
    self.clipsToBounds = YES;
}


//-----------------------------------------------------------------------
//  Method: updateDisplay
//      Updates displayed information, throttled to no more than
//      approximately 30fps.
//
-(void) updateDisplay
{
    // Is it too soon to update the display?
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if( now > (_lastUpdateTimestamp + _flUpdatePeriod) ) {
        // Update the label and redraw the chart
        [self updateValueLabel];
        [self setNeedsDisplay];
        _lastUpdateTimestamp = now;
    }
}


//------------------------------------------------------------------------
//  Method: updateValueLabel
//    Updates any associated value label
//
-(void) updateValueLabel
{
    // Do we have a value label to be updated?
    if(_valueLabel) {
        // Yes, update it
        float flValue = (isnan(self.value)) ? 0.0f : self.value;
        _valueLabel.text = [NSString stringWithFormat:_strLabelFmt, flValue];
    }
}

@end
