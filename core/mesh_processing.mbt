///|
/// Compute unique undirected edges from a triangle index buffer.
pub fn unique_triangle_edges(
  triangles : ArrayView[(Int, Int, Int)],
) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for triangle in triangles {
    let (a, b, c) = triangle
    let e0 = if a < b { (a, b) } else { (b, a) }
    let e1 = if b < c { (b, c) } else { (c, b) }
    let e2 = if c < a { (c, a) } else { (a, c) }
    if !result.contains(e0) {
      result.push(e0)
    }
    if !result.contains(e1) {
      result.push(e1)
    }
    if !result.contains(e2) {
      result.push(e2)
    }
  }
  result
}

///|
pub fn triangle_area3(a : Point3, b : Point3, c : Point3) -> Double {
  b.minus(a).cross(c.minus(a)).norm() / 2.0
}

///|
pub fn triangle_centroid3(a : Point3, b : Point3, c : Point3) -> Point3 {
  Point3::new(
    x=(a.x + b.x + c.x) / 3.0,
    y=(a.y + b.y + c.y) / 3.0,
    z=(a.z + b.z + c.z) / 3.0,
  )
}

///|
pub fn mesh_surface_area(
  vertices : ArrayView[Point3],
  triangles : ArrayView[(Int, Int, Int)],
) -> Double {
  let mut area = 0.0
  for triangle in triangles {
    let (a, b, c) = triangle
    if a >= 0 &&
      b >= 0 &&
      c >= 0 &&
      a < vertices.length() &&
      b < vertices.length() &&
      c < vertices.length() {
      area += triangle_area3(vertices[a], vertices[b], vertices[c])
    }
  }
  area
}

///|
pub fn mesh_centroid(
  vertices : ArrayView[Point3],
) -> Point3 raise GeometryError {
  centroid3(vertices)
}

///|
pub fn translate_mesh(
  vertices : ArrayView[Point3],
  translation : Vec3,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for vertex in vertices {
    result.push(vertex.translate(translation))
  }
  result
}

///|
pub fn scale_mesh(
  vertices : ArrayView[Point3],
  scale : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for vertex in vertices {
    result.push(
      Point3::new(x=vertex.x * scale, y=vertex.y * scale, z=vertex.z * scale),
    )
  }
  result
}

///|
pub fn mesh_diagonal(
  vertices : ArrayView[Point3],
) -> Double raise GeometryError {
  let box = PointCloud::from_points(vertices).bounds()
  box.max.minus(box.min).norm()
}
