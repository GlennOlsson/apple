//
//  OPDSStreamParser.h
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZimFileMetaData.h"

NS_ASSUME_NONNULL_BEGIN

@interface OPDSStreamParser : NSObject

@property (nonatomic, retain) NSData *data;

- (instancetype _Nonnull)initWithData:(NSData *_Nonnull)data;
- (void)parseData:(NSString *)data error:(NSError **)error;
- (NSArray *_Nonnull)getZimFileIDs NS_REFINED_FOR_SWIFT;
- (ZimFileMetaData *_Nullable)getZimFileMetaData:(NSString *_Nonnull)identifier NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
