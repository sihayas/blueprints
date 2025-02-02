//
//  AvatarView.swift
//  blueprints
//
//  Created by decoherence on 1/28/25.
//


//
//  AvatarView.swift
//  acusia
//
//  Created by decoherence on 8/25/24.
//

import SwiftUI

struct AvatarView: View {
    let size: CGFloat
    let imageURL: String

    var body: some View {
        AsyncImage(url: URL(string: imageURL)) { image in
            image
                .resizable()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        } placeholder: {
            Circle()
                .fill(Color.gray)
                .frame(width: size, height: size)
        }
    }
}