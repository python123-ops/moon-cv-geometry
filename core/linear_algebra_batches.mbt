///|
/// Apply a 3x3 matrix to a batch of vectors.
pub fn mat3_apply_batch(
  matrix : Mat3,
  vectors : ArrayView[Vec3],
) -> Array[Vec3] {
  let result : Array[Vec3] = []
  for vector in vectors {
    result.push(matrix.mul_vec3(vector))
  }
  result
}

///|
pub fn mat3_apply_points(
  matrix : Mat3,
  points : ArrayView[Point3],
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    let vector = matrix.mul_vec3(point.to_vec())
    result.push(Point3::new(x=vector.x, y=vector.y, z=vector.z))
  }
  result
}

///|
pub fn batch_norms(vectors : ArrayView[Vec3]) -> Array[Double] {
  let result : Array[Double] = []
  for vector in vectors {
    result.push(vector.norm())
  }
  result
}

///|
pub fn batch_dot(
  left : ArrayView[Vec3],
  right : ArrayView[Vec3],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = left.length().min(right.length())
  for i in 0..<count {
    result.push(left[i].dot(right[i]))
  }
  result
}

///|
pub fn batch_cross(
  left : ArrayView[Vec3],
  right : ArrayView[Vec3],
) -> Array[Vec3] {
  let result : Array[Vec3] = []
  let count = left.length().min(right.length())
  for i in 0..<count {
    result.push(left[i].cross(right[i]))
  }
  result
}

///|
pub fn vector_sum(vectors : ArrayView[Vec3]) -> Vec3 {
  let mut result = Vec3::new(x=0.0, y=0.0, z=0.0)
  for vector in vectors {
    result = result.add(vector)
  }
  result
}

///|
pub fn vector_mean(vectors : ArrayView[Vec3]) -> Vec3 {
  if vectors.length() == 0 {
    Vec3::new(x=0.0, y=0.0, z=0.0)
  } else {
    vector_sum(vectors).scale(1.0 / vectors.length().to_double())
  }
}

///|
pub fn vector_covariance_trace(vectors : ArrayView[Vec3]) -> Double {
  if vectors.length() == 0 {
    return 0.0
  }
  let center = vector_mean(vectors)
  let mut result = 0.0
  for vector in vectors {
    let delta = vector.sub(center)
    result += delta.norm2()
  }
  result / vectors.length().to_double()
}

///|
pub fn outer_products(vectors : ArrayView[Vec3]) -> Array[Mat3] {
  let result : Array[Mat3] = []
  for vector in vectors {
    result.push(outer_product(vector, vector))
  }
  result
}

///|
pub fn mat3_frobenius_batch(matrices : ArrayView[Mat3]) -> Array[Double] {
  let result : Array[Double] = []
  for matrix in matrices {
    result.push(matrix.frobenius_norm())
  }
  result
}

///|
pub fn mat3_determinants(matrices : ArrayView[Mat3]) -> Array[Double] {
  let result : Array[Double] = []
  for matrix in matrices {
    result.push(matrix.det())
  }
  result
}

///|
pub fn mat3_transpose_batch(matrices : ArrayView[Mat3]) -> Array[Mat3] {
  let result : Array[Mat3] = []
  for matrix in matrices {
    result.push(matrix.transpose())
  }
  result
}

///|
pub fn mat3_add_batch(
  left : ArrayView[Mat3],
  right : ArrayView[Mat3],
) -> Array[Mat3] {
  let result : Array[Mat3] = []
  let count = left.length().min(right.length())
  for i in 0..<count {
    result.push(left[i].add(right[i]))
  }
  result
}

///|
pub fn mat3_scale_batch(
  matrices : ArrayView[Mat3],
  scale : Double,
) -> Array[Mat3] {
  let result : Array[Mat3] = []
  for matrix in matrices {
    result.push(matrix.scale(scale))
  }
  result
}

///|
pub fn normalize_vectors(
  vectors : ArrayView[Vec3],
) -> Array[Vec3] raise GeometryError {
  let result : Array[Vec3] = []
  for vector in vectors {
    result.push(vector.normalize())
  }
  result
}

///|
pub fn orthogonal_projection_batch(
  vectors : ArrayView[Vec3],
  axis : Vec3,
) -> Array[Vec3] raise GeometryError {
  let result : Array[Vec3] = []
  let unit = axis.normalize()
  for vector in vectors {
    result.push(vector.sub(unit.scale(vector.dot(unit))))
  }
  result
}

///|
pub fn pairwise_distances(points : ArrayView[Point3]) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<points.length() {
    for j in (i + 1)..<points.length() {
      result.push(points[i].minus(points[j]).norm())
    }
  }
  result
}

///|
pub fn nearest_neighbor_distances(points : ArrayView[Point3]) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<points.length() {
    let mut best = 0.0
    let mut initialized = false
    for j in 0..<points.length() {
      if i != j {
        let distance = points[i].minus(points[j]).norm()
        if !initialized || distance < best {
          best = distance
          initialized = true
        }
      }
    }
    if initialized {
      result.push(best)
    }
  }
  result
}
