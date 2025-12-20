> Design is not just what it looks like and feels like. Design is how it **works**.   

---
Note, for views involving SwiftUI gestures, it's better to opt for UIKit gestures in most cases as you get more fine grained and responsive control, you can use UIGestureRecognizerRepresentable to bridge the gap to utilize UIKit gestures in SwiftUI. See this for example https://gist.github.com/sihayas/0fb2536efd3f731230d68c8d767d656f

## iOS 18 Photos View (LemonadeView)
<video src="https://github.com/user-attachments/assets/f53e7b3f-450f-4742-a950-6734b23ea654" controls="controls"></video>

Internally known as "LemonadeView", this was Apple’s first Photos interface without traditional tabs.  
Built using UIKit and SwiftUI, it relies on nested ScrollViews, something Apple’s HIG usually discourages.

The challenge:  
- Allow smooth scrolling into a nested ScrollView from an outer ScrollView while keeping inertia.  
- Allow users to abort or scroll out of the inner ScrollView without jank.  

Achieved using custom scroll logic instead of reverse-engineering Apple’s full scroll physics.

---

## Vertical Threads
<video src="https://github.com/user-attachments/assets/55fd1e53-b775-4b32-9378-d0432762735d" controls="controls"></video>

Rethinks the side-to-side navigation of apps like Twitter or Threads.  
Tapping a thread animates it vertically into view, sliding up or down like a drawer, and threads can be stacked and restored interactively.

Hybrid architecture:  
- SwiftUI handles state and transitions using MatchedGeometryEffect and ObservableObject.  
- UIKit manages heavy view rendering for better performance.

---

## Imprint
<video src="https://github.com/user-attachments/assets/b6016891-e25b-4de7-816e-29982c7f0ee2" controls="controls"></video>

An interaction model that lets users "leave their mark" on a track or album.  
Each swipe direction produces a different keyframe animation synced with Metal shaders.

- Swipe left: "Heartbreak" animation with ripple shader (via Janum Trivedi’s Wave package).  
- Swipe right: "Heartbeat" animation with dynamic keyframes.

Includes a retargeting method and custom Metal ripple effect inspired by WWDC’s Metal Shader demo.

---

## Iridescence
<video src="https://github.com/user-attachments/assets/36ffb127-d5f9-40e6-8987-232eb241165d" controls="controls"></video>

Recreates the iridescent shimmer seen in bird feathers, a port of KhronosGroup’s physical model.  
Implemented in Metal and rendered with SceneKit on a 3D ellipsoid.

Originally designed as a profile card (inspired by Artifact’s medallion UI).  
Supports engraving of text or shapes via CoreImage filters and Objective-C headers.

---

## Holographic Sticker
<video src="https://github.com/user-attachments/assets/81218c28-edca-458b-925f-16868139aa3b" controls="controls"></video>

A Metal-driven holographic sticker effect.  
Uses the Vision API to:  
- Trace image contours and draw white strokes around them.  
- Extract contour data directly for dynamic edge highlighting.

Explores how Metal shaders can drive realistic, depth-rich animations instead of simple gradient tricks.

---

## Circlify
<video src="https://github.com/user-attachments/assets/1ab121db-911c-4034-88e8-217b3ec94db8" controls="controls"></video>

Swift port of the Python circlify library.  
Generates Apollonian circle packings algorithmically for layout or data visualization.

---

## Liquid Blur
<video src="https://github.com/user-attachments/assets/61cb9e03-f720-477f-b64d-16a305bc3d2e" controls="controls"></video>

A liquid, morphing interface inspired by the Dynamic Island, created before Apple’s own "Liquid Glass".  
Built entirely in SwiftUI using the Canvas API (not Metal).  

Acts as a tab bar replacement, with fluid, glass-like animations resembling Apple’s later LiquidGlass in SwiftUI.

---

## Tilting Card Deck
<video src="https://github.com/user-attachments/assets/842dcff1-09a9-42c4-a1f9-4b7160d842b2" controls="controls"></video>


A card deck paging view with subtle tilt and rotation effects.  
Designed to fix clipping artifacts common in stacked card interfaces.  
Smooth transitions and dynamic depth achieved through custom geometry and animation timing.

---
## Native Auxiliary
<video src="https://github.com/user-attachments/assets/46b641c1-ff7f-4d5b-b50e-1e1fb829a2a1" controls="controls"></video>

attaches an AuxiliaryView to a UIContextMenu, the main code responsible for attaching the view is thanks to DominicGo - surprisingly it doesn't use any private api's
the slightly annoying part was hooking into the native context menu gesture to allow a user to be able to simply hold and drag without lifting a finger to select something. keeps the natural friction spring physics intact without needing to manually add another gesture on top

---
## ARCHIVE

Random sketches...


<video src="https://github.com/user-attachments/assets/453afe81-e36e-4a26-96c3-dd397cff7ef1" controls="controls"></video>

<video src="https://github.com/user-attachments/assets/c75eef8c-fa09-41bb-baf4-f15f1b10eb89" controls="controls"></video>

<video src="https://github.com/user-attachments/assets/06a2021b-b996-4479-ae3f-9a188ea63cba" controls="controls"></video>




