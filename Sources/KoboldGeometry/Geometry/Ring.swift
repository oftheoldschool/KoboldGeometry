import simd

public class KGeometryRing {
    public static func getVertices(
        segments: Int,
        outerRadius: Float,
        innerRadius: Float
    ) -> KGeometry {
        let segmentAngle = Float.pi * 2.0 / Float(segments)
        let vertices = (0..<segments).flatMap { i in
            let angle = segmentAngle * Float(i)
            let segmentVertices: [(SIMD3<Float>, SIMD3<Float>, SIMD2<Float>?)] = [
                (SIMD3<Float>(sin(angle) * innerRadius, 0, cos(angle) * innerRadius), SIMD3<Float>.yPositive, nil),
                (SIMD3<Float>(sin(angle) * outerRadius, 0, cos(angle) * outerRadius), SIMD3<Float>.yPositive, nil),
            ]
            return segmentVertices
        }
        let indices: [UInt32] = (0..<UInt32(segments)).flatMap { i in
            let baseVertex = i * 2
            let nextVertex = i == segments - 1 ? 0 : UInt32(i + 1) * 2
            return [
               baseVertex,
               baseVertex + 1,
               nextVertex,
               baseVertex + 1,
               nextVertex + 1,
               nextVertex,
            ]
        }
        
        return KGeometry(
            vertices: vertices,
            indices: indices)
    }
}
