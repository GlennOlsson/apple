//
//  OPDSStreamParser.mm
//  Kiwix
//
//  Created by Chris Li on 3/8/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

#import "OPDSStreamParser.h"
#import "ZimFileMetaData.h"
#include "book.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
#include "library.h"
#include "manager.h"
#include "otherTools.h"
#pragma clang diagnostic pop

@interface OPDSStreamParser ()

@property (assign) kiwix::Library *library;

@end

@implementation OPDSStreamParser

kiwix::Library *library = nullptr;

- (instancetype _Nonnull)init {
    self = [super init];
    if (self) {
        self.library = new kiwix::Library();
    }
    return self;
}

- (void)dealloc {
    delete library;
}

- (BOOL)parseData:(nonnull NSData *)data error:(NSError **)error {
    try {
        NSString *streamContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        std::shared_ptr<kiwix::Manager> manager = std::make_shared<kiwix::Manager>(library);
        manager->readOpds([streamContent cStringUsingEncoding:NSUTF8StringEncoding],
                          [@"https://library.kiwix.org" cStringUsingEncoding:NSUTF8StringEncoding]);
        return true;
    } catch (std::exception) {
        *error = [[NSError alloc] init];
        return false;
    }
}

- (NSArray *)getZimFileIDs {
    NSMutableArray *identifiers = [[NSMutableArray alloc] initWithCapacity:library->getBookCount(false, true)];
    for (auto identifierC: library->getBooksIds()) {
        NSString *identifier = [NSString stringWithUTF8String:identifierC.c_str()];
        [identifiers addObject:identifier];
    }
    return identifiers;
}

- (ZimFileMetaData *)getZimFileMetaData:(NSString *)identifier {
    std::string identifierC = [identifier cStringUsingEncoding:NSUTF8StringEncoding];
    kiwix::Book book = library->getBookById(identifierC);
    return [[ZimFileMetaData alloc] initWithBook: &book];
}

@end
