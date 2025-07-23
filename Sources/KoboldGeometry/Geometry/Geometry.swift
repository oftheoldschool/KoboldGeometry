public struct KGEOGeometry {
    public let vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)]
    public let indices: [UInt32]

    public init(
        vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)],
        indices: [UInt32] = []
    ) {
        self.vertices = vertices
        self.indices = indices
    }
}
