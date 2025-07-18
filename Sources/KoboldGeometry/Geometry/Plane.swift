import simd

public class KGEOGeometryPlane {
    public static func getVertices() -> KGEOGeometry {
        let vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = [
            (SIMD3<Float>( 0.5, 0,  0.5), .yPositive, nil),
            (SIMD3<Float>( 0.5, 0, -0.5), .yPositive, nil),
            (SIMD3<Float>(-0.5, 0, -0.5), .yPositive, nil),
            (SIMD3<Float>(-0.5, 0,  0.5), .yPositive, nil),
        ]
        let indices: [UInt32] = [0,1,2,0,2,3]
        
        return KGEOGeometry(
            vertices: vertices,
            indices: indices)
    }
}
