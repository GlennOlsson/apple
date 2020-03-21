//
//  OPDSStreamZimFile.m
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import "ZimFileMetaData.h"
#include "book.h"

#define SAFE_READ(X, Y) try {X = Y;} catch (std::exception) {X = nil;}
#define SAFE_READ_BOOL(X, Y) try {X = Y;} catch (std::exception) {X = false;}

@interface ZimFileMetaData ()

@property (assign) kiwix::Book *book;

@end

@implementation ZimFileMetaData

- (nullable instancetype)initWithBook:(void *)book {
    self = [super init];
    if (self) {
        self.book = (kiwix::Book *)book;
        
        try {
            self.identifier = [NSString stringWithUTF8String:self.book->getId().c_str()];
            self.title = [NSString stringWithUTF8String:self.book->getTitle().c_str()];
            self.name = [NSString stringWithUTF8String:self.book->getName().c_str()];
            self.fileDescription = [NSString stringWithUTF8String:self.book->getDescription().c_str()];
            self.languageCode = [NSString stringWithUTF8String:self.book->getLanguage().c_str()];
        } catch (std::exception) {
            return nil;
        }
        
        SAFE_READ(self.creator, [NSString stringWithUTF8String:self.book->getCreator().c_str()]);
        SAFE_READ(self.publisher, [NSString stringWithUTF8String:self.book->getPublisher().c_str()]);
        SAFE_READ(self.url, [NSURL URLWithString:[NSString stringWithUTF8String:self.book->getUrl().c_str()]]);
        SAFE_READ(self.faviconURL,
                  [NSURL URLWithString:[NSString stringWithUTF8String:self.book->getFaviconUrl().c_str()]]);
        SAFE_READ(self.size, [NSNumber numberWithUnsignedLongLong:self.book->getSize()]);
        SAFE_READ(self.articleCount, [NSNumber numberWithUnsignedLongLong:self.book->getArticleCount()]);
        SAFE_READ(self.mediaCount, [NSNumber numberWithUnsignedLongLong:self.book->getMediaCount()]);
        
        SAFE_READ_BOOL(self.hasDetails, self.book->getTagBool("details"));
        SAFE_READ_BOOL(self.hasIndex, self.book->getTagBool("ftindex"));
        SAFE_READ_BOOL(self.hasPictures, self.book->getTagBool("pictures"));
        SAFE_READ_BOOL(self.hasVideos, self.book->getTagBool("videos"));
    }
    return self;
}

- (NSString *)category {
    try {
        return [NSString stringWithUTF8String:self.book->getTagStr("category").c_str()];
    } catch (std::out_of_range e) {
        return @"other";
    }
}

- (NSDate *)creationDate {
    try {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd";
        return [formatter dateFromString:[NSString stringWithUTF8String:self.book->getDate().c_str()]];
    } catch (std::out_of_range e) {
        return nil;
    }
}

- (NSData *)favicon {
    try {
        std::string favicon = self.book->getFavicon();
        return [NSData dataWithBytes:favicon.c_str() length:favicon.length()];
    } catch (std::out_of_range e) {
        return nil;
    }
}

@end
