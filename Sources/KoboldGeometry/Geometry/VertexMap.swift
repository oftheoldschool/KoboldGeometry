import simd

public class KGeometryVertexMap<T: Hashable> {
    private var vertexMap: [T: UInt32] = [:]
    private var vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
    
    public init() {}
    
    public func getVertexIndex(for key: T, vertexGenerator: () -> (position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)) -> UInt32 {
        if let existingIndex = vertexMap[key] {
            return existingIndex
        }
        
        let newVertex = vertexGenerator()
        let newIndex = UInt32(vertices.count)
        vertices.append(newVertex)
        vertexMap[key] = newIndex
        return newIndex
    }
    
    public var allVertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] {
        return vertices
    }
    
    public var count: Int {
        return vertices.count
    }
}

public extension KGeometryVertexMap where T == SIMD3<Float> {
    func roundedKey(_ position: SIMD3<Float>, precision: Float = 1e6) -> SIMD3<Float> {
        return SIMD3<Float>(
            round(position.x * precision) / precision,
            round(position.y * precision) / precision,
            round(position.z * precision) / precision
        )
    }
}
