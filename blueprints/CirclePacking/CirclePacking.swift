//
//  PackedCircle.swift
//  acusia
//
//  Created by decoherence on 1/5/25.
//

import Foundation
import SwiftUI

// MARK: - PackedCircle Data Structure

struct PackedCircle: Equatable {
    var x: Double
    var y: Double
    var r: Double
}

// MARK: - Utility

func distance(_ c1: PackedCircle, _ c2: PackedCircle) -> Double {
    let dx = c2.x - c1.x
    let dy = c2.y - c1.y
    return sqrt(dx*dx + dy*dy) - c1.r - c2.r
}

func getIntersections(_ c1: PackedCircle, _ c2: PackedCircle) -> (CGPoint?, CGPoint?) {
    let dx = c2.x - c1.x
    let dy = c2.y - c1.y
    let d = sqrt(dx*dx + dy*dy)
    // If circles are coincident or there's no valid intersection, bail.
    guard d > 1e-12 else { return (nil, nil) }

    let a = (c1.r*c1.r - c2.r*c2.r + d*d) / (2*d)
    let rr = c1.r*c1.r - a*a
    guard rr >= 0 else { return (nil, nil) }

    let h = sqrt(rr)
    let xm = c1.x + (a*dx / d)
    let ym = c1.y + (a*dy / d)
    let rx = -(dy*(h / d))
    let ry = (dx*(h / d))

    let p1 = CGPoint(x: xm + rx, y: ym + ry)
    let p2 = CGPoint(x: xm - rx, y: ym - ry)
    if p1 == p2 { return (p1, nil) }
    return (p1, p2)
}

// MARK: - Placement

func getPlacementCandidates(radius: Double,
                            c1: PackedCircle,
                            c2: PackedCircle) -> [PackedCircle]
{
    // Extra small margin
    let margin = radius*Double.ulpOfOne*10.0
    let ic1 = PackedCircle(x: c1.x, y: c1.y, r: c1.r + radius + margin)
    let ic2 = PackedCircle(x: c2.x, y: c2.y, r: c2.r + radius + margin)
    let (p1, p2) = getIntersections(ic1, ic2)
    var candidates: [PackedCircle] = []
    if let p1 = p1 {
        candidates.append(PackedCircle(x: p1.x, y: p1.y, r: radius))
    }
    if let p2 = p2 {
        candidates.append(PackedCircle(x: p2.x, y: p2.y, r: radius))
    }
    return candidates
}

// MARK: - Hole Degree Functions

func holeDegreeRadiusWeighted(_ candidate: PackedCircle,
                              _ circles: [PackedCircle]) -> Double
{
    circles.reduce(0.0) { $0 + distance(candidate, $1)*$1.r }
}

// MARK: - A1.0 PackedCircle Packing

// Optimized to avoid building 'otherPackedCircles' on each pass
func placeNewPackedCircleA1_0(radius: Double,
                              placed: [PackedCircle]) -> PackedCircle
{
    switch placed.count {
    case 0:
        return PackedCircle(x: radius, y: 0, r: radius)
    case 1:
        return PackedCircle(x: -radius, y: 0, r: radius)
    default:
        break
    }

    var bestHD: Double? = nil
    var bestCandidate: PackedCircle? = nil

    for i in 0..<(placed.count - 1) {
        for j in (i + 1)..<placed.count {
            let c1 = placed[i]
            let c2 = placed[j]
            for cand in getPlacementCandidates(radius: radius, c1: c1, c2: c2) {
                // Check overlap + compute hole degree in one pass
                var overlaps = false
                var hd = 0.0
                for k in 0..<placed.count {
                    // Skip the pair used for candidate
                    if k == i || k == j { continue }
                    let dist = distance(placed[k], cand)
                    if dist < 0.0 {
                        overlaps = true
                        break
                    }
                    hd += dist*placed[k].r
                }
                if overlaps { continue }

                if bestHD == nil || hd < bestHD! {
                    bestHD = hd
                    bestCandidate = cand
                }
            }
        }
    }
    guard let result = bestCandidate else {
        fatalError("Cannot place circle for radius \(radius)")
    }
    return result
}

func packA1_0(_ values: [Double]) -> [PackedCircle] {
    // Sort descending
    precondition(values == values.sorted(by: >), "Data must be sorted descending.")
    var placed: [PackedCircle] = []
    for v in values {
        let r = sqrt(v)
        let newPackedCircle = placeNewPackedCircleA1_0(radius: r, placed: placed)
        placed.append(newPackedCircle)
    }
    return placed
}

// MARK: - Enclose Helpers

func enclosesWeak(_ a: PackedCircle, _ b: PackedCircle) -> Bool {
    let dr = a.r - b.r + 1e-6
    let dx = b.x - a.x
    let dy = b.y - a.y
    return dr > 0 && (dr*dr > dx*dx + dy*dy)
}

func encloseBasis2(_ a: PackedCircle, _ b: PackedCircle) -> PackedCircle {
    let dx = b.x - a.x
    let dy = b.y - a.y
    let dr = b.r - a.r
    let d = sqrt(dx*dx + dy*dy)
    let cx = (a.x + b.x + (dx / d)*dr)*0.5
    let cy = (a.y + b.y + (dy / d)*dr)*0.5
    let cr = (d + a.r + b.r)*0.5
    return PackedCircle(x: cx, y: cy, r: cr)
}

func encloseBasis3(_ a: PackedCircle, _ b: PackedCircle, _ c: PackedCircle) -> PackedCircle {
    let (x1, y1, r1) = (a.x, a.y, a.r)
    let (x2, y2, r2) = (b.x, b.y, b.r)
    let (x3, y3, r3) = (c.x, c.y, c.r)
    let a2 = x1 - x2
    let a3 = x1 - x3
    let b2 = y1 - y2
    let b3 = y1 - y3
    let c2 = r2 - r1
    let c3 = r3 - r1
    let d1 = x1*x1 + y1*y1 - r1*r1
    let d2 = d1 - (x2*x2 + y2*y2 - r2*r2)
    let d3 = d1 - (x3*x3 + y3*y3 - r3*r3)
    let ab = a3*b2 - a2*b3
    let xa = (b2*d3 - b3*d2) / (ab*2) - x1
    let xb = (b3*c2 - b2*c3) / ab
    let ya = (a3*d2 - a2*d3) / (ab*2) - y1
    let yb = (a2*c3 - a3*c2) / ab
    let A = xb*xb + yb*yb - 1
    let B = 2*(r1 + xa*xb + ya*yb)
    let C = xa*xa + ya*ya - r1*r1
    let r: Double
    if abs(A) > Double.ulpOfOne {
        r = -(B + sqrt(B*B - 4*A*C)) / (2*A)
    } else {
        r = -C / B
    }
    return PackedCircle(x: x1 + xa + xb*r, y: y1 + ya + yb*r, r: r)
}

func encloseBasis(_ B: [PackedCircle]) -> PackedCircle {
    switch B.count {
    case 1: return B[0]
    case 2: return encloseBasis2(B[0], B[1])
    default: return encloseBasis3(B[0], B[1], B[2])
    }
}

func enclosesNot(_ a: PackedCircle, _ b: PackedCircle) -> Bool {
    let dr = a.r - b.r
    let dx = b.x - a.x
    let dy = b.y - a.y
    return dr < 0 || (dr*dr < dx*dx + dy*dy)
}

func enclosesWeakAll(_ a: PackedCircle, _ list: [PackedCircle]) -> Bool {
    for c in list {
        if !enclosesWeak(a, c) { return false }
    }
    return true
}

func extendBasis(_ B: [PackedCircle], _ p: PackedCircle) -> [PackedCircle] {
    if enclosesWeakAll(p, B) {
        return [p]
    }
    for b in B {
        if enclosesNot(p, b), enclosesWeakAll(encloseBasis2(b, p), B) {
            return [b, p]
        }
    }
    let n = B.count
    for i in 0..<(n - 1) {
        for j in (i + 1)..<n {
            let b1 = B[i]
            let b2 = B[j]
            let eb3 = encloseBasis3(b1, b2, p)
            if enclosesNot(encloseBasis2(b1, b2), p),
               enclosesNot(encloseBasis2(b1, p), b2),
               enclosesNot(encloseBasis2(b2, p), b1),
               enclosesWeakAll(eb3, B)
            {
                return [b1, b2, p]
            }
        }
    }
    fatalError("extendBasis: unexpected state")
}

func enclose(_ circles: [PackedCircle]) -> PackedCircle? {
    guard !circles.isEmpty else { return nil }
    var B: [PackedCircle] = []
    var e: PackedCircle?
    var i = 0
    while i < circles.count {
        let p = circles[i]
        if let enc = e, enclosesWeak(enc, p) {
            i += 1
        } else {
            B = extendBasis(B, p)
            e = encloseBasis(B)
            i = 0
        }
    }
    return e
}

// MARK: - Scaling & Circlify

func scale(_ circle: PackedCircle,
           into target: PackedCircle,
           enclosure: PackedCircle) -> PackedCircle
{
    let r = target.r / enclosure.r
    let x = (circle.x - enclosure.x)*r + target.x
    let y = (circle.y - enclosure.y)*r + target.y
    return PackedCircle(x: x, y: y, r: circle.r*r)
}

func circlify(_ data: [Double],
              targetEnclosure: PackedCircle = PackedCircle(x: 0, y: 0, r: 1),
              showEnclosure: Bool = false) -> [PackedCircle]
{
    // 1) Pack using A1.0
    let packed = packA1_0(data.sorted(by: >))
    guard let encl = enclose(packed) else { return [] }

    // 2) Scale to target enclosure
    var scaled: [PackedCircle] = []
    for c in packed {
        let sc = scale(c, into: targetEnclosure, enclosure: encl)
        scaled.append(sc)
    }

    // 3) Optionally add the big enclosure circle
    if showEnclosure {
        scaled.append(targetEnclosure)
    }
    return scaled
}

enum Operation: String, CaseIterable, Identifiable {
    case add = "Add"
    case remove = "Remove"
    var id: Self { self }
}

struct CirclifyPreviewView: View {
    let size: CGSize
    let values: [Double]
    let padding: CGFloat

    @State private var rotate = false

    var body: some View {
        let packed = circlify(values)

        ZStack {
            ForEach(packed.indices, id: \.self) { i in
                let c = packed[i]
                let scaleFactor = (size.width / 2)

                Circle()
                    .fill(.blue)
                    .padding(padding)
                    .frame(width: c.r*2*scaleFactor,
                           height: c.r*2*scaleFactor)
                    .offset(x: c.x*scaleFactor, y: c.y*scaleFactor)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(.clear, in: Circle())
        // .rotationEffect(.degrees(225))
    }
}

struct CirclifyDemoView: View {
    @State private var values: [Double] = [1.0]
    @State private var selectedOp: Operation? = nil

    var body: some View {
        VStack {
            CirclifyPreviewView(
                size: CGSize(width: 300, height: 300),
                values: values,
                padding: 2
            )
            .frame(width: 300, height: 300)
            .rotationEffect(.degrees(225))
            .animation(.bouncy(), value: values)
            .overlay(
                Circle()
                    .stroke(.blue.opacity(0.2), lineWidth: 1)
            )

            Picker("Operation", selection: $selectedOp) {
                ForEach(Operation.allCases) { op in
                    Text(op.rawValue)
                        .tag(op as Operation?)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .onChange(of: selectedOp) { op in
                guard let op = op else { return }
                withAnimation {
                    if op == .add {
                        let newValue = Double.random(in: 0.3 ... 1.0)
                        values.append(newValue)
                        values.sort(by: >)
                    } else if op == .remove {
                        if !values.isEmpty { values.removeLast() }
                    }
                }
                // Reset selection to allow repeated tapping.
                DispatchQueue.main.async { selectedOp = nil }
            }
        }
    }
}

struct CirclifyDemoView_Previews: PreviewProvider {
    static var previews: some View {
        CirclifyDemoView()
    }
}
