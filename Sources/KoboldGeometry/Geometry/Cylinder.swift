import simd

public struct KGEOGeometryCylinder {
    public static func getVertices(
        radius: Float = 1,
        height: Float = 2,
        segments: Int = 16,
        smoothNormals: Bool = true
    ) -> KGEOGeometry
    {
        if smoothNormals {
            return getSmoothNormalVertices(
                radius: radius,
                height: height,
                segments: segments)
        } else {
            return getFlatNormalVertices(
                radius: radius,
                height: height,
                segments: segments)
        }
    }

    private static func getSmoothNormalVertices(
        radius: Float,
        height: Float,
        segments: Int
    ) -> KGEOGeometry {
        let theta = Float.pi * 2 / Float(segments)
        let topY = height / 2
        let bottomY = -topY
        let topCentre = SIMD3<Float>(0, topY, 0)
        let bottomCentre = SIMD3<Float>(0, bottomY, 0)

        let bottomVertex: (SIMD3<Float>, SIMD3<Float>, SIMD2<Float>?) = (position: bottomCentre, normal: SIMD3<Float>.yNegative, texCoord: .zero)
        let topVertex: (SIMD3<Float>, SIMD3<Float>, SIMD2<Float>?) = (position: topCentre, normal: SIMD3<Float>.yPositive, texCoord: .zero)

        var vertices = [bottomVertex, topVertex]
        var indices: [UInt32] = []

        (0..<segments).forEach { index in
            let firstX = radius * sinf(Float(index) * theta)
            let firstZ = radius * cosf(Float(index) * theta)

            vertices += [
                (position: SIMD3<Float>(firstX, bottomY, firstZ), normal: SIMD3<Float>.yNegative, texCoord: .zero),
                (position: SIMD3<Float>(firstX, topY, firstZ), normal: SIMD3<Float>.yPositive, texCoord: .zero),
                (position: SIMD3<Float>(firstX, bottomY, firstZ), normal: normalize(SIMD3<Float>(firstX, 0, firstZ)), texCoord: .zero),
                (position: SIMD3<Float>(firstX, topY, firstZ), normal: normalize(SIMD3<Float>(firstX, 0, firstZ)), texCoord: .zero),
            ]

            let bottom1 = vertices.count - 4
            let bottom2 = (vertices.count - 2) % (segments * 4) + 2
            let top1 = vertices.count - 3
            let top2 = (vertices.count - 2) % (segments * 4) + 3
            let sideBottom1 = vertices.count - 2
            let sideBottom2 = (vertices.count - 2) % (segments * 4) + 4
            let sideTop1 = vertices.count - 1
            let sideTop2 = (vertices.count - 2) % (segments * 4) + 5

            indices += [
                UInt32(0),
                UInt32(bottom2),
                UInt32(bottom1),
                UInt32(1),
                UInt32(top1),
                UInt32(top2),
                UInt32(sideBottom1),
                UInt32(sideBottom2),
                UInt32(sideTop1),
                UInt32(sideTop2),
                UInt32(sideTop1),
                UInt32(sideBottom2),
            ]
        }

        return KGEOGeometry(vertices: vertices, indices: indices)
    }

    private static func getFlatNormalVertices(
        radius: Float,
        height: Float,
        segments: Int
    ) -> KGEOGeometry {
        let theta = Float.pi * 2 / Float(segments)
        let topY = height / 2
        let bottomY = -topY

        var vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var indices: [UInt32] = []

        for i in 0..<segments {
            let angle1 = Float(i) * theta
            let angle2 = Float(i + 1) * theta

            let x1 = radius * sinf(angle1)
            let z1 = radius * cosf(angle1)
            let x2 = radius * sinf(angle2)
            let z2 = radius * cosf(angle2)

            let bottomNormal = SIMD3<Float>.yNegative
            let bottomCenter = SIMD3<Float>(0, bottomY, 0)
            let bottomEdge1 = SIMD3<Float>(x1, bottomY, z1)
            let bottomEdge2 = SIMD3<Float>(x2, bottomY, z2)

            let bottomStartIndex = UInt32(vertices.count)
            vertices.append((position: bottomCenter, normal: bottomNormal, texCoord: .zero))
            vertices.append((position: bottomEdge1, normal: bottomNormal, texCoord: .zero))
            vertices.append((position: bottomEdge2, normal: bottomNormal, texCoord: .zero))

            indices.append(bottomStartIndex)
            indices.append(bottomStartIndex + 2)
            indices.append(bottomStartIndex + 1)

            let topNormal = SIMD3<Float>.yPositive
            let topCenter = SIMD3<Float>(0, topY, 0)
            let topEdge1 = SIMD3<Float>(x1, topY, z1)
            let topEdge2 = SIMD3<Float>(x2, topY, z2)

            let topStartIndex = UInt32(vertices.count)
            vertices.append((position: topCenter, normal: topNormal, texCoord: .zero))
            vertices.append((position: topEdge1, normal: topNormal, texCoord: .zero))
            vertices.append((position: topEdge2, normal: topNormal, texCoord: .zero))

            indices.append(topStartIndex)
            indices.append(topStartIndex + 1)
            indices.append(topStartIndex + 2)

            let sideBottom1 = SIMD3<Float>(x1, bottomY, z1)
            let sideBottom2 = SIMD3<Float>(x2, bottomY, z2)
            let sideTop1 = SIMD3<Float>(x1, topY, z1)
            let sideTop2 = SIMD3<Float>(x2, topY, z2)

            let edge1 = sideTop1 - sideBottom1
            let edge2 = sideBottom2 - sideBottom1
            let sideNormal = normalize(cross(edge2, edge1))

            let sideStartIndex = UInt32(vertices.count)
            vertices.append((position: sideBottom1, normal: sideNormal, texCoord: .zero))
            vertices.append((position: sideBottom2, normal: sideNormal, texCoord: .zero))
            vertices.append((position: sideTop1, normal: sideNormal, texCoord: .zero))

            vertices.append((position: sideTop1, normal: sideNormal, texCoord: .zero))
            vertices.append((position: sideBottom2, normal: sideNormal, texCoord: .zero))
            vertices.append((position: sideTop2, normal: sideNormal, texCoord: .zero))

            indices.append(sideStartIndex)
            indices.append(sideStartIndex + 1)
            indices.append(sideStartIndex + 2)

            indices.append(sideStartIndex + 3)
            indices.append(sideStartIndex + 4)
            indices.append(sideStartIndex + 5)
        }

        return KGEOGeometry(vertices: vertices, indices: indices)
    }
}
