import simd

public struct KGEOGeometryCube {
    private static let positions: [SIMD3<Float>] = [
        SIMD3<Float>( 1,  1,  1),
        SIMD3<Float>( 1, -1,  1),
        SIMD3<Float>(-1, -1,  1),
        SIMD3<Float>(-1,  1,  1),
        SIMD3<Float>( 1,  1, -1),
        SIMD3<Float>( 1, -1, -1),
        SIMD3<Float>(-1, -1, -1),
        SIMD3<Float>(-1,  1, -1),
    ]

    private static let normals: [SIMD3<Float>] = [
        .xPositive,
        .xNegative,
        .yPositive,
        .yNegative,
        .zPositive,
        .zNegative,
    ]

    private static let faces: [Int] = [
        5,1,0,4,
        6,7,3,2,
        0,3,7,4,
        5,6,2,1,
        0,1,2,3,
        7,6,5,4,
    ]

    private static let texCoords: [SIMD2<Float>] = [
        SIMD2<Float>(1, 0),
        SIMD2<Float>(0, 0),
        SIMD2<Float>(0, 1),
        SIMD2<Float>(1, 1),
    ]

    public static func getVertices() -> KGEOGeometry {
        var vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var indices: [UInt32] = []

        faces.sliding(4).forEach { (offset, window) in
            let vertexOffset = vertices.count
            let faceIndex = offset / 4

            vertices += window.enumerated().map { (i, index) in
                return (position: positions[index], normal: normals[faceIndex], texCoord: texCoords[i])
            }
            indices += [0,2,1,0,3,2].map { $0 + UInt32(vertexOffset) }
        }

        return KGEOGeometry(
            vertices: vertices,
            indices: indices)
    }
}
