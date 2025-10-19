# Experimental iOS Interface Concepts

> **Requires iOS 26**  
> Simply run and play.

---

## Video Samples
https://vimeo.com/1124109248

---

## iOS 18 Photo’s View Architecture Reconstruction (UIKit + SwiftUI)

Internally designated as "LemonadeView" by Apple, the structure of the interface is entirely unique and compelling in that it was Apple's first attempt at removing the idea of a tab based interface within an App. Extremely complex to design and build, it involves nested ScrollViews, something Apple warns against in their HIG ironically. It has to check many boxes. A user needs to be able to abort scrolling up, or "into", the nested ScrollView, which given the delegate methods available in a UIKit ScrollView is difficult to accomplish without custom logic. A user needs to be able to smoothly scroll into the nested ScrollView, from the bottom, or "outer" ScrollView, while retaining inertia. You could reverse engineer Apple's scroll physics entirely, but it would be unnecessary and overtly complex.

https://vimeo.com/1124109240

---

## Vertical Threads

An attempt to remove the typical side-to-side slide transition in existing thread based applications like Twitter or Threads, tapping a thread smoothly translates it up into the top or bottom of the screen in a drawer like fashion, tucking it into obscurity. Threads can be stacked one after the other, and can be dragged back into their original state. Works in tandem across SwiftUI and UIKit for specific parts of the code to leverage each one's strengths. SwiftUI's ease of use with MatchedGeometry and Observable state, UIKit's performance advantages in hiding views from a screen to increase performance.

https://vimeo.com/1124109235

---

## Imprint

Interaction paradigm to allow a user to "leave their mark" on a piece of music that did the same for them. A user would have a binary choice between loving, and not-loving an album or a song. Swiping to the left would translate to a "heart-break" keyframe animation, in sync with a retargeting method provided by Janum Trivedi's Wave package, alongside a Metal shader Ripple effect inspired by the WWDC Keynote Talk on Metal Shaders in SwiftUI. Swiping right would translate to a Disney-esque heartbeat keyframe animation.

https://vimeo.com/1124109227

---

## Iridescence

A recreation of KhronosGroup's work on emulating iridescence as it is in reality, inspired by the shimmer effect that is similarly seen on birds, and ported into Metal onto a SceneKit 3D ellipsoid. Originally meant to serve as a user profile card, ala Artifact News App Medallion. The Ellipsoid has the ability to engrave any shape or text through custom CoreImage filters and Obj-C headers.

https://vimeo.com/1124109223

---

## Holographic Sticker

Metal driven, holographic sticker effect. Utilizes the Vision API to trace the contours of an image to draw a white stroke around the input image, whilst also being able to extract contours from an image using said API. An exploration into the range of Metal shaders and how they can be used to drive very visceral, real animations that are not linear-gradient translation tricks.

https://vimeo.com/1124109218

---

## Circlify

The Python circlify package essentially creates an Apollonian circle structure using an algorithmic approach. Ported to Swift.

https://vimeo.com/1124109212

---

## Liquid Blur

My own version of Liquid Glass before Liquid Glass was ever a thing. Inspired by the Dynamic Island, the idea was to create a morphing, liquid-esque interface that would serve as a replacement to the tab bar. The design of the view is purely in SwiftUI, and remarkably resembles Apple's own native implementation of LiquidGlass in SwiftUI. Except it opts for the CanvasAPI instead of Metal.

https://vimeo.com/1124109206

---

## Tilting Card Deck Paging View

A tilting card deck paging view. Adds a subtle tilt and rotation to prevent the clipping you usually see with these types of card stacks.

https://vimeo.com/1124109200