//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import "OWSReadReceiptsForLinkedDevicesMessage.h"
#import <SignalServiceKit/OWSLinkedDeviceReadReceipt.h>
#import <SignalServiceKit/SignalServiceKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@interface OWSReadReceiptsForLinkedDevicesMessage ()

@property (nonatomic, readonly) NSArray<OWSLinkedDeviceReadReceipt *> *readReceipts;

@end

@implementation OWSReadReceiptsForLinkedDevicesMessage

- (instancetype)initWithThread:(TSThread *)thread readReceipts:(NSArray<OWSLinkedDeviceReadReceipt *> *)readReceipts
{
    self = [super initWithThread:thread];
    if (!self) {
        return self;
    }

    _readReceipts = [readReceipts copy];

    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    return [super initWithCoder:coder];
}

- (nullable SSKProtoSyncMessageBuilder *)syncMessageBuilderWithTransaction:(SDSAnyReadTransaction *)transaction
{
    SSKProtoSyncMessageBuilder *syncMessageBuilder = [SSKProtoSyncMessage builder];
    for (OWSLinkedDeviceReadReceipt *readReceipt in self.readReceipts) {
        SSKProtoSyncMessageReadBuilder *readProtoBuilder =
            [SSKProtoSyncMessageRead builderWithTimestamp:readReceipt.messageIdTimestamp];

        [readProtoBuilder setSenderE164:readReceipt.senderAddress.phoneNumber];
        [readProtoBuilder setSenderUuid:readReceipt.senderAddress.uuidString];

        NSError *error;
        SSKProtoSyncMessageRead *_Nullable readProto = [readProtoBuilder buildAndReturnError:&error];
        if (error || !readProto) {
            OWSFailDebug(@"could not build protobuf: %@", error);
            return nil;
        }
        [syncMessageBuilder addRead:readProto];
    }
    return syncMessageBuilder;
}

- (NSSet<NSString *> *)relatedUniqueIds
{
    NSMutableArray<NSString *> *messageUniqueIds = [[NSMutableArray alloc] init];
    for (OWSLinkedDeviceReadReceipt *readReceipt in self.readReceipts) {
        if (readReceipt.messageUniqueId) {
            [messageUniqueIds addObject:readReceipt.messageUniqueId];
        }
    }
    return [[super relatedUniqueIds] setByAddingObjectsFromArray:messageUniqueIds];
}


@end

NS_ASSUME_NONNULL_END
