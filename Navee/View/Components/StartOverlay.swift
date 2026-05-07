//
//  StartOverlay.swift
//  Navee
//
//  Created by neena on 06/05/26.
//

import SwiftUI

struct StartOverlay: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image("welcomepage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image("island")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 24)

                Text("Drop a trail so you can always\nfind your way back.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Button(action: onStart) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Start Trekking")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(50)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    StartOverlay(onStart: {})
}
