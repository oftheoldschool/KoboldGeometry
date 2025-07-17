public struct KGeometry {
    public let vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)]
    public let indices: [UInt32]
}

extension KGeometry {
    init(vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)]) {
        self.vertices = vertices
        self.indices = []
    }
}
