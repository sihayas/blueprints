# acusia / blueprints

This repository is a collection of **SwiftUI and Metal/SceneKit prototypes** exploring 
motion design, interactive UI concepts, and generative graphics.  
It isn’t a finished product or app, but a **playground of experiments** that mix 
SwiftUI, Core Motion, Core Image, and custom Metal shaders.

## Purpose

The goal of this repo is to **prototype new interaction patterns**:  
- Playful card decks with realistic shadows and 3D tilting.  
- Holographic previews driven by device motion and shader effects.  
- Packed circle layouts for generative UI geometry.  
- Symmetry-based "Dynamic Island" style capsules.  
- SceneKit + Metal experiments with iridescent 3D discs and live text labels.  

Each file is largely self-contained, showing a different idea or 
interaction technique that can be used as inspiration or building blocks 
for future apps.

## Contents

- **CustomCardDeckPageView.swift** – Tilting card deck page view style with 
  swipe gestures, scaling, rotation, and shadows.  
- **HoloPreview.swift** – A holographic card effect that responds to device 
  motion and drag gestures, layered with shader highlights.  
- **PackedCircle.swift** – Circle packing utility with geometry helpers and 
  a SwiftUI demo for visualizing layouts.  
- **DynamicIsland.swift** – Symmetry-based capsule animations for collapsed, 
  feed, and reply states.  
- **ImprintPreview.swift** – Animated morphing vectors, ripple effects, and 
  playful paging gestures.  
- **SoundScreen.swift** – A SceneKit + SwiftUI prototype that renders an 
  iridescent 3D disc with a Core Image–generated normal map and shader 
  parameter controls.

## Notes

- Some files rely on **custom Metal shaders** (`.metal` + `.metallib`).  
- External dependencies include **BigUIPaging** for paging gestures.  
- Components like `HoloShaderView`, `MKSymbolShape`, and 
  `HoloRotationManager` are custom helpers defined elsewhere in the project.  

---

This repo is meant as a **creative lab** for experimenting with how far 
you can push SwiftUI when combined with lower-level rendering frameworks.



https://github.com/user-attachments/assets/974789fe-3560-4923-a4d2-04fc68fa4cf1



