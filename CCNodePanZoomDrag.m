//
//  CCNodePanZoomDrag.m
//  shortcut
//
//  Created by Maik Verbaan on 01-07-16.
//  Copyright © 2016 Apportable. All rights reserved.
//
//  Set the contentnode to anything you like and drag, pan and zoom away...
//  Could use some work in rubberband effect, handling more than two touches 
//  and other paramters, but this class served its purpose for me.

#import "CCNodePanZoomDrag.h"

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define MaxTouches 2

@implementation CCNodePanZoomDrag
{
    CCSprite * _anchorPointSprite;
    
    NSMutableArray * _touches;
    
    CGPoint _startingPointTouchInContentnode;
    CGPoint _previousPointTouchInContentnode;
    CGPoint _currentPointTouchInContentnode;
    
    CGPoint _startingPointTouchInSelf;
    CGPoint _previousPointTouchInSelf;
    CGPoint _currentPointTouchInSelf;
    
    float _startingDistance;
    float _currentDistance;
    float _previousDistance;
    
    float _startingAngle;
    float _currentAngle;
    float _previousAngle;
    
    
}

#pragma mark Initialization

- (id)init
{
    self = [super init];
    self.contentNode = [[CCNode alloc]init];
    return self;
}

- (id)initWithContentnode:(CCNode*)newContentNode
{
    self = [super init];
    self.contentNode = newContentNode;
    return self;
}

-(void)setContentNodeSize:(CGSize)newSize
{
    self.contentNode = [[CCNode alloc]init];
    [self.contentNode setContentSize:newSize];
    
}

-(void)onEnter
{
    [super onEnter];
    self.userInteractionEnabled = TRUE;
    self.multipleTouchEnabled = TRUE;
    [self addChild:self.contentNode];
    _touches = [[NSMutableArray alloc]init];
    //Add sprite for anchor point
    /**
    _anchorPointSprite = [[CCSprite alloc]init];
    [_anchorPointSprite setSpriteFrame:[CCSpriteFrame frameWithImageNamed: @"sprites/hexagonred.png"]];
    _anchorPointSprite.anchorPoint = CGPointMake(0.5,0.5);
    [self.contentNode addChild:_anchorPointSprite];
    */
}




#pragma mark Context helpers


-(CGPoint)getCenterPointForContentNode
{
    return [self getCenterPointForReferenceNode:self.contentNode];
}

-(CGPoint)getCenterPointForSelf
{
    return [self getCenterPointForReferenceNode:self];
}

-(CGPoint)getCenterPointForReferenceNode:(CCNode*)node
{
    CCTouch * touch1 = [_touches firstObject];
    CCTouch * touch2 = [_touches lastObject];
    CGPoint touchPosition1 = [touch1 locationInNode:node];
    CGPoint touchPosition2 = [touch2 locationInNode:node];
    CGPoint returnPoint = [self getCenterOfTwoPoints:touchPosition1 :touchPosition2];
    return returnPoint;
}

-(float)getAngleForActiveTouches
{
    CCTouch * touch1 = [_touches firstObject];
    CCTouch * touch2 = [_touches lastObject];
    CGPoint touchPosition1 = [touch1 locationInNode:self];
    CGPoint touchPosition2 = [touch2 locationInNode:self];
    float returnAngle = [self angleBetweenPoints:touchPosition1 and:touchPosition2];
    return returnAngle;
}

-(float)getCurrentDistance
{
    CCTouch * touch1 = [_touches firstObject];
    CCTouch * touch2 = [_touches lastObject];
    CGPoint touchPosition1 = [touch1 locationInNode:self.parent];
    CGPoint touchPosition2 = [touch2 locationInNode:self.parent];
    float distance = [self calculateDistance:touchPosition1 :touchPosition2];
    return distance;
}

#pragma mark Touch methods
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    if(_touches.count < MaxTouches) //only register touch if not exceeding max amount of touches
    {
        [_touches addObject:touch];
        
        //NSLog(@"Touch began");
        CGPoint touchPositionInContentnode = [touch locationInNode:self.contentNode];
        CGPoint touchPositionInSelf = [touch locationInNode:self];
        
        if (_touches.count == 1)    //starting point = touch point
        {
            _startingPointTouchInContentnode = touchPositionInContentnode;
            _currentPointTouchInContentnode = touchPositionInContentnode;
            _previousPointTouchInContentnode = touchPositionInContentnode;
            
            _startingPointTouchInSelf = touchPositionInSelf;
            _currentPointTouchInSelf = touchPositionInSelf;
            _previousPointTouchInSelf = touchPositionInSelf;

            _startingAngle = 0;
            _currentAngle = 0;
            _previousAngle = 0;
        }
        
        if (_touches.count == 2)    //starting point = middle of two points
        {
            _startingPointTouchInContentnode = [self getCenterPointForContentNode];
            _currentPointTouchInContentnode = [self getCenterPointForContentNode];
            _previousPointTouchInContentnode = [self getCenterPointForContentNode];
            
            _startingPointTouchInSelf = [self getCenterPointForSelf];
            _currentPointTouchInSelf = [self getCenterPointForSelf];
            _previousPointTouchInSelf = [self getCenterPointForSelf];
            
            _startingDistance = [self getCurrentDistance];
            _previousDistance = [self getCurrentDistance];
            _currentDistance = [self getCurrentDistance];
            
            _startingAngle = [self getAngleForActiveTouches];
            _currentAngle = [self getAngleForActiveTouches];
            _previousAngle = [self getAngleForActiveTouches];
        }
        [self updateAnchor];
        
    }
    //NSLog(@"Count touches: %lu", (unsigned long)_touches.count);
}
- (void)touchMoved:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    if([_touches containsObject:touch]) //If touch has been processed
    {
        CGPoint touchPositionInContentnode = [touch locationInNode:self.contentNode];
        CGPoint touchPositionInSelf = [touch locationInNode:self];
        
        if (_touches.count == 1)    //drag
        {
            _currentPointTouchInContentnode = touchPositionInContentnode;
            _currentPointTouchInSelf = touchPositionInSelf;
        }
        
        if (_touches.count == 2)    //rotate, drag or scale
        {
            _currentPointTouchInContentnode = [self getCenterPointForContentNode];
            _currentPointTouchInSelf = [self getCenterPointForSelf];
            _currentDistance = [self getCurrentDistance];
    
            float deltadistance = _currentDistance - _previousDistance;
            [self handleZoom:deltadistance];
            
            _currentAngle = [self getAngleForActiveTouches];
            
            float deltaangle = _previousAngle - _currentAngle;
            [self handleRotation:deltaangle];
            
            
        }
        
        //Updates position because of drag, however also the anchor position (anchor node is for debugging purposes)
        [self updatePosition];
        [self updateAnchor];
        
        //Assign previous statuses
        _previousPointTouchInContentnode = _currentPointTouchInContentnode;
        _previousPointTouchInSelf = _currentPointTouchInSelf;
        
        _previousDistance = _currentDistance;
        _previousAngle = _currentAngle;
        
    }
}

- (void)touchEnded:(CCTouch *)touch withEvent:(CCTouchEvent *)event
{
    if([_touches containsObject:touch]) //If touch has been processed
    {
        [_touches removeObject:touch];
        if(_touches.count == 0)
        {
            _startingPointTouchInContentnode = CGPointZero;
            _currentPointTouchInContentnode = CGPointZero;
            _previousPointTouchInContentnode = CGPointZero;
            
            _startingPointTouchInSelf = CGPointZero;
            _currentPointTouchInSelf = CGPointZero;
            _previousPointTouchInSelf = CGPointZero;

        }
        
        else if(_touches.count == 1)
        {
            CCTouch *remainingTouch = [_touches lastObject];
            CGPoint touchPositionInParent = [remainingTouch locationInNode:self.parent];
            CGPoint touchPositionInSelf = [remainingTouch locationInNode:self];
            
            _startingPointTouchInContentnode = touchPositionInParent;
            _currentPointTouchInContentnode = touchPositionInParent;
            _previousPointTouchInContentnode = touchPositionInParent;
            
            _startingPointTouchInSelf = touchPositionInSelf;
            _currentPointTouchInSelf = touchPositionInSelf;
            _previousPointTouchInSelf = touchPositionInSelf;
            
            [self updateAnchor];
        }
        
        _startingDistance = 0;
        _currentDistance = 0;
        _previousDistance = 0;
        
        _startingAngle = 0;
        _currentAngle = 0;
        _previousAngle = 0;
    }
}


#pragma mark Handle events (drag, anchor, zoom, etc...)
-(void)updateAnchor
{    
    CGPoint newAnchorPoint = CGPointMake(_currentPointTouchInContentnode.x / self.contentNode.contentSizeInPoints.width, _currentPointTouchInContentnode.y / self.contentNode.contentSizeInPoints.height);
    [self setAnchorPoint:newAnchorPoint forNode:self.contentNode];
    //For debugging purposes
    //_anchorPointSprite.position = self.contentNode.anchorPointInPoints;
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forNode:(CCNode *)node
//Courtesy of He Shiming: http://stackoverflow.com/questions/2089285/change-sprite-anchorpoint-without-moving-it
{
    CGPoint newPoint = CGPointMake(node.contentSize.width * anchorPoint.x, node.contentSize.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(node.contentSize.width * node.anchorPoint.x, node.contentSize.height * node.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, [node nodeToWorldTransform]);
    oldPoint = CGPointApplyAffineTransform(oldPoint, [node nodeToWorldTransform]);
    
    CGPoint position = node.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    node.position = position;
    node.anchorPoint = anchorPoint;
}


-(void)updatePosition   //:(CGPoint)delta
{
    CGPoint delta = ccpSub(_currentPointTouchInSelf,_previousPointTouchInSelf);
    delta = ccpMult(delta, 1.0f);
    CGPoint newPos = ccpAdd(self.contentNode.position, delta);
    self.contentNode.position = newPos;
}

-(void)handleZoom:(float)delta
{
    float indexedDelta = (delta/500);
    float newScale = self.contentNode.scale + indexedDelta;
    if(newScale > 2 ) {newScale = 2;}
    if(newScale < 0.3 ) {newScale = 0.3;}
    self.contentNode.scale = newScale;
}

-(void)handleRotation:(float)delta
{
    float limiter = 1;  //Decides speed of rotation, the higher the number, the lower the rotation
    float newRotation = self.contentNode.rotation + (delta/limiter);
    self.contentNode.rotation = newRotation;
}


#pragma mark Helper methods
- (GLfloat) calculateDistance:(CGPoint)point1 :(CGPoint)point2
{
    //Positive x Positive Y
    GLfloat dx = point1.x - point2.x;
    GLfloat dy = point1.y - point2.y;
    GLfloat c;
    c = sqrtf((dx*dx) + (dy*dy));
    return c;
}

- (float) angleBetweenPoints:(CGPoint)point1 and:(CGPoint) point2
//Angle in degrees
{
    CGPoint origin = CGPointMake(point2.x - point1.x, point2.y - point1.y);
    float angleRadians = atan2f(origin.y, origin.x);
    float angleDegrees = angleRadians * (180.0 / M_PI);
    
    if(!(angleDegrees > 0.0))
    {
        angleDegrees += 360;
    }
    
    return angleDegrees;
}

-(CGPoint)getCenterOfTwoPoints:(CGPoint)point1 :(CGPoint)point2
{
    float x = (point1.x + point2.x) / 2;
    float y = (point1.y + point2.y) / 2;
    return CGPointMake(x,y);
}

-(CGPoint)getPointAtDistance:(float)distance WithRadAngle:(float)angle fromPoint:(CGPoint)point
{
    CGPoint endPoint;
    endPoint.x = sinf(CC_DEGREES_TO_RADIANS(angle)) * distance;
    endPoint.y = cosf(CC_DEGREES_TO_RADIANS(angle)) * distance;
    endPoint = ccpAdd(point, endPoint);
    return endPoint;
}


@end
