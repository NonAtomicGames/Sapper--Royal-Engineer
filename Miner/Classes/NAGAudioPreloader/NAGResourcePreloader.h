//
//  NAGResourcePreloader.h
//  Miner
//
//  Created by AndrewShmig on 4/5/14.
//  Copyright (c) 2014 Bleeding Games. All rights reserved.
//
@import AVFoundation;


@interface NAGResourcePreloader : NSObject <AVAudioPlayerDelegate>

+ (instancetype)shared;

// предзагружает аудио файл и готовит его к проигрыванию
- (void)preloadAudioResource:(NSString *)name;

// возвращает аудиопроигрыватель для воспроизведения аудио файла с именем name и
// расширением type
// nil - если звуки отключены
- (AVAudioPlayer *)playerFromGameConfigForResource:(NSString *)name;

// возвращает аудиопроигрыватель для воспроизведения аудио файла с именем name и
// расширением type. Не зависит от настроек звука
- (AVAudioPlayer *)playerForResource:(NSString *)name;

@end
