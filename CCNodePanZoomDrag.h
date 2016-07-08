//
//  CCNodePanZoomDrag.h
//  shortcut
//
//  Created by Maik Verbaan on 01-07-16.
//  
//

#import "CCNode.h"

@interface CCNodePanZoomDrag : CCNode


@property (atomic, retain) CCNode * contentNode;


- (id)initWithContentnode:(CCNode*)newContentNode;
- (void)setContentNodeSize:(CGSize)newSize;

@end
