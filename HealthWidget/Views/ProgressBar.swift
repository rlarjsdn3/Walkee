//
//  ProgressBar.swift
//  Health
//
//  Created by Seohyun Kim on 8/25/25.
//
import SwiftUI

struct ProgressBar: View {
	let progress: Double
	let height: CGFloat
	let fill: Color

	var body: some View {
		GeometryReader { geo in
			ZStack(alignment: .leading) {
				Capsule().fill(Color(.systemGray4))
				Capsule()
					.fill(fill)
					.frame(width: geo.size.width * CGFloat(min(max(progress, 0), 1)))
			}
		}
		.frame(height: height)
	}
}

#if DEBUG
struct ProgressBar_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 12) {
			ProgressBar(progress: 0.25, height: 8, fill: .accent)
			ProgressBar(progress: 0.6, height: 10, fill: .teal)
			ProgressBar(progress: 1.0, height: 12, fill: .green)
		}
		.padding()
		.previewLayout(.sizeThatFits)
	}
}
#endif
