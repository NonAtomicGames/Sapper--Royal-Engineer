//
// Copyright (C) 4/27/14  Andrew Shmig ( andrewshmig@yandex.ru )
// Non Atomic Games. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "NAGSettingsManager.h"


@implementation NAGSettingsManager
{
    NSMutableDictionary *_defaultSettings;
    NSMutableDictionary *_settings;
}

#pragma mark - Class methods

+ (instancetype)shared
{
    static dispatch_once_t once;
    static NAGSettingsManager *shared;

    dispatch_once(&once, ^{
        shared = [[self alloc] init];
        shared->_pathDelimiters = [NSCharacterSet characterSetWithCharactersInString:@"."];
        shared->_throwExceptionForUnknownPath = YES;

        [shared BGPrivateMethod_loadExistingSettings];
    });

    return shared;
}

#pragma mark - Instance methods

- (void)createDefaultSettingsFromDictionary:(NSDictionary *)settings
{
    _defaultSettings = [self BGPrivateMethod_deepMutableCopy:settings];

    [self BGPrivateMethod_saveSettings];
}

- (void)resetToDefaultSettings
{
    _settings = [_defaultSettings mutableCopy];

    [self BGPrivateMethod_saveSettings];
}

- (void)resetToDefaultSettingsIfNoneExists
{
    NSDictionary *settings = [[NSUserDefaults standardUserDefaults]
                                              valueForKey:kBGSettingManagerUserDefaultsStoreKeyForMainSettings];

    if (0 == [settings count]) {
        [self resetToDefaultSettings];
    }
}


- (void)clear
{
    _settings = [NSMutableDictionary new];
    _defaultSettings = [NSMutableDictionary new];

    [self BGPrivateMethod_saveSettings];
}


- (void)setValue:(id)value forSettingsPath:(NSString *)settingPath
{
    NSArray *settingsPathComponents = [settingPath componentsSeparatedByCharactersInSet:self
            .pathDelimiters];
    __block id currentNode = _settings;

    [settingsPathComponents enumerateObjectsUsingBlock:^(id pathComponent,
                                                         NSUInteger idx,
                                                         BOOL *stop)
            {

                id nextNode = currentNode[pathComponent];

                BOOL nextNodeIsNil = (nextNode == nil);
                BOOL nextNodeIsDictionary = [nextNode isKindOfClass:[NSMutableDictionary class]];
                BOOL lastPathComponent = (idx == [settingsPathComponents count] - 1);

                if ((nextNodeIsNil || !nextNodeIsDictionary) && !lastPathComponent) {

                    [currentNode setObject:[NSMutableDictionary new]
                                    forKey:pathComponent];
                } else if (idx == [settingsPathComponents count] - 1) {

                    if ([value isKindOfClass:[NSNumber class]])
                        currentNode[pathComponent] = [value copy];
                    else
                        currentNode[pathComponent] = [value mutableCopy];
                }

                currentNode = currentNode[pathComponent];
            }];

    [self BGPrivateMethod_saveSettings];
}

- (id)valueForSettingsPath:(NSString *)settingsPath
{
    NSArray *settingsPathComponents = [settingsPath componentsSeparatedByCharactersInSet:self
            .pathDelimiters];
    __block id currentNode = _settings;
    __block id valueForSettingsPath = nil;

    [settingsPathComponents enumerateObjectsUsingBlock:^(id obj,
                                                         NSUInteger idx,
                                                         BOOL *stop)
            {

//        we have a nil node for a path component which is not the last one
//        or a node which is not a leaf node
                if ((nil == currentNode && idx != [settingsPathComponents count]) ||
                        (currentNode != nil && ![currentNode isKindOfClass:[NSDictionary class]])) {

                    [self BGPrivateMethod_throwExceptionForInvalidSettingsPath];
                }

                NSString *key = obj;
                id nextNode = currentNode[key];

                if (nil == nextNode) {
                    *stop = YES;
                } else {
                    if (![nextNode isKindOfClass:[NSMutableDictionary class]])
                        valueForSettingsPath = nextNode;
                }

                currentNode = nextNode;
            }];

    return valueForSettingsPath;
}

- (BOOL)boolValueForSettingsPath:(NSString *)settingsPath
{
    return [[self valueForSettingsPath:settingsPath] boolValue];
}

- (NSInteger)integerValueForSettingsPath:(NSString *)settingsPath
{
    return [[self valueForSettingsPath:settingsPath] integerValue];
}

- (NSUInteger)unsignedIntegerValueForSettingsPath:(NSString *)settingsPath
{
    return (NSUInteger) [[self valueForSettingsPath:settingsPath] integerValue];
}

- (CGFloat)floatValueForSettingsPath:(NSString *)settingsPath
{
    return [[self valueForSettingsPath:settingsPath] floatValue];
}

- (NSString *)stringValueForSettingsPath:(NSString *)settingsPath
{
    return (NSString *) [self valueForSettingsPath:settingsPath];
}

- (NSArray *)arrayValueForSettingsPath:(NSString *)settingsPath
{
    return (NSArray *) [self valueForSettingsPath:settingsPath];
}

- (NSDictionary *)dictionaryValueForSettingsPath:(NSString *)settingsPath
{
    return (NSDictionary *) [self valueForSettingsPath:settingsPath];
}

- (NSData *)dataValueForSettingsPath:(NSString *)settingsPath
{
    return (NSData *) [self valueForSettingsPath:settingsPath];
}


- (NSString *)description
{
    return [_settings description];
}

#pragma mark - Private methods

- (void)BGPrivateMethod_saveSettings
{
    [[NSUserDefaults standardUserDefaults]
                     setValue:_settings
                       forKey:kBGSettingManagerUserDefaultsStoreKeyForMainSettings];
    [[NSUserDefaults standardUserDefaults]
                     setValue:_defaultSettings
                       forKey:kBGSettingManagerUserDefaultsStoreKeyForDefaultSettings];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)BGPrivateMethod_loadExistingSettings
{
    id settings = [[NSUserDefaults standardUserDefaults]
                                   valueForKey:kBGSettingManagerUserDefaultsStoreKeyForMainSettings];
    id defaultSettings = [[NSUserDefaults standardUserDefaults]
                                          valueForKey:kBGSettingManagerUserDefaultsStoreKeyForDefaultSettings];

    _settings = (settings ? settings : [NSMutableDictionary new]);
    _defaultSettings = (defaultSettings ? defaultSettings : [NSMutableDictionary new]);
}

- (NSMutableDictionary *)BGPrivateMethod_deepMutableCopy:(NSDictionary *)settings
{
    NSMutableDictionary *deepMutableCopy = [settings mutableCopy];

    [settings enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
            {
                if ([obj isKindOfClass:[NSDictionary class]])
                    deepMutableCopy[key] = [self BGPrivateMethod_deepMutableCopy:obj];
                else
                    deepMutableCopy[key] = obj;
            }];

    return deepMutableCopy;
}

- (void)BGPrivateMethod_throwExceptionForInvalidSettingsPath
{
    if (self.throwExceptionForUnknownPath)
        [NSException raise:@"Invalid settings path."
                    format:@"Some of your setting path components may intersect incorrectly or they don't exist."];
}

@end