//
//  StartOverlay.swift
//  Navee
//

import SwiftUI

struct StartOverlay: View {
    let onStart: () -> Void

    var body: some View {
        ZStack {
            // Background saja dalam GeometryReader
            GeometryReader { geo in
                Image("welcomepage")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width:  geo.size.width  * 1.15,
                        height: geo.size.height * 1.15
                    )
                    .position(
                        x: geo.size.width  / 2,
                        y: geo.size.height / 2
                    )
                    .clipped()
            }
            .ignoresSafeArea()

            // Konten — pure SwiftUI centering, zero offset
            VStack(spacing: 32) {
                Spacer()

                Image("island")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity)  // paksa full width simetris

                Text("Drop a trail so you can always\nfind your way back.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)  // paksa center simetris

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 0)  // pastikan zero horizontal offset
        }
    }
}

#Preview {
    StartOverlay(onStart: {})
}
