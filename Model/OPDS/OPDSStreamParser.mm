//
//  OPDSStreamParser.m
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import "OPDSStreamParser.h"
#include "book.h"
#include "library.h"
#include "manager.h"

@implementation OPDSStreamParser

kiwix::Library *library = new kiwix::Library();

- (instancetype _Nonnull)initWithData:(NSData *_Nonnull)data {
    self = [super init];
    if (self) {
        self.data = data;
    }
    return self;
}

- (void)dealloc {
    delete library;
}

- (void)parse {
    NSString *streamContent = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    
    std::shared_ptr<kiwix::Manager> manager = std::make_shared<kiwix::Manager>(library);
    manager->readOpds([streamContent cStringUsingEncoding:NSUTF8StringEncoding],
                      [@"http://library.kiwix.org" cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (NSArray *)getZimFileIDs {
    NSMutableArray *identifiers = [[NSMutableArray alloc] initWithCapacity:library->getBookCount(false, true)];
    for (auto identifierC: library->getBooksIds()) {
        NSString *identifier = [NSString stringWithUTF8String:identifierC.c_str()];
        [identifiers addObject:identifier];
    }
    return identifiers;
}

- (OPDSStreamZimFile *)getZimFile:(NSString *)identifier {
    std::string identifierC = [identifier cStringUsingEncoding:NSUTF8StringEncoding];
    try {
        kiwix::Book book = library->getBookById(identifierC);
        OPDSStreamZimFile *zimFile = [[OPDSStreamZimFile alloc] init];
        
        zimFile.identifier = [NSString stringWithUTF8String:book.getId().c_str()];
        zimFile.name = [NSString stringWithUTF8String:book.getName().c_str()];
        zimFile.category = [NSString stringWithUTF8String:book.getTagStr("_category").c_str()];
        zimFile.title = [NSString stringWithUTF8String:book.getTitle().c_str()];
        zimFile.fileDescription = [NSString stringWithUTF8String:book.getDescription().c_str()];
        zimFile.languageCode = [NSString stringWithUTF8String:book.getName().c_str()];
        zimFile.creationDate = [NSString stringWithUTF8String:book.getDate().c_str()];
        zimFile.creator = [NSString stringWithUTF8String:book.getCreator().c_str()];
        zimFile.publisher = [NSString stringWithUTF8String:book.getPublisher().c_str()];
        
        zimFile.url = [NSString stringWithUTF8String:book.getFaviconUrl().c_str()];
        zimFile.iconURL = [NSString stringWithUTF8String:book.getFaviconUrl().c_str()];
        
        zimFile.size = book.getSize();
        zimFile.articleCount = book.getArticleCount();
        zimFile.mediaCount = book.getMediaCount();
        
        zimFile.hasPictures = book.getTagBool("_pictures");
        zimFile.hasVideos = book.getTagBool("_videos");
        zimFile.hasIndex = book.getTagBool("_ftindex");
        zimFile.hasDetails = book.getTagBool("_details");
        
        return zimFile;
    } catch (std::out_of_range) {
        return nil;
    }
}

@end
