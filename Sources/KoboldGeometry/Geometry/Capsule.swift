import simd

public struct KGEOGeometryCapsule {
    public static func getVertices(
        cylinderRadius: Float = 0.5,
        capRadius: Float? = nil,
        height: Float = 1,
        segments: Int = 16,
        capSubdivisions: Int? = nil,
        flatNormals: Bool = false
    ) -> KGEOGeometry {
        let segments = max(3, segments)
        let actualCapRadius = capRadius ?? cylinderRadius
        let actualCapSubdivisions = capSubdivisions ?? (segments / 2)
        var vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var indices: [UInt32] = []

        for y in 0..<segments {
            let yPos = height * (Float(y) / Float(segments) - 0.5)
            let yPosNext = height * (Float(y + 1) / Float(segments) - 0.5)

            for x in 0..<segments {
                let angle = Float(x) / Float(segments) * 2 * Float.pi
                let nextAngle = Float(x + 1) / Float(segments) * 2 * Float.pi

                let xPos = sin(angle) * cylinderRadius
                let zPos = cos(angle) * cylinderRadius
                let xPosNext = sin(nextAngle) * cylinderRadius
                let zPosNext = cos(nextAngle) * cylinderRadius

                let bottomLeft = SIMD3<Float>(xPos, yPos, zPos)
                let bottomRight = SIMD3<Float>(xPosNext, yPos, zPosNext)
                let topLeft = SIMD3<Float>(xPos, yPosNext, zPos)
                let topRight = SIMD3<Float>(xPosNext, yPosNext, zPosNext)

                let normal: SIMD3<Float>
                let nextNormal: SIMD3<Float>

                if flatNormals {
                    let edge1 = bottomRight - bottomLeft
                    let edge2 = topLeft - bottomLeft
                    normal = normalize(cross(edge1, edge2))
                    nextNormal = normal
                } else {
                    normal = normalize(SIMD3<Float>(xPos, 0, zPos))
                    nextNormal = normalize(SIMD3<Float>(xPosNext, 0, zPosNext))
                }

                let baseIndex = UInt32(vertices.count)

                vertices.append((position: bottomLeft, normal: normal, texCoord: .zero))
                vertices.append((position: bottomRight, normal: nextNormal, texCoord: .zero))
                vertices.append((position: topLeft, normal: normal, texCoord: .zero))

                vertices.append((position: bottomRight, normal: nextNormal, texCoord: .zero))
                vertices.append((position: topRight, normal: nextNormal, texCoord: .zero))
                vertices.append((position: topLeft, normal: normal, texCoord: .zero))

                indices.append(contentsOf: [
                    baseIndex, baseIndex + 1, baseIndex + 2,
                    baseIndex + 3, baseIndex + 4, baseIndex + 5
                ])
            }
        }

        for cap in 0...1 {
            let yOffset = (cap == 0 ? -0.5 : 0.5) * height

            for y in 0..<actualCapSubdivisions {
                let phi = Float(y) / Float(actualCapSubdivisions) * Float.pi/2
                let yPos = cos(phi) * actualCapRadius
                let sphereRadius = sin(phi) * cylinderRadius

                for x in 0..<segments {
                    let theta = Float(x) / Float(segments) * 2 * Float.pi
                    let nextTheta = Float(x + 1) / Float(segments) * 2 * Float.pi

                    let pos1 = SIMD3<Float>(
                        sin(theta) * sphereRadius,
                        (cap == 0 ? -yPos : yPos) + yOffset,
                        cos(theta) * sphereRadius
                    )
                    let pos2 = SIMD3<Float>(
                        sin(nextTheta) * sphereRadius,
                        (cap == 0 ? -yPos : yPos) + yOffset,
                        cos(nextTheta) * sphereRadius
                    )

                    let nextPhi = Float(y + 1) / Float(actualCapSubdivisions) * Float.pi/2
                    let nextYPos = cos(nextPhi) * actualCapRadius
                    let nextRadius = sin(nextPhi) * cylinderRadius

                    let pos3 = SIMD3<Float>(
                        sin(theta) * nextRadius,
                        (cap == 0 ? -nextYPos : nextYPos) + yOffset,
                        cos(theta) * nextRadius
                    )
                    let pos4 = SIMD3<Float>(
                        sin(nextTheta) * nextRadius,
                        (cap == 0 ? -nextYPos : nextYPos) + yOffset,
                        cos(nextTheta) * nextRadius
                    )

                    let normal1, normal2, normal3, normal4: SIMD3<Float>
                    if flatNormals {
                        let edge1 = pos2 - pos1
                        let edge2 = pos3 - pos1
                        let crossProduct = cross(edge1, edge2)
                        let len = length(crossProduct)
                        let faceNormal = len > Float.ulpOfOne
                            ? crossProduct / len
                            : SIMD3<Float>(0, -1, 0)
                        normal1 = faceNormal
                        normal2 = faceNormal
                        normal3 = faceNormal
                        normal4 = faceNormal
                    } else {
                        let centerY = yOffset
                        normal1 = normalize(SIMD3<Float>(
                            (pos1.x - 0) / (cylinderRadius * cylinderRadius),
                            (pos1.y - centerY) / (actualCapRadius * actualCapRadius),
                            (pos1.z - 0) / (cylinderRadius * cylinderRadius)
                        ))
                        normal2 = normalize(SIMD3<Float>(
                            (pos2.x - 0) / (cylinderRadius * cylinderRadius),
                            (pos2.y - centerY) / (actualCapRadius * actualCapRadius),
                            (pos2.z - 0) / (cylinderRadius * cylinderRadius)
                        ))
                        normal3 = normalize(SIMD3<Float>(
                            (pos3.x - 0) / (cylinderRadius * cylinderRadius),
                            (pos3.y - centerY) / (actualCapRadius * actualCapRadius),
                            (pos3.z - 0) / (cylinderRadius * cylinderRadius)
                        ))
                        normal4 = normalize(SIMD3<Float>(
                            (pos4.x - 0) / (cylinderRadius * cylinderRadius),
                            (pos4.y - centerY) / (actualCapRadius * actualCapRadius),
                            (pos4.z - 0) / (cylinderRadius * cylinderRadius)
                        ))
                    }

                    let baseIndex = UInt32(vertices.count)

                    if cap == 0 {
                        vertices.append((position: pos1, normal: normal1, texCoord: .zero))
                        vertices.append((position: pos2, normal: normal2, texCoord: .zero))
                        vertices.append((position: pos3, normal: normal3, texCoord: .zero))

                        vertices.append((position: pos2, normal: normal2, texCoord: .zero))
                        vertices.append((position: pos4, normal: normal4, texCoord: .zero))
                        vertices.append((position: pos3, normal: normal3, texCoord: .zero))
                    } else {
                        let normalMultiplier: Float = flatNormals ? -1 : 1
                        vertices.append((position: pos1, normal: normalMultiplier * normal1, texCoord: .zero))
                        vertices.append((position: pos3, normal: normalMultiplier * normal3, texCoord: .zero))
                        vertices.append((position: pos2, normal: normalMultiplier * normal2, texCoord: .zero))

                        vertices.append((position: pos2, normal: normalMultiplier * normal2, texCoord: .zero))
                        vertices.append((position: pos3, normal: normalMultiplier * normal3, texCoord: .zero))
                        vertices.append((position: pos4, normal: normalMultiplier * normal4, texCoord: .zero))
                    }

                    indices.append(contentsOf: [
                        baseIndex, baseIndex + 1, baseIndex + 2,
                        baseIndex + 3, baseIndex + 4, baseIndex + 5
                    ])
                }
            }
        }

        return KGEOGeometry(
            vertices: vertices,
            indices: indices
        )
    }
}
