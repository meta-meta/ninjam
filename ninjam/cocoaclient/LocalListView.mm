#import "LocalListView.h"
#import "LocalListItem.h"

#include "../njclient.h"

extern NSLock *g_client_mutex;

extern NJClient *g_client;

@implementation LocalListView

- (id)initWithFrame:(NSRect)frameRect
{
  frameRect.size.width = 320;
	if ((self = [super initWithFrame:frameRect]) != nil) {
		// Add initialization code here
    addbutton=[[NSButton alloc] init];
    
      [addbutton setButtonType:NSMomentaryPushButton];
      [addbutton setBezelStyle:NSRoundedBezelStyle];
      [addbutton setTitle:@"Add Channel"];
      [addbutton setFrame:NSMakeRect(0,0,120,32)];
      
      [addbutton setTarget:self];
      [addbutton setAction:@selector(onAction:)];
      [self addSubview:addbutton];
    
	}
	return self;
}

- (BOOL)isOpaque
{
  return YES;
}



- (void)drawRect:(NSRect)rect
{  
  NSDrawWindowBackground(rect);
}

- (void)runVUMeters
{
  int x;
  for (x = 0; x < [[self subviews] count]; x ++)
  {
    NSView *p=[[self subviews] objectAtIndex:x];
    if ([p tag] >= 1024 && [p tag] < 1024+MAX_LOCAL_CHANNELS)
    {
      LocalListItem *pp=p;
      [pp runVUmeter];
    }
  }
}


- (void)onAction:(id)sender
{
  if (sender == addbutton)
  {
    int idx;
    [g_client_mutex lock];
    for (idx = 0; idx < MAX_LOCAL_CHANNELS && g_client->GetLocalChannelInfo(idx,NULL,NULL,NULL); idx++);
    if (idx < MAX_LOCAL_CHANNELS)
    {
      g_client->SetLocalChannelInfo(idx,"new channel",true,0,false,0,true,false);
//    g_client->SetLocalChannelMonitoring(idx,false,0.0f,false,0.0f,false,false,false,false);
      g_client->NotifyServerOfChannelChange();  
    }
    [g_client_mutex unlock];
    
    // we do this outside the mutex, because the item will need to lock the mutex itself
    if (idx < MAX_LOCAL_CHANNELS) [self newChannel:idx];
  }
}

- (void)newChannel:(int)index
{
  int svc=[[self subviews] count] - 1;
  LocalListItem *p = [[LocalListItem alloc] initWithCh:index atPos:svc];
  [self addSubview:p];
  NSRect r=[p frame];
  NSRect r2;

  NSRect r3=[addbutton frame];
  r3.origin.y = r.origin.y + r.size.height;
    
  r2.size.width = r.size.width+r.origin.x;
  r2.size.height = r3.size.height + r3.origin.y;
  r2.origin.x=0;
  r2.origin.y=0;
  [self setFrame:r2];
  
  [addbutton setFrame:r3];
  [addbutton setNeedsDisplay:YES];
  [p setNeedsDisplay:YES];

  [self setNeedsDisplay:YES];
  [self displayIfNeeded];
  [p displayIfNeeded];
  [addbutton displayIfNeeded];
  [p release];
}

- (void)removeChannel:(id)chan
{
  NSRect f=[chan frame];
  [chan removeFromSuperview];
  
  int x;
  for (x = 0; x < [[self subviews] count]; x ++)
  {
    NSView *p=[[self subviews] objectAtIndex:x];
    NSRect tf=[p frame];
    if (tf.origin.y >= f.origin.y)
    {
      tf.origin.y -= f.size.height;
      [p setFrame:tf];
      [p setNeedsDisplay:YES];
    }
  }
  [self setNeedsDisplay:YES];
  [self displayIfNeeded];
}

- (BOOL)isFlipped
{
return YES;
}
@end