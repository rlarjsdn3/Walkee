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
