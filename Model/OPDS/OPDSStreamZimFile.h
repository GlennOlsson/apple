//
//  OPDSStreamZimFile.h
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OPDSStreamZimFile : NSObject

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *category;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *fileDescription;
@property (nonatomic, retain) NSString *languageCode;
@property (nonatomic, retain) NSString *creationDate;
@property (nonatomic, retain) NSString *creator;
@property (nonatomic, retain) NSString *publisher;

@property (nonatomic, retain) NSString *url;
@property (nonatomic, retain) NSString *iconURL;

@property (nonatomic, assign) unsigned long long size;
@property (nonatomic, assign) unsigned long long articleCount;
@property (nonatomic, assign) unsigned long long mediaCount;

@property (nonatomic, assign) BOOL hasPictures;
@property (nonatomic, assign) BOOL hasVideos;
@property (nonatomic, assign) BOOL hasIndex;
@property (nonatomic, assign) BOOL hasDetails;

@end

NS_ASSUME_NONNULL_END
