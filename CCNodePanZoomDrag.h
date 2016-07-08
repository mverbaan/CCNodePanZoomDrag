//
//  CCNodePanZoomDrag.h
//  shortcut
//
//  Created by Maik Verbaan on 01-07-16.
//  Copyright © 2016 Apportable. All rights reserved.
//

#import "CCNode.h"

@interface CCNodePanZoomDrag : CCNode


@property (atomic, retain) CCNode * contentNode;


- (id)initWithContentnode:(CCNode*)newContentNode;
- (void)setContentNodeSize:(CGSize)newSize;

@end
