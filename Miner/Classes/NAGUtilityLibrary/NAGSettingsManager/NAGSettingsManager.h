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


static NSString *const kBGSettingManagerUserDefaultsStoreKeyForMainSettings = @"kBGSettingsManagerUserDefaultsStoreKeyForMainSettings";
static NSString *const kBGSettingManagerUserDefaultsStoreKeyForDefaultSettings = @"kBGSettingsManagerUserDefaultsStoreKeyForDefaultSettings";


// Class allows to work with app settings in a simple and flexible way.
@interface NAGSettingsManager : NSObject

// Delimiters for setting paths. Defaults to "." (dot) character.
@property (nonatomic, readwrite, strong) NSCharacterSet *pathDelimiters;
// Boolean value which specifies if exception should be thrown if settings path
// doesn't exist or they are incorrect. Defaults to YES.
@property (nonatomic, readwrite, assign) BOOL throwExceptionForUnknownPath;

+ (instancetype)shared;

// creates default settings which are not used as main settings until
// resetToDefaultSettings method is called
// example: [[NAGSettingsManager shared] createDefaultSettingsFromDictionary:@{@"user":@{@"login":@"Andrew", @"password":@"1234"}}]
- (void)createDefaultSettingsFromDictionary:(NSDictionary *)settings;

// resets main settings to default settings
- (void)resetToDefaultSettings;

// resets main settings to default settings if none exist in NSUserDefaults
- (void)resetToDefaultSettingsIfNoneExists;

// clears/removes all settings - main and default
- (void)clear;

// adding new setting value for settingPath
// example: [... setValue:@YES forSettingsPath:@"user.personalInfo.married"];
- (void)setValue:(id)value forSettingsPath:(NSString *)settingPath;

// return setting value with specified type
- (id)valueForSettingsPath:(NSString *)settingsPath;

- (BOOL)boolValueForSettingsPath:(NSString *)settingsPath;

- (NSInteger)integerValueForSettingsPath:(NSString *)settingsPath;

- (NSUInteger)unsignedIntegerValueForSettingsPath:(NSString *)settingsPath;

- (CGFloat)floatValueForSettingsPath:(NSString *)settingsPath;

- (NSString *)stringValueForSettingsPath:(NSString *)settingsPath;

- (NSArray *)arrayValueForSettingsPath:(NSString *)settingsPath;

- (NSDictionary *)dictionaryValueForSettingsPath:(NSString *)settingsPath;

- (NSData *)dataValueForSettingsPath:(NSString *)settingsPath;

@end