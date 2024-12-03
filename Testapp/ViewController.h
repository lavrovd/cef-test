#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSSlider *timelineSlider;
@property (weak) IBOutlet NSButton *playPauseButton;
@property (weak) IBOutlet NSTextField *frameRateField;
@property (weak) IBOutlet NSTextField *totalFramesField;
@property (weak) IBOutlet NSTextField *currentFrameLabel;
@property (weak) IBOutlet NSPopUpButton *frameRatePresets;

@end
