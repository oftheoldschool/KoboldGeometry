import simd

public struct KGEOGeometryCone {
    public static func getVertices(
        radius: Float = 1,
        height: Float = 2,
        segments: Int = 16,
        flatNormals: Bool = false
    ) -> KGEOGeometry
    {
        if flatNormals {
            return getFlatNormalCone(radius: radius, height: height, segments: segments)
        } else {
            return getSmoothNormalCone(radius: radius, height: height, segments: segments)
        }
    }

    private static func getSmoothNormalCone(
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

        let slopeAngle = atan2f(height, radius)

        (0..<segments).forEach { index in
            let firstUnitX = sinf(Float(index) * theta)
            let firstUnitZ = cosf(Float(index) * theta)

            let firstX = radius * firstUnitX
            let firstZ = radius * firstUnitZ

            vertices += [
                (position: SIMD3<Float>(firstX, bottomY, firstZ),
                 normal: .yNegative, texCoord: .zero),
                (position: SIMD3<Float>(firstX, bottomY, firstZ),
                 normal: normalize(
                    SIMD3<Float>(
                        firstUnitX * sinf(slopeAngle),
                        cosf(slopeAngle),
                        firstUnitZ * sinf(slopeAngle))),
                 texCoord: .zero),
            ]

            let bottom1 = vertices.count - 2
            let bottom2 = (vertices.count - 2) % (segments * 2) + 2
            let side1 = vertices.count - 1
            let side2 = (vertices.count - 2) % (segments * 2) + 3
            indices += [
                UInt32(0),
                UInt32(bottom2),
                UInt32(bottom1),
                UInt32(1),
                UInt32(side1),
                UInt32(side2),
            ]
        }

        return KGEOGeometry(
            vertices: vertices,
            indices: indices
        )
    }

    private static func getFlatNormalCone(
        radius: Float,
        height: Float,
        segments: Int
    ) -> KGEOGeometry {
        let theta = Float.pi * 2 / Float(segments)
        let topY = height / 2
        let bottomY = -topY
        let topCentre = SIMD3<Float>(0, topY, 0)
        let bottomCentre = SIMD3<Float>(0, bottomY, 0)

        var vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var indices: [UInt32] = []

        for i in 0..<segments {
            let currentAngle = Float(i) * theta
            let nextAngle = Float(i + 1) * theta

            let currentUnitX = sinf(currentAngle)
            let currentUnitZ = cosf(currentAngle)
            let nextUnitX = sinf(nextAngle)
            let nextUnitZ = cosf(nextAngle)

            let currentX = radius * currentUnitX
            let currentZ = radius * currentUnitZ
            let nextX = radius * nextUnitX
            let nextZ = radius * nextUnitZ

            let bottomNormal = SIMD3<Float>.yNegative
            let bottomIndex = UInt32(vertices.count)

            vertices.append((position: bottomCentre, normal: bottomNormal, texCoord: .zero))
            vertices.append((position: SIMD3<Float>(nextX, bottomY, nextZ), normal: bottomNormal, texCoord: .zero))
            vertices.append((position: SIMD3<Float>(currentX, bottomY, currentZ), normal: bottomNormal, texCoord: .zero))

            indices.append(bottomIndex)
            indices.append(bottomIndex + 1)
            indices.append(bottomIndex + 2)

            let v1 = SIMD3<Float>(currentX, bottomY, currentZ)
            let v2 = SIMD3<Float>(nextX, bottomY, nextZ)
            let v3 = topCentre

            let edge1 = v2 - v1
            let edge2 = v3 - v1
            let sideNormal = normalize(cross(edge1, edge2))

            let sideIndex = UInt32(vertices.count)

            vertices.append((position: SIMD3<Float>(currentX, bottomY, currentZ), normal: sideNormal, texCoord: .zero))
            vertices.append((position: SIMD3<Float>(nextX, bottomY, nextZ), normal: sideNormal, texCoord: .zero))
            vertices.append((position: topCentre, normal: sideNormal, texCoord: .zero))

            indices.append(sideIndex)
            indices.append(sideIndex + 1)
            indices.append(sideIndex + 2)
        }

        return KGEOGeometry(
            vertices: vertices,
            indices: indices
        )
    }
}
