//
//  OPDSStreamParser.h
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OPDSStreamZimFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface OPDSStreamParser : NSObject

@property (nonatomic, retain) NSData *data;

- (instancetype _Nonnull)initWithData:(NSData *_Nonnull)data;
- (void)parse;
- (NSArray *_Nonnull)getZimFileIDs NS_REFINED_FOR_SWIFT;
- (OPDSStreamZimFile *_Nullable)getZimFile:(NSString *_Nonnull)identifier NS_REFINED_FOR_SWIFT;

@end

NS_ASSUME_NONNULL_END
