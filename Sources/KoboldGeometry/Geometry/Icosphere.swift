import simd

public typealias HeightFunction = ([SIMD3<Float>]) -> [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)]

public class KGEOGeometryIcosphere {
    private static let x: Float = 0.525731112119133696
    private static let z: Float = 0.850650808352039932

    private static let vertexData: [[Float]] = [
        [ -x,  0.0, z ],
        [ x,   0.0, z ],
        [ -x,  0.0, -z ],
        [ x,   0.0, -z ],
        [ 0.0, z,   x ],
        [ 0.0, z,   -x ],
        [ 0.0, -z,  x ],
        [ 0.0, -z,  -x ],
        [ z,   x,   0.0 ],
        [ -z,  x,   0.0 ],
        [ z,   -x,  0.0 ],
        [ -z,  -x,  0.0 ],
    ]

    private static let indexData = [
        [ 1,  4,  0 ],
        [ 4,  9,  0 ],
        [ 4,  5,  9 ],
        [ 8,  5,  4 ],
        [ 1,  8,  4 ],
        [ 1,  10, 8 ],
        [ 10, 3,  8 ],
        [ 8,  3,  5 ],
        [ 3,  2,  5 ],
        [ 3,  7,  2 ],
        [ 3,  10, 7 ],
        [ 10, 6,  7 ],
        [ 6,  11, 7 ],
        [ 6,  0,  11 ],
        [ 6,  1,  0 ],
        [ 10, 1,  6 ],
        [ 11, 0,  9 ],
        [ 2,  11, 9 ],
        [ 5,  2,  9 ],
        [ 11, 2,  7 ],
    ]

    public static func getVertices(
        subdivisions: Int = 1,
        radius: Float = 1,
        inwardNormals: Bool = false,
        flatNormals: Bool = false,
        vertexHeightFunction: HeightFunction? = nil
    ) -> KGEOGeometry {
        if flatNormals {
            return getFlatNormalGeometry(
                subdivisions: subdivisions,
                radius: radius,
                inwardNormals: inwardNormals,
                vertexHeightFunction: vertexHeightFunction
            )
        } else {
            return getSmoothNormalGeometry(
                subdivisions: subdivisions,
                radius: radius,
                inwardNormals: inwardNormals,
                vertexHeightFunction: vertexHeightFunction
            )
        }
    }

    private static func getSmoothNormalGeometry(
        subdivisions: Int,
        radius: Float,
        inwardNormals: Bool,
        vertexHeightFunction: HeightFunction?
    ) -> KGEOGeometry {
        var vertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var indices: [UInt32] = []

        let baseVertices = vertexData.map { SIMD3<Float>($0[0], $0[1], $0[2]) }

        for vertex in baseVertices {
            let normal = normalize(vertex)
            let position = normal * radius
            vertices.append((
                position: position,
                normal: inwardNormals ? -normal : normal,
                texCoord: .zero
            ))
        }

        for triangle in indexData {
            indices.append(UInt32(triangle[0]))
            if inwardNormals {
                indices.append(UInt32(triangle[2]))
                indices.append(UInt32(triangle[1]))
            } else {
                indices.append(UInt32(triangle[1]))
                indices.append(UInt32(triangle[2]))
            }
        }

        if subdivisions > 0 {
            var subdividedVertices = vertices
            var subdividedIndices: [UInt32] = []

            for _ in 0..<subdivisions {
                var middlePointCache: [String: UInt32] = [:]

                for i in stride(from: 0, to: indices.count, by: 3) {
                    let v1 = indices[i]
                    let v2 = indices[i + 1]
                    let v3 = indices[i + 2]

                    let a = getMiddlePoint(v1, v2, &subdividedVertices, &middlePointCache, radius)
                    let b = getMiddlePoint(v2, v3, &subdividedVertices, &middlePointCache, radius)
                    let c = getMiddlePoint(v3, v1, &subdividedVertices, &middlePointCache, radius)

                    subdividedIndices += [v1, a, c]
                    subdividedIndices += [v2, b, a]
                    subdividedIndices += [v3, c, b]
                    subdividedIndices += [a, b, c]
                }

                indices = subdividedIndices
                subdividedIndices = []
            }

            vertices = subdividedVertices
        }

        if let heightFunc = vertexHeightFunction {
            let positions = vertices.map { $0.position }
            let modifiedVertices = heightFunc(positions)
            vertices = modifiedVertices
        }

        return KGEOGeometry(
            vertices: vertices,
            indices: indices)
    }

    private static func getFlatNormalGeometry(
        subdivisions: Int,
        radius: Float,
        inwardNormals: Bool,
        vertexHeightFunction: HeightFunction?
    ) -> KGEOGeometry {
        var smoothVertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var smoothIndices: [UInt32] = []

        let baseVertices = vertexData.map { SIMD3<Float>($0[0], $0[1], $0[2]) }

        for vertex in baseVertices {
            let normal = normalize(vertex)
            let position = normal * radius
            smoothVertices.append((
                position: position,
                normal: normal,
                texCoord: .zero
            ))
        }

        for triangle in indexData {
            smoothIndices.append(UInt32(triangle[0]))
            smoothIndices.append(UInt32(triangle[1]))
            smoothIndices.append(UInt32(triangle[2]))
        }

        if subdivisions > 0 {
            var subdividedVertices = smoothVertices
            var subdividedIndices: [UInt32] = []

            for _ in 0..<subdivisions {
                var middlePointCache: [String: UInt32] = [:]

                for i in stride(from: 0, to: smoothIndices.count, by: 3) {
                    let v1 = smoothIndices[i]
                    let v2 = smoothIndices[i + 1]
                    let v3 = smoothIndices[i + 2]

                    let a = getMiddlePoint(v1, v2, &subdividedVertices, &middlePointCache, radius)
                    let b = getMiddlePoint(v2, v3, &subdividedVertices, &middlePointCache, radius)
                    let c = getMiddlePoint(v3, v1, &subdividedVertices, &middlePointCache, radius)

                    subdividedIndices += [v1, a, c]
                    subdividedIndices += [v2, b, a]
                    subdividedIndices += [v3, c, b]
                    subdividedIndices += [a, b, c]
                }

                smoothIndices = subdividedIndices
                subdividedIndices = []
            }

            smoothVertices = subdividedVertices
        }

        if let heightFunc = vertexHeightFunction {
            let positions = smoothVertices.map { $0.position }
            smoothVertices = heightFunc(positions)
        }

        var flatVertices: [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)] = []
        var flatIndices: [UInt32] = []

        for i in stride(from: 0, to: smoothIndices.count, by: 3) {
            let i1 = Int(smoothIndices[i])
            let i2 = Int(smoothIndices[i + 1])
            let i3 = Int(smoothIndices[i + 2])

            let v1 = smoothVertices[i1].position
            let v2 = smoothVertices[i2].position
            let v3 = smoothVertices[i3].position

            let edge1 = v2 - v1
            let edge2 = v3 - v1
            var faceNormal = normalize(cross(edge1, edge2))

            if inwardNormals {
                faceNormal = -faceNormal
            }

            let startIndex = UInt32(flatVertices.count)

            flatVertices.append((
                position: v1,
                normal: faceNormal,
                texCoord: smoothVertices[i1].texCoord
            ))

            flatVertices.append((
                position: v2,
                normal: faceNormal,
                texCoord: smoothVertices[i2].texCoord
            ))

            flatVertices.append((
                position: v3,
                normal: faceNormal,
                texCoord: smoothVertices[i3].texCoord
            ))

            flatIndices.append(startIndex)
            if inwardNormals {
                flatIndices.append(startIndex + 2)
                flatIndices.append(startIndex + 1)
            } else {
                flatIndices.append(startIndex + 1)
                flatIndices.append(startIndex + 2)
            }
        }

        return KGEOGeometry(
            vertices: flatVertices,
            indices: flatIndices)
    }

    private static func getMiddlePoint(
        _ p1: UInt32,
        _ p2: UInt32,
        _ vertices: inout [(position: SIMD3<Float>, normal: SIMD3<Float>, texCoord: SIMD2<Float>?)],
        _ cache: inout [String: UInt32],
        _ radius: Float
    ) -> UInt32 {
        let smallerIndex = min(p1, p2)
        let greaterIndex = max(p1, p2)
        let key = "\(smallerIndex)-\(greaterIndex)"

        if let cached = cache[key] {
            return cached
        }

        let point1 = vertices[Int(p1)].position
        let point2 = vertices[Int(p2)].position

        let middle = (point1 + point2) * 0.5

        let normal = normalize(middle)
        let position = normal * radius

        let newIndex = UInt32(vertices.count)
        vertices.append((position: position, normal: normal, texCoord: .zero))

        cache[key] = newIndex

        return newIndex
    }
}
