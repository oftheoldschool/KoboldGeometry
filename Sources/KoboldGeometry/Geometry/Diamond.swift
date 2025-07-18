import simd

public struct KGEOGeometryDiamond {
    public static func getVertices(
        facets: Int = 8,
        topBottom: Float = 0.25,
        upperRadius: Float = 1.2,
        middleRadius: Float = 1.4,
        bevel: Float = 0.125
    ) -> KGEOGeometry {
        let angleSize = Float.pi * 2 / Float(facets)
        let upperBevelY = 1 - (bevel * 2)
        let middle = 1 - (topBottom * 2)

        let top0 = SIMD3<Float>(0, 1, 0) * 0.5
        let bottom0 = SIMD3<Float>(0, -1, 0) * 0.5

        var vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var indices: [UInt32] = []

        for i in 0..<facets {
            let currentAngle = (x: sin(angleSize * Float(i)), z: cos(angleSize * Float(i)))
            let nextAngle = (x: sin(angleSize * Float(i + 1)), z: cos(angleSize * Float(i + 1)))

            let top1 = SIMD3<Float>(currentAngle.x * upperRadius, upperBevelY, currentAngle.z * upperRadius) * 0.5
            let top2 = SIMD3<Float>(nextAngle.x * upperRadius, upperBevelY, nextAngle.z * upperRadius) * 0.5
            let middle0 = SIMD3<Float>(currentAngle.x * middleRadius, middle, currentAngle.z * middleRadius) * 0.5
            let middle1 = SIMD3<Float>(nextAngle.x * middleRadius, middle, nextAngle.z * middleRadius) * 0.5

            let faces = [
                [top0, top1, top2],
                [top1, middle0, top2],
                [top2, middle0, middle1],
                [middle0, bottom0, middle1],
            ]

            for face in faces {
                let v0v1 = normalize(face[1] - face[0])
                let v1v2 = normalize(face[2] - face[1])
                let faceNormal = normalize(cross(-v1v2, v0v1))

                let baseIndex = UInt32(vertices.count)

                for vertex in face {
                    vertices.append((position: vertex, normal: faceNormal, texCoord: .zero))
                }

                indices.append(baseIndex)
                indices.append(baseIndex + 1)
                indices.append(baseIndex + 2)
            }
        }

        return KGEOGeometry(
            vertices: vertices,
            indices: indices
        )
    }
}
