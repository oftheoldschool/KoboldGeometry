import simd

public struct KGEOGeometryCubeSphere {
    private static let positions: [SIMD3<Float>] = [
        SIMD3<Float>( 0.5,  0.5,  0.5),
        SIMD3<Float>( 0.5, -0.5,  0.5),
        SIMD3<Float>(-0.5, -0.5,  0.5),
        SIMD3<Float>(-0.5,  0.5,  0.5),
        SIMD3<Float>( 0.5,  0.5, -0.5),
        SIMD3<Float>( 0.5, -0.5, -0.5),
        SIMD3<Float>(-0.5, -0.5, -0.5),
        SIMD3<Float>(-0.5,  0.5, -0.5),
    ]

    private static let faces: [Int] = [
        0,1,2,3,
        6,7,3,2,
        7,6,5,4,
        5,1,0,4,
        0,3,7,4,
        5,6,2,1,
    ]

    public static func getVertices(
        subdivisions: Int = 0,
        radius: Float = 1,
        inwardFaces: Bool = false,
        smoothNormals: Bool = false
    ) -> KGEOGeometry {
        if smoothNormals {
            return getSmoothNormalVertices(
                subdivisions: subdivisions,
                radius: radius,
                inwardFaces: inwardFaces)
        } else {
            return getFlatNormalVertices(
                subdivisions: subdivisions,
                radius: radius,
                inwardFaces: inwardFaces)
        }
    }

    private static func getSmoothNormalVertices(
        subdivisions: Int,
        radius: Float,
        inwardFaces: Bool
    ) -> KGEOGeometry {
        var indices: [UInt32] = []
        let vertexMap = KGEOGeometryVertexMap<SIMD3<Float>>()

        let segments = max(1, Int(pow(2.0, Float(subdivisions))))
        let segmentSize: Float = 1.0 / Float(segments)

        for faceIndex in 0..<6 {
            let baseIndices = Array(faces[faceIndex * 4..<faceIndex * 4 + 4])
            let faceVertices = baseIndices.map { positions[$0] }

            for row in 0...segments {
                let v = Float(row) * segmentSize
                for col in 0...segments {
                    let u = Float(col) * segmentSize

                    let p0 = mix(faceVertices[0], faceVertices[1], t: v)
                    let p1 = mix(faceVertices[3], faceVertices[2], t: v)
                    let position = mix(p0, p1, t: u)

                    if row < segments && col < segments {
                        let i0 = vertexMap.getVertexIndex(for: vertexMap.roundedKey(position)) {
                            let normalizedPos = normalize(position) * radius
                            let normal = normalize(position)
                            return (
                                position: normalizedPos,
                                normal: inwardFaces ? -normal : normal,
                                texCoord: .zero
                            )
                        }

                        let posRight = mix(p0, p1, t: u + segmentSize)
                        let i1 = vertexMap.getVertexIndex(for: vertexMap.roundedKey(posRight)) {
                            let normalizedPos = normalize(posRight) * radius
                            let normal = normalize(posRight)
                            return (
                                position: normalizedPos,
                                normal: inwardFaces ? -normal : normal,
                                texCoord: .zero
                            )
                        }

                        let p0Next = mix(faceVertices[0], faceVertices[1], t: v + segmentSize)
                        let p1Next = mix(faceVertices[3], faceVertices[2], t: v + segmentSize)
                        let posDown = mix(p0Next, p1Next, t: u)
                        let i2 = vertexMap.getVertexIndex(for: vertexMap.roundedKey(posDown)) {
                            let normalizedPos = normalize(posDown) * radius
                            let normal = normalize(posDown)
                            return (
                                position: normalizedPos,
                                normal: inwardFaces ? -normal : normal,
                                texCoord: .zero
                            )
                        }

                        let posDiag = mix(p0Next, p1Next, t: u + segmentSize)
                        let i3 = vertexMap.getVertexIndex(for: vertexMap.roundedKey(posDiag)) {
                            let normalizedPos = normalize(posDiag) * radius
                            let normal = normalize(posDiag)
                            return (
                                position: normalizedPos,
                                normal: inwardFaces ? -normal : normal,
                                texCoord: .zero
                            )
                        }

                        indices += [
                            i0, i1, i2,
                            i1, i3, i2
                        ]
                    }
                }
            }
        }

        return KGEOGeometry(
            vertices: vertexMap.allVertices,
            indices: indices)
    }

    private static func getFlatNormalVertices(
        subdivisions: Int,
        radius: Float,
        inwardFaces: Bool
    ) -> KGEOGeometry {
        var vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var indices: [UInt32] = []

        let segments = max(1, Int(pow(2.0, Float(subdivisions))))
        let segmentSize: Float = 1.0 / Float(segments)

        for faceIndex in 0..<6 {
            let baseIndices = Array(faces[faceIndex * 4..<faceIndex * 4 + 4])
            let faceVertices = baseIndices.map { positions[$0] }

            for row in 0..<segments {
                let v = Float(row) * segmentSize
                let vNext = v + segmentSize

                for col in 0..<segments {
                    let u = Float(col) * segmentSize
                    let uNext = u + segmentSize

                    let p0 = mix(faceVertices[0], faceVertices[1], t: v)
                    let p1 = mix(faceVertices[3], faceVertices[2], t: v)
                    let pos00 = mix(p0, p1, t: u)
                    let pos10 = mix(p0, p1, t: uNext)

                    let p0Next = mix(faceVertices[0], faceVertices[1], t: vNext)
                    let p1Next = mix(faceVertices[3], faceVertices[2], t: vNext)
                    let pos01 = mix(p0Next, p1Next, t: u)
                    let pos11 = mix(p0Next, p1Next, t: uNext)

                    let spherePos00 = normalize(pos00) * radius
                    let spherePos10 = normalize(pos10) * radius
                    let spherePos01 = normalize(pos01) * radius
                    let spherePos11 = normalize(pos11) * radius

                    let normal1 = cross(spherePos10 - spherePos00, spherePos01 - spherePos00)
                    let normal2 = cross(spherePos11 - spherePos10, spherePos01 - spherePos10)
                    let quadNormal = normalize(normal1 + normal2)

                    let finalNormal = inwardFaces ? -quadNormal : quadNormal

                    let idx = UInt32(vertices.count)
                    vertices.append((position: spherePos00, normal: finalNormal, texCoord: SIMD2<Float>(u, v)))
                    vertices.append((position: spherePos10, normal: finalNormal, texCoord: SIMD2<Float>(uNext, v)))
                    vertices.append((position: spherePos01, normal: finalNormal, texCoord: SIMD2<Float>(u, vNext)))
                    vertices.append((position: spherePos11, normal: finalNormal, texCoord: SIMD2<Float>(uNext, vNext)))

                    indices += [
                        idx, idx + 1, idx + 2,
                        idx + 1, idx + 3, idx + 2,
                    ]
                }
            }
        }


        return KGEOGeometry(
            vertices: vertices,
            indices: indices)
    }


    private static func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        return a + (b - a) * t
    }
}
