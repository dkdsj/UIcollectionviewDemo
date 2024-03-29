//
//  CCCTagLayout.m
//  OCCollectionViewDemo
//
//  Created by ZZ on 2019/11/28.
//  Copyright © 2019 ZZ. All rights reserved.
//

#import "CCCTagLayout.h"

@interface CCCTagLayout ()

/** 总的布局对象数组，包括item，sectionHeader，footerHeader */
@property (nonatomic, strong) NSMutableArray *attributesArray;
/** item的布局对象数组 */
@property (nonatomic, strong) NSMutableArray *itemsAttributes;
/** header的布局对象数组 */
@property (nonatomic, strong) NSMutableArray *headerAttributes;
/** footer的布局对象数组 */
@property (nonatomic, strong) NSMutableArray *footerAttributes;
/** 计算 collectionview 的内容高度 */
@property (nonatomic, assign) CGFloat contentHeight;
/** collectionview 自身减去inset的宽度 */
@property (nonatomic, assign) CGFloat viewWidth;

@end

@implementation CCCTagLayout

#pragma mark - initialize
- (instancetype)init {
    if (self = [super init]) {
        
        //设置间距的默认值
        self.headerViewHeight = 0.0;
        self.footerViewHeight = 0.0;
        self.interitemSpacing = 8.0;
        self.lineSpacing = 8.0;
        self.itemHeight = 30.0;
        self.itemInset = UIEdgeInsetsZero;
        self.headerInset = UIEdgeInsetsZero;
        self.footerInset = UIEdgeInsetsZero;
        self.labelFont = [UIFont systemFontOfSize:15.0];
    }
    return self;
}

- (instancetype)initWithHeaderViewHeight:(CGFloat)headerViewHeight
                        footerViewHeight:(CGFloat)footerViewHeight
                               itemSpace:(CGFloat)itemSpace
                               lineSpace:(CGFloat)lineSpace
                              itemHeight:(CGFloat)itemHeight
                               itemInset:(UIEdgeInsets)itemInset
                             headerInset:(UIEdgeInsets)headerInset
                             footerInset:(UIEdgeInsets)footerInset
                               labelFont:(UIFont *)labelFont {
    if (self = [super init]) {
        //设置间距的默认值
        self.headerViewHeight = headerViewHeight;
        self.footerViewHeight = footerViewHeight;
        self.interitemSpacing = itemSpace;
        self.lineSpacing = lineSpace;
        self.itemHeight = itemHeight;
        self.itemInset = itemInset;
        self.headerInset = headerInset;
        self.footerInset = footerInset;
        self.labelFont = labelFont;
    }
    return self;
}

/** 1、当collectionView布局item时 第一个执行的方法 */
- (void)prepareLayout {
    NSLog(@"logss----%s", __func__);
    
    /** 重写layout中的方法 首先必须调用父类 */
    [super prepareLayout];
    
    self.viewWidth = UIScreen.mainScreen.bounds.size.width - self.itemInset.left - self.itemInset.right;
    //所有内容的布局属性数组
    self.attributesArray = [NSMutableArray array];
    
    //item的数据模型是2原数组,就是第一层数组包含的是section,第二层是每个section包含的item
    self.itemsAttributes = [NSMutableArray array];
    //记录 collectionview 的内容高度
    self.contentHeight = 0.0;
    
    /** 获取collectionView 中的item的个数 */
    NSInteger sectionCount = [self.collectionView numberOfSections];
    /** 遍历得到每个item 设置位置信息 */
    for (NSInteger i = 0; i < sectionCount; i++) {
        
        NSInteger itemCount = [self.collectionView numberOfItemsInSection:i];
        for (NSInteger j = 0; j < itemCount; j++) {
            
            //设置每个item的attribute
            [self setItemFrameWithIndexPath:[NSIndexPath indexPathForItem:j inSection:i]];
            
            //这里是当最后一个 item 的 layoutAttributes 设置完成后如果有设置 footer 就要把 footer 添加到所有 layoutAttributes 数组
            if ( (i == sectionCount - 1) && ( j == itemCount - 1) ) {
                if ( [self.delegate respondsToSelector:@selector(collectionViewDynamicFooterSizeWithIndexPath:)] ) {
                    
                    //获取最后一个 item 的 layoutAttributes
                    UICollectionViewLayoutAttributes *lastAttributes = self.attributesArray.lastObject;
                    //添加 footer 的 layoutAttributes
                    [self makeFooterAttributesWithLastItemAttributes:lastAttributes];
                    
                    // 获取新添加的 footer 的 layoutAttributes
                    UICollectionViewLayoutAttributes *footerAttributes = self.footerAttributes.lastObject;
                    //计算总高度
                    self.contentHeight = CGRectGetMaxY(footerAttributes.frame) + self.itemInset.bottom;
                }
            }
        }
    }
}

- (void)setItemFrameWithIndexPath:(NSIndexPath *)indexPath {
    
    //这里主要是设置一下 item 的初始 frame
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    CGFloat width = [self countItemSizeWithIndexPath:indexPath];
    CGFloat height = self.itemHeight;
    
    // 获取数组最后一个 layoutAttributes, 这样方便计算 frame 和 判断是否需要计算新的 section
    UICollectionViewLayoutAttributes *lastAttributes = self.attributesArray.lastObject;
    
    if ( lastAttributes ) {
        //如果数组有值代表不是设置第一个item
        if ( lastAttributes.indexPath.section == indexPath.section ) {
            //同一组
            if ( CGRectGetMaxX(lastAttributes.frame) + self.interitemSpacing + width > self.viewWidth ) {
                //需要换行
                x = self.itemInset.left + self.lineSpacing;
                y = CGRectGetMaxY(lastAttributes.frame) + self.lineSpacing;
            } else {
                //不需要换行
                x = CGRectGetMaxX(lastAttributes.frame) + self.interitemSpacing;
                y = CGRectGetMinY(lastAttributes.frame);
            }
        } else {
            //不同一组
            //添加 footer 的布局,内部会判断是否需要添加
            [self makeFooterAttributesWithLastItemAttributes:lastAttributes];
            
            //添加一个新的 section 数组
            [self.itemsAttributes addObject:[NSMutableArray array]];
            
            //这里重新获取最后一个 layoutAttributes 是因为如果加入了 footer 总的 layoutAttributes就会改变
            lastAttributes = self.attributesArray.lastObject;
            
            //添加 header 的布局,内部会判断是否需要添加
            [self makeHeaderAttributesWithIndexPath:indexPath lastItemAttributes:lastAttributes];
            
            //设置新的 section 的第一个 item 的 frame
            x = self.itemInset.left + self.lineSpacing;
            y = CGRectGetMaxY(lastAttributes.frame) + self.lineSpacing * 2 + self.headerViewHeight;
        }
    } else {
        //这里是设置第一个section的item
        [self.itemsAttributes addObject:[NSMutableArray array]];
        
        //添加 header 的布局,内部会判断是否需要添加
        [self makeHeaderAttributesWithIndexPath:indexPath lastItemAttributes:lastAttributes];
        
        //这里判断是否有 header, 如果有就获取最后一个 layoutAttributes
        if ( self.headerAttributes.count ) {
            lastAttributes = self.attributesArray.lastObject;
        }
        
        //设置新的 section 的第一个 item 的 frame
        x = self.itemInset.left + self.lineSpacing;
        y = self.lineSpacing + lastAttributes.size.height;
    }
    
    //设置每一个 item 的 frame
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    /** 添加frame */
    attributes.frame = CGRectMake(x, y, width, height);
    self.contentHeight = CGRectGetMaxY(attributes.frame) + self.lineSpacing;
    
    /** 保存在数组中 */
    [self.itemsAttributes[indexPath.section] addObject:attributes];
    [self.attributesArray addObject:attributes];
}

#pragma mark - New Header Or Footer
- (void)makeHeaderAttributesWithIndexPath:(NSIndexPath *)indexPath lastItemAttributes:(UICollectionViewLayoutAttributes *)attributes {
    //设置第一个section的header
    UICollectionViewLayoutAttributes *headerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader withIndexPath:indexPath];
    
    CGFloat y = (attributes)?(CGRectGetMaxY(attributes.frame) + self.lineSpacing):self.itemInset.top;
    CGFloat headerWidth =  0.0;
    CGFloat headerHeight =  0.0;
    
    if ( [self.delegate respondsToSelector:@selector(collectionViewDynamicHeaderSizeWithIndexPath:)] ) {
        CGSize size = [self.delegate collectionViewDynamicHeaderSizeWithIndexPath:indexPath];
        
        headerWidth = size.width;
        headerHeight = size.height;
    }else {
        headerWidth = UIScreen.mainScreen.bounds.size.width - self.headerInset.left - self.headerInset.right;
        headerHeight = self.headerViewHeight;
    }
    
    if ( headerHeight > 0.0 ) {
        headerAttributes.frame = CGRectMake(self.headerInset.left, y, headerWidth, headerHeight);
        
        [self.headerAttributes addObject:headerAttributes];
        [self.attributesArray addObject:headerAttributes];
    }
}

- (void)makeFooterAttributesWithLastItemAttributes:(UICollectionViewLayoutAttributes *)attributes {
    
    UICollectionViewLayoutAttributes *footerAttributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionFooter withIndexPath:attributes.indexPath];
    
    CGFloat footerWidth =  0.0;
    CGFloat footerHeight =  0.0;
    if ( [self.delegate respondsToSelector:@selector(collectionViewDynamicFooterSizeWithIndexPath:)] ) {
        
        CGSize size = [self.delegate collectionViewDynamicFooterSizeWithIndexPath:attributes.indexPath];
        footerWidth = size.width;
        footerHeight = size.height;
    } else {
        footerWidth = UIScreen.mainScreen.bounds.size.width - self.footerInset.left - self.footerInset.right;
        footerHeight = self.footerViewHeight;
    }
    
    if ( footerHeight > 0 ) {
        footerAttributes.frame = CGRectMake(self.footerInset.left, CGRectGetMaxY(attributes.frame) + self.lineSpacing, footerWidth, footerHeight);
        [self.footerAttributes addObject:footerAttributes];
        [self.attributesArray addObject:footerAttributes];
    }
    
}

#pragma mark - 布局
//这个是返回所有 header, footer, item 属性的回调方法, 一定要实现
- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSLog(@"logss----%s", __func__);
    return self.attributesArray;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"logss----%s", __func__);
    return self.itemsAttributes[indexPath.section][indexPath.item];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"logss----%s", __func__);
    if ( [elementKind isEqual: UICollectionElementKindSectionHeader] ) {
        return self.headerAttributes[indexPath.section];
    }else {
        return self.footerAttributes[indexPath.section];
    }
}

/** 4、设置滚动范围 */
// 这里可以处理 uicollectionview 内容不够屏幕高度不能滑动的问题,只要把 contentsize.height 设置成比屏幕高度大就可以了
- (CGSize)collectionViewContentSize {
    NSLog(@"logss----%s", __func__);
    
    return CGSizeMake(0.0, self.contentHeight + self.itemInset.bottom);
}

//计算每个item的size
- (CGFloat)countItemSizeWithIndexPath:(NSIndexPath *)indexPath {
    NSString *content = [self.delegate collectionViewItemSizeWithIndexPath:indexPath];
    
    CGSize size = [content sizeWithAttributes:@{NSFontAttributeName:self.labelFont}];
    
    return MAX(size.width + 24.0, self.itemHeight);
}


#pragma mark - lazy
// header 的布局属性数组
- (NSMutableArray *)headerAttributes {
    if ( !_headerAttributes ) {
        _headerAttributes = [NSMutableArray array];
    }
    return _headerAttributes;
}

// footer 的布局属性数组
- (NSMutableArray *)footerAttributes {
    if ( !_footerAttributes ) {
        _footerAttributes = [NSMutableArray array];
    }
    return _footerAttributes;
}

@end
