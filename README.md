# Experimental iOS Interface Concepts  
> **Requires iOS 26**  
> Simply run and play.

---

## Native Auxiliary

![original_d5e79c79659cefdf73cb49261a367681](https://github.com/user-attachments/assets/689e82a2-0430-4902-b2b1-d179eda287cf)

attaches an AuxiliaryView to a UIContextMenu, the main code responsible for attaching the view is thanks to DominicGo - surprisingly it doesn't use any private api's
the slightly annoying part was hooking into the native context menu gesture to allow a user to be able to simply hold and drag without lifting a finger to select something. keeps the natural friction spring physics intact without needing to manually add another gesture on top

---

## iOS 18 Photos View (LemonadeView)
![original_f53e7b3f-450f-4742-a950-6734b23ea654](https://github.com/user-attachments/assets/f53e7b3f-450f-4742-a950-6734b23ea654)

Internally known as "LemonadeView", this was Apple’s first Photos interface without traditional tabs.  
Built using UIKit and SwiftUI, it relies on nested ScrollViews, something Apple’s HIG usually discourages.

The challenge:  
- Allow smooth scrolling into a nested ScrollView from an outer ScrollView while keeping inertia.  
- Allow users to abort or scroll out of the inner ScrollView without jank.  

Achieved using custom scroll logic instead of reverse-engineering Apple’s full scroll physics.

---

## Vertical Threads
![original](https://github.com/user-attachments/assets/55fd1e53-b775-4b32-9378-d0432762735d)

Rethinks the side-to-side navigation of apps like Twitter or Threads.  
Tapping a thread animates it vertically into view, sliding up or down like a drawer, and threads can be stacked and restored interactively.

Hybrid architecture:  
- SwiftUI handles state and transitions using MatchedGeometryEffect and ObservableObject.  
- UIKit manages heavy view rendering for better performance.

---

## Imprint
![original](https://github.com/user-attachments/assets/b6016891-e25b-4de7-816e-29982c7f0ee2)

An interaction model that lets users "leave their mark" on a track or album.  
Each swipe direction produces a different keyframe animation synced with Metal shaders.

- Swipe left: "Heartbreak" animation with ripple shader (via Janum Trivedi’s Wave package).  
- Swipe right: "Heartbeat" animation with dynamic keyframes.

Includes a retargeting method and custom Metal ripple effect inspired by WWDC’s Metal Shader demo.

---

## Iridescence
![original](https://github.com/user-attachments/assets/36ffb127-d5f9-40e6-8987-232eb241165d)

Recreates the iridescent shimmer seen in bird feathers, a port of KhronosGroup’s physical model.  
Implemented in Metal and rendered with SceneKit on a 3D ellipsoid.

Originally designed as a profile card (inspired by Artifact’s medallion UI).  
Supports engraving of text or shapes via CoreImage filters and Objective-C headers.

---

## Holographic Sticker
![original](https://github.com/user-attachments/assets/81218c28-edca-458b-925f-16868139aa3b)

A Metal-driven holographic sticker effect.  
Uses the Vision API to:  
- Trace image contours and draw white strokes around them.  
- Extract contour data directly for dynamic edge highlighting.

Explores how Metal shaders can drive realistic, depth-rich animations instead of simple gradient tricks.

---

## Circlify
![original]()
<video src='https://github.com/user-attachments/assets/1ab121db-911c-4034-88e8-217b3ec94db8'/>
Swift port of the Python circlify library.  
Generates Apollonian circle packings algorithmically for layout or data visualization.

---

## Liquid Blur
![original](https://github.com/user-attachments/assets/61cb9e03-f720-477f-b64d-16a305bc3d2e)

A liquid, morphing interface inspired by the Dynamic Island, created before Apple’s own "Liquid Glass".  
Built entirely in SwiftUI using the Canvas API (not Metal).  

Acts as a tab bar replacement, with fluid, glass-like animations resembling Apple’s later LiquidGlass in SwiftUI.

---

## Tilting Card Deck
![original](https://github.com/user-attachments/assets/842dcff1-09a9-42c4-a1f9-4b7160d842b2)

A card deck paging view with subtle tilt and rotation effects.  
Designed to fix clipping artifacts common in stacked card interfaces.  
Smooth transitions and dynamic depth achieved through custom geometry and animation timing.

---

## ARCHIVE

Random sketches that never saw the light of day...








