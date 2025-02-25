
#import "RNMailCore.h"
#import <MailCore/MailCore.h>
#import <React/RCTConvert.h>

@implementation RNMailCore
  

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(loginSmtp:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
  smtpSession.hostname = [RCTConvert NSString:obj[@"hostname"]];
  smtpSession.port = [RCTConvert int:obj[@"port"]];
  smtpSession.username = [RCTConvert NSString:obj[@"username"]];
  smtpSession.password = [RCTConvert NSString:obj[@"password"]];
  smtpSession.authType = MCOAuthTypeSASLPlain;
  smtpSession.connectionType = MCOConnectionTypeTLS;
  _smtpObject = smtpSession;
  MCOSMTPOperation *smtpOperation = [_smtpObject loginOperation];
  [smtpOperation start:^(NSError *error) {
      if(error) {
        NSLog(@"Error sending email: %@", error);
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSLog(@"Successfully sent email!");
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}

RCT_EXPORT_METHOD(loginImap:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  MCOIMAPSession *imapSession = [[MCOIMAPSession alloc] init];
  imapSession.hostname = [RCTConvert NSString:obj[@"hostname"]];
  imapSession.port = [RCTConvert int:obj[@"port"]];
  imapSession.username = [RCTConvert NSString:obj[@"username"]];
  imapSession.password = [RCTConvert NSString:obj[@"password"]];
  imapSession.authType = MCOAuthTypeSASLPlain;
  imapSession.connectionType = MCOConnectionTypeTLS;
  _imapObject = imapSession;
  MCOIMAPOperation *imapOperation = [_imapObject checkAccountOperation];
  [imapOperation start:^(NSError *error) {
      if(error) {
        NSLog(@"Error sending email: %@", error);
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSLog(@"Successfully sent email!");
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}

RCT_EXPORT_METHOD(createFolder:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  MCOIMAPOperation *imapOperation = [_imapObject createFolderOperation: [RCTConvert NSString:obj[@"folder"]]];
  [imapOperation start:^(NSError *error) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}

RCT_EXPORT_METHOD(renameFolder:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  MCOIMAPOperation *imapOperation = [_imapObject renameFolderOperation:[RCTConvert NSString:obj[@"folderOldName"]] otherName:[RCTConvert NSString:obj[@"folderNewName"]]];
  [imapOperation start:^(NSError *error) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}

RCT_EXPORT_METHOD(deleteFolder:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  MCOIMAPOperation *imapOperation = [_imapObject deleteFolderOperation: [RCTConvert NSString:obj[@"folder"]]];
  [imapOperation start:^(NSError *error) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}

RCT_EXPORT_METHOD(getFolders:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  MCOIMAPFetchFoldersOperation *imapOperation = [_imapObject fetchAllFoldersOperation];
  [imapOperation start:^(NSError *error, NSArray * fetchedFolders) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSMutableArray *folders = [[NSMutableArray alloc] init];
        for(int i=0;i < fetchedFolders.count;i++) {
          NSMutableDictionary *folderObject = [[NSMutableDictionary alloc] init];
          MCOIMAPFolder *folder = fetchedFolders[i];
            
          int flags = folder.flags;
          [folderObject setObject:[NSString stringWithFormat:@"%d",flags] forKey:@"flags"];
          [folderObject setObject:folder.path forKey:@"folder"];
          NSDictionary *mapFolder = @{@"folder": folder.path};
            
          [folders addObject:folderObject];
        }
        resolve(folders);
      }
    }];
}

RCT_EXPORT_METHOD(actionFlagMessage:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *folder = [RCTConvert NSString:obj[@"folder"]];
  NSNumber *messageId = [RCTConvert NSNumber:obj[@"messageId"]];
  unsigned long long valueUInt64 = messageId.unsignedLongLongValue;
  MCOIndexSet *uid = [MCOIndexSet indexSetWithIndex:valueUInt64];
  NSNumber *flagsRequestKind = [RCTConvert NSNumber:obj[@"flagsRequestKind"]];
  NSNumber *messageFlag = [RCTConvert NSNumber:obj[@"messageFlag"]];
  MCOIMAPOperation *imapOperation = [_imapObject storeFlagsOperationWithFolder:folder uids:uid kind:flagsRequestKind.unsignedLongLongValue flags:messageFlag.unsignedLongLongValue];
  [imapOperation start:^(NSError *error) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}


RCT_EXPORT_METHOD(actionLabelMessage:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *folder = [RCTConvert NSString:obj[@"folder"]];
  NSNumber *messageId = [RCTConvert NSNumber:obj[@"messageId"]];
  unsigned long long valueUInt64 = messageId.unsignedLongLongValue;
  MCOIndexSet *uid = [MCOIndexSet indexSetWithIndex:valueUInt64];
  NSNumber *flagsRequestKind = [RCTConvert NSNumber:obj[@"flagsRequestKind"]];
  NSArray *tags = [RCTConvert NSArray:obj[@"tags"]];
  MCOIMAPOperation *imapOperation = [_imapObject storeLabelsOperationWithFolder:folder uids:uid kind:flagsRequestKind.unsignedLongLongValue labels:tags];
  [imapOperation start:^(NSError *error) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}

RCT_EXPORT_METHOD(moveEmail:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *folderFrom = [RCTConvert NSString:obj[@"folderFrom"]];
  NSNumber *messageId = [RCTConvert NSNumber:obj[@"messageId"]];
  unsigned long long valueUInt64 = messageId.unsignedLongLongValue;
  MCOIndexSet *uid = [MCOIndexSet indexSetWithIndex:valueUInt64];
  NSString *folderTo = [RCTConvert NSString:obj[@"folderTo"]];
  MCOIMAPCopyMessagesOperation *imapOperation = [_imapObject copyMessagesOperationWithFolder:folderFrom uids:uid destFolder:folderTo];
  [imapOperation start:^(NSError *error, NSDictionary * uidMapping) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        //[self permantDelete:obj resolver:resolve rejecter:reject];
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}

RCT_EXPORT_METHOD(permantDeleteEmail:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *folder = [RCTConvert NSString:obj[@"folder"]];
  NSNumber *messageId = [RCTConvert NSNumber:obj[@"messageId"]];
  unsigned long long valueUInt64 = messageId.unsignedLongLongValue;
  MCOIndexSet *uid = [MCOIndexSet indexSetWithIndex:valueUInt64];
  MCOIMAPOperation *imapOperation = [_imapObject storeFlagsOperationWithFolder:folder uids:uid kind:0 flags:8];
  [imapOperation start:^(NSError *error) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
      }
    }];
    imapOperation = [_imapObject expungeOperation:folder];
    [imapOperation start:^(NSError * error) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
    }];
}

RCT_EXPORT_METHOD(sendMail:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  MCOMessageBuilder *messageBuilder = [[MCOMessageBuilder alloc] init];
  if([obj objectForKey:@"headers"]) {
    NSDictionary *headerObj = [RCTConvert NSDictionary:obj[@"headers"]];
    for(id key in headerObj) {
      [[messageBuilder header] setExtraHeaderValue:[headerObj objectForKey:key] forName:key];
    }
  }

  NSDictionary *fromObj = [RCTConvert NSDictionary:obj[@"from"]];
  [[messageBuilder header] setFrom:[MCOAddress addressWithDisplayName:[fromObj objectForKey:@"addressWithDisplayName"] mailbox:[fromObj objectForKey:@"mailbox"]]];

  NSDictionary *toObj = [RCTConvert NSDictionary:obj[@"to"]];
  NSMutableArray *toArray = [[NSMutableArray alloc] init];
  for(id toKey in toObj) {
    [toArray addObject:[MCOAddress addressWithDisplayName:[toObj objectForKey:toKey] mailbox:toKey]];
  }
  [[messageBuilder header] setTo:toArray];

  if([obj objectForKey:@"cc"]) {
    NSDictionary *ccObj = [RCTConvert NSDictionary:obj[@"cc"]];
    NSMutableArray *ccArray = [[NSMutableArray alloc] init];
    for(id ccKey in ccObj) {
      [ccArray addObject:[MCOAddress addressWithDisplayName:[ccObj objectForKey:ccKey] mailbox:ccKey]];
    }
    [[messageBuilder header] setCc:ccArray];
  }

  if([obj objectForKey:@"bcc"]) {
    NSDictionary *bccObj = [RCTConvert NSDictionary:obj[@"bcc"]];
    NSMutableArray *bccArray = [[NSMutableArray alloc] init];
    for(id bccKey in bccObj) {
      [bccArray addObject:[MCOAddress addressWithDisplayName:[bccObj objectForKey:bccKey] mailbox:bccKey]];
    }
    [[messageBuilder header] setBcc:bccArray];
  }

  if([obj objectForKey:@"subject"]) {
    [[messageBuilder header] setSubject:[RCTConvert NSString:obj[@"subject"]]];
  }

  if([obj objectForKey:@"body"]) {
    [messageBuilder setHTMLBody:[RCTConvert NSString:obj[@"body"]]];
  }

  if([obj objectForKey:@"attachments"]) {
    // TODO
    NSArray *attachmentObj = [RCTConvert NSArray:obj[@"attachments"]];
    for(id attachment in attachmentObj) {
      NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
      documentsURL = [documentsURL URLByAppendingPathComponent:attachment];
      NSData *fileData = [NSData dataWithContentsOfURL:documentsURL];
      MCOAttachment *attach = [MCOAttachment attachmentWithData:fileData filename:attachment];
      [messageBuilder addAttachment:attach];
    }
  }

  MCOSMTPSendOperation *sendOperation = [_smtpObject sendOperationWithData:[messageBuilder data]];
  [sendOperation start:^(NSError *error) {
      if(error) {
        reject(@"Error", error.localizedDescription, error);
      } else {
        NSDictionary *result = @{@"status": @"SUCCESS"};
        resolve(result);
      }
  }];
}

RCT_EXPORT_METHOD(getMail:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *folder = [RCTConvert NSString:obj[@"folder"]];
  NSNumber *messageId = [RCTConvert NSNumber:obj[@"messageId"]];
  unsigned long long valueUInt64 = messageId.unsignedLongLongValue;
  MCOIndexSet *uid = [MCOIndexSet indexSetWithIndex:valueUInt64];
  int requestKind = [RCTConvert int:obj[@"requestKind"]];
  
  MCOIMAPFetchMessagesOperation *fetchOperation = [_imapObject fetchMessagesOperationWithFolder:folder requestKind:requestKind uids:uid];

  NSArray *extraHeadersRequest = [RCTConvert NSArray:obj[@"headers"]];
  if (extraHeadersRequest != nil && extraHeadersRequest.count > 0) {
    [fetchOperation setExtraHeaders:extraHeadersRequest];
  }
    
  [fetchOperation start:^(NSError * error, NSArray * fetchedMessages, MCOIndexSet * vanishedMessages) 
  {
    if(error) {
      reject(@"Error", error.localizedDescription, error);
    } else {
      MCOIMAPMessage *message = fetchedMessages[0];
      NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
      NSString *messageUid = [NSString stringWithFormat:@"%d",message.uid];
      [result setValue:messageUid forKey:@"id"];
      int flags = message.flags;
      [result setObject:[NSString stringWithFormat:@"%d",flags] forKey:@"flags"];
      //mailData.putString("date", message.header().date().toString());
  
      NSMutableDictionary *fromData = [[NSMutableDictionary alloc] init];
      [fromData setValue:message.header.from.mailbox forKey:@"mailbox"];
      [fromData setValue:message.header.from.displayName forKey:@"displayName"];
      [result setObject:fromData forKey:@"from"];

      if(message.header.cc != nil) {
        NSMutableDictionary *toData = [[NSMutableDictionary alloc] init];
        for(MCOAddress *toAddress in message.header.to) {
          [toData setValue:[toAddress displayName] forKey:[toAddress mailbox]];
        }
        [result setObject:toData forKey:@"to"];
      }
      
      if(message.header.cc != nil) {
        NSMutableDictionary *ccData = [[NSMutableDictionary alloc] init];
        for(MCOAddress *ccAddress in message.header.cc) {
          [ccData setValue:[ccAddress displayName] forKey:[ccAddress mailbox]];
        }
        [result setObject:ccData forKey:@"cc"];
      }

      if(message.header.bcc != nil) {
        NSMutableDictionary *bccData = [[NSMutableDictionary alloc] init];
        for(MCOAddress *bccAddress in message.header.bcc) {
          [bccData setValue:[bccAddress displayName] forKey:[bccAddress mailbox]];
        }
        [result setObject:bccData forKey:@"bcc"];
      }

      [result setValue:message.header.subject forKey:@"subject"];

      if ([message.attachments count] > 0){
        NSMutableDictionary *attachmentsData = [[NSMutableDictionary alloc] init];
        for(MCOIMAPPart *part in message.attachments) {
          NSMutableDictionary *attachmentData = [[NSMutableDictionary alloc] init];
          NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
          NSString *saveDirectory = [paths objectAtIndex:0];
          NSString *attachmentPath = [saveDirectory stringByAppendingPathComponent:part.filename];
          int encod = part.encoding;
          int size = part.size;
          NSString *sizeS = [NSString stringWithFormat:@"%d",size];
          [attachmentData setValue:attachmentPath forKey:@"filename"];
          [attachmentData setValue:sizeS forKey:@"size"];
          [attachmentData setValue:[NSString stringWithFormat:@"%d",encod] forKey:@"encoding"];
          [attachmentsData setObject:attachmentData forKey:part.partID];
        }
        [result setObject:attachmentsData forKey:@"attachments"];
      }

      NSMutableArray *headers = [[NSMutableArray alloc] init];
      NSArray *extraHeaderNames = [message.header allExtraHeadersNames];
      if (extraHeaderNames != nil && extraHeaderNames.count > 0){
        for(NSString *headerKey in extraHeaderNames) {
          NSMutableDictionary *header = [[NSMutableDictionary alloc] init];
          [header setObject:[message.header extraHeaderValueForName:headerKey] forKey:headerKey];
          [headers addObject:header];
        }
      }
      [result setObject: headers forKey: @"headers"];

      MCOIMAPFetchContentOperation *operation = [_imapObject fetchMessageOperationWithFolder:folder uid:message.uid];
      [operation start:^(NSError *error, NSData *data) {
        if(error) {
          reject(@"Error", error.localizedDescription, error);
        } else {
            MCOMessageParser *messageParser = [[MCOMessageParser alloc] initWithData:data];
            NSString *msgHTMLBody = [messageParser htmlBodyRendering];
            [result setValue:msgHTMLBody forKey:@"body"];
            [result setValue:@"SUCCESS123" forKey:@"status"];
            resolve(result);
        }
      }];
    }
  }];
}

RCT_EXPORT_METHOD(getMails:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *folder = [RCTConvert NSString:obj[@"folder"]];
  int requestKind = [RCTConvert int:obj[@"requestKind"]];
  MCOIndexSet *uids = [MCOIndexSet indexSetWithRange:MCORangeMake(1, UINT64_MAX)];
  MCOIMAPFetchMessagesOperation * fetchMessagesOperationWithFolderOperation = [_imapObject fetchMessagesOperationWithFolder:folder 
    requestKind:requestKind uids:uids];

  NSArray *extraHeadersRequest = [RCTConvert NSArray:obj[@"headers"]];
  if (extraHeadersRequest != nil && extraHeadersRequest.count > 0) {
    [fetchMessagesOperationWithFolderOperation setExtraHeaders:extraHeadersRequest];
  }

  [fetchMessagesOperationWithFolderOperation start:^(NSError * error, NSArray * messages, MCOIndexSet * vanishedMessages) {
    if(error) {
      reject(@"Error", error.localizedDescription, error);
    } else {

      NSMutableArray *mails = [[NSMutableArray alloc] init];
      NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
      [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];

      for(MCOIMAPMessage * message in messages) {
        NSMutableDictionary *mail = [[NSMutableDictionary alloc] init];
          
        NSMutableArray *headers = [[NSMutableArray alloc] init];
        NSArray *extraHeaderNames = [message.header allExtraHeadersNames];
        if (extraHeaderNames != nil && extraHeaderNames.count > 0){
          for(NSString *headerKey in extraHeaderNames) {
            NSMutableDictionary *header = [[NSMutableDictionary alloc] init];
            [header setObject:[message.header extraHeaderValueForName:headerKey] forKey:headerKey];
            [headers addObject:header];
          }
        }
        [mail setObject: headers forKey: @"headers"];
          
        [mail setObject:[NSString stringWithFormat:@"%d",[message uid]] forKey:@"id"];
          int flags = message.flags;
        [mail setObject:[NSString stringWithFormat:@"%d",flags] forKey:@"flags"];
        [mail setObject:message.header.from.displayName forKey:@"from"];
        [mail setObject:message.header.subject forKey:@"subject"];
        [mail setObject:[dateFormat stringFromDate:message.header.date] forKey:@"date"];
        if (message.attachments != nil) {
          [mail setObject:[NSString stringWithFormat:@"%lu", message.attachments.count] forKey:@"attachments"];
        } else {
          [mail setObject:[NSString stringWithFormat:@"%d",0] forKey:@"attachments"];
        }
        [mails addObject:mail];
      }

      NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
      [result setObject: @"SUCCESS" forKey: @"status"];
      [result setObject: mails forKey: @"mails"];
      resolve(result);
    }
  }];
}

RCT_EXPORT_METHOD(getAttachment:(NSDictionary *)obj resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *filename = [RCTConvert NSString:obj[@"filename"]];
  NSString *folder = [RCTConvert NSString:obj[@"folder"]];
  NSNumber *messageId = [RCTConvert NSNumber:obj[@"messageId"]];
  unsigned long long valueUInt64 = messageId.unsignedLongLongValue;
  MCOIndexSet *uid = [MCOIndexSet indexSetWithIndex:valueUInt64];
  MCOIMAPMessagesRequestKind requestKind = MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure | MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject | MCOIMAPMessagesRequestKindFlags;
  MCOIMAPFetchMessagesOperation *fetchOperation = [_imapObject fetchMessagesOperationWithFolder:folder requestKind:requestKind uids:uid];
  [fetchOperation start:^(NSError * error, NSArray * fetchedMessages, MCOIndexSet * vanishedMessages) {
      if(error) {
          reject(@"Error", error.localizedDescription, error);
      } else {
          MCOIMAPMessage *message = [fetchedMessages objectAtIndex:0];
          MCOIMAPFetchContentOperation *op = [_imapObject fetchMessageOperationWithFolder:folder uid:message.uid];
          [op start:^(NSError * error, NSData * data) {
              if(error || !data) {
                  reject(@"Error", error.localizedDescription, error);
              }
              
              if ([message.attachments count] > 0)
              {
                  for (int k = 0; k < [message.attachments count]; k++) {
                      MCOIMAPPart *part = [message.attachments objectAtIndex:k];
                      if([part.filename isEqualToString:filename]) {
                          NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                          NSString *saveDirectory = [paths objectAtIndex:0];
                          NSString *attachmentPath = [saveDirectory stringByAppendingPathComponent:part.filename];
                          BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:attachmentPath];
                          NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
                          [result setValue:attachmentPath forKey:@"url"];
                          if (fileExists) {
                            [result setObject:@"FILE EXIST!" forKey:@"status"];
                          }
                          else{
                              [result setObject:@"FILE SAVE WITH SUCCESS!" forKey:@"status"];
                              [data writeToFile:attachmentPath atomically:YES];
                          }
                         resolve(result);
                      } 
                       
                  }
              } else {
                 NSDictionary *result = @{@"status": @"SUCCESS"};
                resolve(result);
              }
          }];
      }
  }];
}


- (instancetype)initSmtp:(MCOSMTPSession *)smtpObject {
    self = [super init];
    if (self) {
        _smtpObject = smtpObject;
    }
    return self;
}


- (MCOSMTPSession *)getSmtpObject {
        return _smtpObject;
    }

- (instancetype)initImap:(MCOIMAPSession *)imapObject {
    self = [super init];
    if (self) {
        _imapObject = imapObject;
    }
    return self;
}

- (MCOIMAPSession *)getImapObject {
        return _imapObject;
    }

@end
