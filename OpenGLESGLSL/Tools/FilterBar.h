//
//  FilterBar.h
//  OpenGLESGLSL
//
//  Created by yz on 2020/8/11.
//  Copyright © 2020 yz. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class FilterBar;

@protocol FilterBarDelegate <NSObject>

- (void)filterBar:(FilterBar *)filterBar didScrollToIndex:(NSUInteger)index;

@end
@interface FilterBar : UIView
@property (nonatomic, strong) NSArray <NSString *> *itemList;

@property (nonatomic, weak) id<FilterBarDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
