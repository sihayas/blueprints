Design is not just what it looks like and feels like. Design is how it **works**.  

---

I think it may be wiser for iOS engineers to focus more on the "flow" of how you use  
an app, rather than simpler things like typography and layout. Many of these  
prototypes explore what I personally consider to be design engineering, which is  
less about how things "look", and more about how they function.  

As general guidelines, slide transitions should not exist as screens are too wide  
now. Animations and screen space transitions should only occur along the Y or  
Z-axes. Text should be big and bold. Titlebar's and footers should not exist, as  
clipping content so abruptly feels distasteful to the rounded edges of the screen.

Visual abstraction, in the form of navigation hierarchy for example, introduces  
complexity not only for the user but for us as well. Ever written a navigation  
router? As a designer/engineer, ask yourself why do you need to push the user into  
an entirely new screen state to simply express a few words, or showcase a new view  
or piece of content.  

Why do you think it justifiable then, to write the code and subsequent viewmodel's  
to maintain that screen state and wire it into the flow across your application.  

It's not that I believe navigation should disappear entirely, but that navigation  
as is, is excessive, and the less of it there is, the better both for the user  
and developer.

## iOS 18 Photos
<video src="https://github.com/user-attachments/assets/f53e7b3f-450f-4742-a950-6734b23ea654" controls="controls"></video>

Internally known as "LemonadeView", this was Apple’s first attempt at removing the  
idea of traditional tabs. Built using UIKit and SwiftUI, it relies on nested  
ScrollViews, something Apple’s HIG usually discourages.

- Allow smooth scrolling into a nested ScrollView from an outer ScrollView while  
  retaining inertia and gesture recognition.  
- Allow users to abort or scroll out of the inner ScrollView without jank.  
- Coordinate locking and unlocking scroll offset's based on a single gesture.  
- & Many other edge cases.

This was possibly the most difficult thing to build and at the same time the most  
compelling. By crafting a clever way for scrolling to go infinitely in either  
direction while still having designated break points via bounce, you get the "feel"  
of segmentation within an app, without the abrupt context switching of traditional  
tabs.

I also see a place for this type of interface as the perfect foundation for a more  
idealistic chat interface. Sidebar's feel archaic and antithetical to the primary  
goal of a chatbot, which is to make the user feel as if they are having a long  
standing conversation with something intelligent.  

When you have a conversation with a person, you are never "opening a new tab" when  
you want to shift the topic to something else. Ideas naturally ebb and flow as the  
conversation evolves. Context switching is natural when going human <->  
human, and should feel as such going human <-> machine. You can imagine an
effortless gesture dragging down to reveal past conversations rendered as custom
views.

The challenge of knowing when to "refresh" context should be handled by the model  
itself in most cases.

---

## Vertical Threads
<video src="https://github.com/user-attachments/assets/55fd1e53-b775-4b32-9378-d0432762735d" controls="controls"></video>

Rethinks the side-to-side navigation of apps like Twitter or Threads. Tapping a  
thread animates it vertically into view, sliding up or down like a drawer, and  
threads can be stacked and restored interactively.

- SwiftUI handles state and transitions using MatchedGeometryEffect and  
  ObservableObject.  
- UIKit manages heavy view rendering for better performance.

---

## Imprint
<video src="https://github.com/user-attachments/assets/b6016891-e25b-4de7-816e-29982c7f0ee2" controls="controls"></video>

An interaction model that lets users "leave their mark" on a track or album.  
Each swipe direction produces a different keyframe animation synced with Metal  
shaders.

- Swipe left: "Heartbreak" animation with ripple shader (via Janum Trivedi’s  
  Wave package).  
- Swipe right: "Heartbeat" animation with dynamic keyframes.

Includes a retargeting method and custom Metal ripple effect inspired by WWDC’s  
Metal Shader demo.

---

## Holographic Sticker
<video src="https://github.com/user-attachments/assets/81218c28-edca-458b-925f-16868139aa3b" controls="controls"></video>

A Metal-driven holographic sticker effect. Uses the Vision API to:

- Trace image contours and draw white strokes around them.  
- Extract contour data directly for dynamic edge highlighting.

Explores how Metal shaders can drive realistic, depth-rich animations instead of  
simple gradient tricks.

---

## Liquid Blur
<video src="https://github.com/user-attachments/assets/61cb9e03-f720-477f-b64d-16a305bc3d2e" controls="controls"></video>

A liquid, morphing interface inspired by the Dynamic Island, created before Apple’s  
own "Liquid Glass". Built entirely in SwiftUI using the Canvas API (not Metal).  

Acts as a tab bar replacement, with fluid, glass-like animations resembling  
Apple’s later LiquidGlass in SwiftUI.

---

## Tilting Card Deck
<video src="https://github.com/user-attachments/assets/842dcff1-09a9-42c4-a1f9-4b7160d842b2" controls="controls"></video>

A card deck paging view with subtle tilt and rotation effects. Designed to fix  
clipping artifacts common in stacked card interfaces.  

Smooth transitions and dynamic depth achieved through custom geometry and  
animation timing.

---

## Metro Flip
<video src="https://github.com/user-attachments/assets/9b1da07a-4770-4cc2-8de7-0707618d7049" controls="controls"></video>

Attempt at recreating MetroUI's beautiful Turnstile animation/transition in 
SwiftUI/UIKit.

The key trick to the effect is how Microsoft designers approached making the
cells appear as if they were flipping inside singular 3D space, without actually
needing to render a 3D view. Each cell's leading-center edge is anchored to the 
leading edge of the container screen, not anchored to itself. Without this, you
get an effect where the cells appear to flip out towards the screen in a very
jarring POV perspective, rather than appearing as if they are flipping within 
a singular space.

There is also a variability to the stagger as each cell flips out of view one by
one, to give some naturalism to the effect. I tried my best to get it to feel
as 1:1 as possible but I am still mising finer grained values. I do believe this
interface was far ahead of it's time, especially in terms of simplicity.

Ref:
https://matthiasshapiro.com/basic-windows-phone-7-motion-design/

---

## Native Auxiliary
<video src="https://github.com/user-attachments/assets/46b641c1-ff7f-4d5b-b50e-1e1fb829a2a1" controls="controls"></video>

attaches an AuxiliaryView to a UIContextMenu, the main code responsible for  
attaching the view is thanks to DominicGo - surprisingly it doesn't use any  
private api's

the slightly annoying part was hooking into the native context menu gesture to  
allow a user to be able to simply hold and drag without lifting a finger to select  
something. keeps the natural friction spring physics intact without needing to  
manually add another gesture on top

---

## Iridescence
<video src="https://github.com/user-attachments/assets/36ffb127-d5f9-40e6-8987-232eb241165d" controls="controls"></video>

Recreates the iridescent shimmer seen in bird feathers, a port of KhronosGroup’s  
physical model. Implemented in Metal and rendered with SceneKit on a 3D ellipsoid.

Originally designed as a profile card (inspired by Artifact’s medallion UI).  
Supports engraving of text or shapes via CoreImage filters and Objective-C headers.

---

## Circlify
<video src="https://github.com/user-attachments/assets/1ab121db-911c-4034-88e8-217b3ec94db8" controls="controls"></video>

Swift port of the Python circlify library. Generates Apollonian circle packings  
algorithmically for layout or data visualization.

---

## ARCHIVE
Random sketches...

<video src="https://github.com/user-attachments/assets/453afe81-e36e-4a26-96c3-dd397cff7ef1" controls="controls"></video>
<video src="https://github.com/user-attachments/assets/c75eef8c-fa09-41bb-baf4-f15f1b10eb89" controls="controls"></video>
<video src="https://github.com/user-attachments/assets/06a2021b-b996-4479-ae3f-9a188ea63cba" controls="controls"></video>
