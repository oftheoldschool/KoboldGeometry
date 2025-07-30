import simd

public class KGEOGeometryDisc {
    public static func getVertices(
        segments: Int,
        radius: Float
    ) -> KGEOGeometry {
        let segmentAngle = Float.pi * 2.0 / Float(segments)
        let centerVertex: [(SIMD3<Float>, SIMD3<Float>, SIMD2<Float>?)] = [(.zero, .yPositive, nil)]
        let vertices = centerVertex + (0..<segments).map { i in
            let angle = segmentAngle * Float(i)
            return (SIMD3<Float>(sin(angle) * radius, 0, cos(angle) * radius), SIMD3<Float>.yPositive, nil)
        }
        let indices: [UInt32] = (0..<UInt32(segments)).flatMap { i in
            let baseVertex = 1 + i
            let nextVertex = 1 + (i == segments - 1 ? 0 : UInt32(i + 1))
            return [
                0,
                baseVertex,
                nextVertex
            ]
        }
        
        return KGEOGeometry(
            vertices: vertices,
            indices: indices)
    }
}
