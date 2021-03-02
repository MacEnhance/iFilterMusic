//
//  AppDelegate.m
//  iFilterMusic
//
//  Created by Wolfgang Baird on 2/27/21.
//

#import "AXUI/AXUIElementWrapper.h"
#import "AppDelegate.h"
#import <Carbon/Carbon.h>

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@end

NSString                *selectedCellName;
NSRunningApplication    *runningApp;
AXUIElementWrapper      *applicationWrapper = nil;
AXUIElementWrapper      *sidebar = nil;

AXUIElementWrapper* itemInTree(AXUIElementWrapper* root, NSArray* nodes) {
    AXUIElementWrapper *result = root;
    for (NSNumber *index in nodes) {
        NSArray *kids = result.children;
        if (kids.count > index.intValue) {
            result = result.children[index.intValue];
        } else {
            return root;
        }
    }
    return result;
}

AXUIElementWrapper* fetchItem(NSArray* path) {
    
    // Result nil if nothing is found
    AXUIElementWrapper *result = nil;
    
    int loops = 0;
    // Look for an item up to 20 times with 0.05 waits between each loop (1 second total)
    while (result == nil && loops < 40) {
        // Increase loop counter
        loops++;
        
        // Attempt to get item
        result = itemInTree(applicationWrapper, path);
        
        // Wait if nothing found
        if (result == nil)
            [NSThread sleepForTimeInterval: 0.025];
    }
    
    if (result == applicationWrapper)
        return nil;
    
    return result;
}

void pushTheButton(AXUIElementRef element) {
    NSArray *kids;
    AXUIElementWrapper *item;
    
    // Get the title of the cell of the selected item in the sidebar name
    item = [AXUIElementWrapper wrapperWithUIElement:element];
    kids = [item attributeValue:@"AXSelectedCells"];
    item = [AXUIElementWrapper wrapperWithUIElement:(__bridge AXUIElementRef)(kids.firstObject)];
    kids = [item attributeValue:@"AXChildren"];
    item = [AXUIElementWrapper wrapperWithUIElement:(__bridge AXUIElementRef)(kids.lastObject)];
    
    id cellName = [item attributeValue:@"AXValue"];
    if (cellName) {
        if (selectedCellName != cellName) {
            selectedCellName = cellName;
            //    NSLog(@"%@", [item attributeValue:@"AXValue"]);
            //    NSLog(@"%@", item.attributeNames);
            
            AXUIElementWrapper *menu = fetchItem(@[@1, @5, @0]);
            kids = [menu attributeValue:@"AXChildren"];
            AXUIElementWrapper *menuItem;
            for (id item in kids) {
                menuItem = [AXUIElementWrapper wrapperWithUIElement:(__bridge AXUIElementRef)(item)];
                NSString *cmd = [menuItem attributeValue:@"AXMenuItemCmdChar"];
                int mod = [[menuItem attributeValue:@"AXMenuItemCmdModifiers"] intValue];
                if (cmd && mod) {
                    if ([cmd isEqualToString:@"F"] && mod == 2) {
                        AXUIElementPerformAction(menuItem.UIElement, kAXPressAction);
                    }
                }
                
                //        NSLog(@"%@ : %@ : %@", [menuItem attributeValue:@"AXTitle"], [menuItem attributeValue:@"AXMenuItemCmdChar"], [menuItem attributeValue:@"AXMenuItemCmdModifiers"]);
            }
        }
    }
}

// The AXUIElementRef element we recieve is the sidebar
void musicSidebarObserver(AXObserverRef observer, AXUIElementRef element, CFStringRef notificationName, void * contextData) {
    // Toggle the filter field visible
    pushTheButton(element);
}

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [self addObserverToMusic];
    [self watchForNewMusicProcess];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)getwrappers {
    NSArray *kids, *xtra;
    AXUIElementWrapper *item;
    selectedCellName = @"";
    
    // Wrapper for app -- kids -- 0 window 1 menubar
    applicationWrapper = [AXUIElementWrapper wrapperForApplication:runningApp.processIdentifier];
    kids = [applicationWrapper attributeValue:@"AXChildren"];
    
    // Wrapper for main window -- kids -- 0 AXObjectBridge 1 close 2 fullscreen 3 minimize
    item = [AXUIElementWrapper wrapperWithUIElement:(__bridge AXUIElementRef)(kids.firstObject)];
    kids = [item attributeValue:@"AXChildren"];
    
    // Wrapper for AXObjectBridge -- AXSplitters -- 0 ITDRawingHostView
    item = [AXUIElementWrapper wrapperWithUIElement:(__bridge AXUIElementRef)(kids.firstObject)];
    xtra = [item attributeValue:@"AXSplitters"];
    
    // Wrapper for ITDRawingHostView -- AXPreviousContents -- 0 Scroll View
    item = [AXUIElementWrapper wrapperWithUIElement:(__bridge AXUIElementRef)(xtra.firstObject)];
    xtra = [item attributeValue:@"AXPreviousContents"];
    
    // Wrapper for Sidebar
    sidebar = [AXUIElementWrapper wrapperWithUIElement:(__bridge AXUIElementRef)(xtra.firstObject)];
}

// Watch the Dock for selection changes
- (void)addObserverToMusic {
    runningApp = [[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.Music"] lastObject];
    AXObserverRef observer;
    AXObserverCreate(runningApp.processIdentifier, musicSidebarObserver, &observer);
    [self getwrappers];
    pushTheButton(sidebar.UIElement);
    AXObserverAddNotification(observer, sidebar.UIElement, kAXSelectedRowsChangedNotification, (__bridge void * _Nullable)(self));
    CFRunLoopAddSource( [[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode );
}

- (void)watchForNewMusicProcess {
    static EventHandlerRef sCarbonEventsRef = NULL;
    static const EventTypeSpec kEvents[] = {
        { kEventClassApplication, kEventAppLaunched },
        { kEventClassApplication, kEventAppTerminated },
    };
    if (sCarbonEventsRef == NULL)
        (void) InstallEventHandler(GetApplicationEventTarget(), (EventHandlerUPP)CarbonEventHandler, GetEventTypeCount(kEvents), kEvents, (__bridge void *)(self), &sCarbonEventsRef);
}

static OSStatus CarbonEventHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void* inUserData) {
    pid_t pid;
    (void) GetEventParameter(inEvent, kEventParamProcessID, typeKernelProcessID, NULL, sizeof(pid), NULL, &pid);
    switch ( GetEventKind(inEvent) ) {
        case kEventAppLaunched:
            // Music app lauched
            if ([[NSRunningApplication runningApplicationWithProcessIdentifier:pid].bundleIdentifier isEqualToString:@"com.apple.Music"]) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [NSApp.delegate performSelector:@selector(addObserverToMusic)];
                });
            }
            break;
        case kEventAppTerminated:
            // App terminated!
            break;
        default:
            assert(false);
    }
    return noErr;
}

@end


