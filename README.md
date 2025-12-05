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
[Watch demo](https://vimeo.com/1124109248)
![original](https://github.com/user-attachments/assets/f53e7b3f-450f-4742-a950-6734b23ea654)


Internally known as "LemonadeView", this was Apple’s first Photos interface without traditional tabs.  
Built using UIKit and SwiftUI, it relies on nested ScrollViews, something Apple’s HIG usually discourages.

The challenge:  
- Allow smooth scrolling into a nested ScrollView from an outer ScrollView while keeping inertia.  
- Allow users to abort or scroll out of the inner ScrollView without jank.  

Achieved using custom scroll logic instead of reverse-engineering Apple’s full scroll physics.

---

## Vertical Threads
[Watch demo](https://vimeo.com/1124109240)

Rethinks the side-to-side navigation of apps like Twitter or Threads.  
Tapping a thread animates it vertically into view, sliding up or down like a drawer, and threads can be stacked and restored interactively.

Hybrid architecture:  
- SwiftUI handles state and transitions using MatchedGeometryEffect and ObservableObject.  
- UIKit manages heavy view rendering for better performance.

---

## Imprint
[Watch demo](https://vimeo.com/1124109235)

An interaction model that lets users "leave their mark" on a track or album.  
Each swipe direction produces a different keyframe animation synced with Metal shaders.

- Swipe left: "Heartbreak" animation with ripple shader (via Janum Trivedi’s Wave package).  
- Swipe right: "Heartbeat" animation with dynamic keyframes.

Includes a retargeting method and custom Metal ripple effect inspired by WWDC’s Metal Shader demo.

---

## Iridescence
[Watch demo](https://vimeo.com/1124109227)

Recreates the iridescent shimmer seen in bird feathers, a port of KhronosGroup’s physical model.  
Implemented in Metal and rendered with SceneKit on a 3D ellipsoid.

Originally designed as a profile card (inspired by Artifact’s medallion UI).  
Supports engraving of text or shapes via CoreImage filters and Objective-C headers.

---

## Holographic Sticker
[Watch demo](https://vimeo.com/1124109223)

A Metal-driven holographic sticker effect.  
Uses the Vision API to:  
- Trace image contours and draw white strokes around them.  
- Extract contour data directly for dynamic edge highlighting.

Explores how Metal shaders can drive realistic, depth-rich animations instead of simple gradient tricks.

---

## Circlify
[Watch demo](https://vimeo.com/1124109218)

Swift port of the Python circlify library.  
Generates Apollonian circle packings algorithmically for layout or data visualization.

---

## Liquid Blur
[Watch demo](https://vimeo.com/1124109212)

A liquid, morphing interface inspired by the Dynamic Island, created before Apple’s own "Liquid Glass".  
Built entirely in SwiftUI using the Canvas API (not Metal).  

Acts as a tab bar replacement, with fluid, glass-like animations resembling Apple’s later LiquidGlass in SwiftUI.

---

## Tilting Card Deck
[Watch demo](https://vimeo.com/1124109206)

A card deck paging view with subtle tilt and rotation effects.  
Designed to fix clipping artifacts common in stacked card interfaces.  
Smooth transitions and dynamic depth achieved through custom geometry and animation timing.
