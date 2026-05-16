//
//  WatchCompassView.swift
//  Navee Watch App
//
//  Created by neena on 16/05/26.
//

import SwiftUI
import CoreLocation

// MARK: - WatchCompassView

struct WatchCompassView: View {
    let nav: NavState

    var body: some View {
        GeometryReader { geo in
            let size   = min(geo.size.width, geo.size.height)
            let radius = size / 2

            ZStack {
                WatchDirectionCone(isOnTrack: nav.isOnTrack, radius: radius)

                WatchCompassDial(
                    userHeading: nav.userHeading,
                    isOnTrack:   nav.isOnTrack,
                    radius:      radius
                )
                .frame(width: size, height: size)

                WatchDestinationDot(nav: nav, radius: radius * 0.72)
                    .rotationEffect(.degrees(-nav.userHeading))

                WatchNorthPointer(radius: radius)

                WatchUserDot()
            }
            .frame(width: size, height: size)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - WatchCompassDial

private struct WatchCompassDial: View {
    let userHeading: Double
    let isOnTrack: Bool
    let radius: CGFloat

    private let cardinals: [(text: String, deg: Double)] = [
        ("N", 0), ("E", 90), ("S", 180), ("W", 270)
    ]

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width  / 2
            let cy = size.height / 2
            let R  = min(cx, cy)

            // Outer ring
            let ring = Path(ellipseIn: CGRect(
                x: cx - R, y: cy - R, width: R * 2, height: R * 2
            ))
            ctx.stroke(ring, with: .color(.white.opacity(0.2)), lineWidth: 1.5)

            for deg in stride(from: 0.0, to: 360.0, by: 5.0) {
                let isMajor = deg.truncatingRemainder(dividingBy: 90) == 0
                let isMinor = deg.truncatingRemainder(dividingBy: 45) == 0 && !isMajor

                let outer: CGFloat = R - 1
                // ← tick diperpendek
                let inner: CGFloat = isMajor ? R - 14 : isMinor ? R - 10 : R - 6

                let rad  = (deg - userHeading - 90) * .pi / 180
                let cosV = CGFloat(Foundation.cos(rad))
                let sinV = CGFloat(Foundation.sin(rad))

                var tick = Path()
                tick.move(to:    CGPoint(x: cx + outer * cosV, y: cy + outer * sinV))
                tick.addLine(to: CGPoint(x: cx + inner * cosV, y: cy + inner * sinV))

                let width: CGFloat  = isMajor ? 3   : isMinor ? 2   : 1.5
                let opacity: Double = isMajor ? 1.0 : isMinor ? 0.7 : 0.4
                let color: Color    = (deg == 0 && isOnTrack)
                    ? Color(red: 0, green: 1, blue: 0.45)
                    : .white

                ctx.stroke(
                    tick,
                    with: .color(color.opacity(opacity)),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
            }
        }
        .overlay(
            ZStack {
                ForEach(cardinals, id: \.deg) { item in
                    let rad  = (item.deg - userHeading) * .pi / 180
                    let dist = radius - 26
                    Text(item.text)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(
                            item.deg == 0
                                ? (isOnTrack
                                    ? Color(red: 0.2, green: 1, blue: 0.5)
                                    : .white)
                                : .white.opacity(0.65)
                        )
                        .offset(
                            x:  CGFloat(sin(rad)) * dist,
                            y: -CGFloat(cos(rad)) * dist
                        )
                }
            }
        )
    }
}

// MARK: - WatchDirectionCone

private struct WatchDirectionCone: View {
    let isOnTrack: Bool
    let radius: CGFloat

    var body: some View {
        WatchConeSector(halfAngle: 28)
            .fill(
                RadialGradient(
                    colors: [
                        isOnTrack
                            ? Color(red: 0.0, green: 1.0, blue: 0.45).opacity(0.5)
                            : Color.white.opacity(0.12),
                        .clear
                    ],
                    center:      UnitPoint(x: 0.5, y: 1.0),
                    startRadius: 0,
                    endRadius:   radius * 2
                )
            )
            .frame(width: radius * 2, height: radius * 2)
            .animation(.easeInOut(duration: 0.3), value: isOnTrack)
    }
}

private struct WatchConeSector: Shape {
    let halfAngle: Double
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: center)
        p.addArc(
            center:     center,
            radius:     r,
            startAngle: .degrees(-90 - halfAngle),
            endAngle:   .degrees(-90 + halfAngle),
            clockwise:  false
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - WatchDestinationDot

private struct WatchDestinationDot: View {
    let nav: NavState
    let radius: CGFloat

    private var offset: CGSize {
        let rad   = nav.bearing * .pi / 180
        let ratio = CGFloat(min(nav.distance, Nav.pinMaxDistance) / Nav.pinMaxDistance)
        let minR  = radius * Nav.pinMinRatio
        let r     = minR + ratio * (radius - minR)
        return CGSize(
            width:  CGFloat(sin(rad)) * r,
            height: -CGFloat(cos(rad)) * r
        )
    }

    var body: some View {
        Group {
            if nav.isOnTrack || nav.hasArrived {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.35))
                        .frame(width: 22, height: 22)
                    Circle()
                        .fill(Color(red: 0.35, green: 0.95, blue: 0.55))
                        .frame(width: 12, height: 12)
                }
            } else {
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 10, height: 10)
            }
        }
        .offset(offset)
    }
}

// MARK: - WatchNorthPointer

private struct WatchNorthPointer: View {
    let radius: CGFloat
    var body: some View {
        NorthTriangle()
            .fill(Color.red)
            .frame(width: 8, height: 13)
            .offset(y: -(radius - 4))
    }
}

private struct NorthTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to:    CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - WatchUserDot

private struct WatchUserDot: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.12)).frame(width: 20, height: 20)
            Circle().fill(Color.white).frame(width: 12, height: 12)
            Circle().fill(Color.blue).frame(width:  7, height:  7)
        }
    }
}
