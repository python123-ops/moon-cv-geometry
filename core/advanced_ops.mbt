///|
pub fn Mat3::frobenius_norm(m : Mat3) -> Double {
  (m.m00 * m.m00 +
  m.m01 * m.m01 +
  m.m02 * m.m02 +
  m.m10 * m.m10 +
  m.m11 * m.m11 +
  m.m12 * m.m12 +
  m.m20 * m.m20 +
  m.m21 * m.m21 +
  m.m22 * m.m22).sqrt()
}

///|
pub fn Mat3::scale(m : Mat3, value : Double) -> Mat3 {
  mat3_from_rows(
    (m.m00 * value, m.m01 * value, m.m02 * value),
    (m.m10 * value, m.m11 * value, m.m12 * value),
    (m.m20 * value, m.m21 * value, m.m22 * value),
  )
}

///|
pub fn Mat3::add(a : Mat3, b : Mat3) -> Mat3 {
  mat3_from_rows(
    (a.m00 + b.m00, a.m01 + b.m01, a.m02 + b.m02),
    (a.m10 + b.m10, a.m11 + b.m11, a.m12 + b.m12),
    (a.m20 + b.m20, a.m21 + b.m21, a.m22 + b.m22),
  )
}

///|
pub fn Mat3::sub(a : Mat3, b : Mat3) -> Mat3 {
  mat3_from_rows(
    (a.m00 - b.m00, a.m01 - b.m01, a.m02 - b.m02),
    (a.m10 - b.m10, a.m11 - b.m11, a.m12 - b.m12),
    (a.m20 - b.m20, a.m21 - b.m21, a.m22 - b.m22),
  )
}

///|
pub fn outer_product(a : Vec3, b : Vec3) -> Mat3 {
  mat3_from_rows(
    (a.x * b.x, a.x * b.y, a.x * b.z),
    (a.y * b.x, a.y * b.y, a.y * b.z),
    (a.z * b.x, a.z * b.y, a.z * b.z),
  )
}

///|
pub fn skew_symmetric(v : Vec3) -> Mat3 {
  mat3_from_rows((0.0, -v.z, v.y), (v.z, 0.0, -v.x), (-v.y, v.x, 0.0))
}

///|
pub fn Mat3::is_orthonormal(m : Mat3, tolerance? : Double = 0.000001) -> Bool {
  let product = m.mul(m.transpose())
  (product.m00 - 1.0).abs() <= tolerance &&
  (product.m11 - 1.0).abs() <= tolerance &&
  (product.m22 - 1.0).abs() <= tolerance &&
  product.m01.abs() <= tolerance &&
  product.m02.abs() <= tolerance &&
  product.m10.abs() <= tolerance &&
  product.m12.abs() <= tolerance &&
  product.m20.abs() <= tolerance &&
  product.m21.abs() <= tolerance
}

///|
pub fn orthogonal_component(v : Vec3, axis : Vec3) -> Vec3 raise GeometryError {
  let unit = axis.normalize()
  v.sub(unit.scale(v.dot(unit)))
}

///|
pub fn project_vector(v : Vec3, axis : Vec3) -> Vec3 raise GeometryError {
  let unit = axis.normalize()
  unit.scale(v.dot(unit))
}

///|
pub fn lerp_vec3(a : Vec3, b : Vec3, amount : Double) -> Vec3 {
  Vec3::new(
    x=linear_interpolate(a.x, b.x, amount),
    y=linear_interpolate(a.y, b.y, amount),
    z=linear_interpolate(a.z, b.z, amount),
  )
}

///|
pub fn centroid3(points : ArrayView[Point3]) -> Point3 raise GeometryError {
  if points.length() == 0 {
    raise GeometryError::NotEnoughPoints("centroid needs points")
  }
  let mut x = 0.0
  let mut y = 0.0
  let mut z = 0.0
  for p in points {
    x += p.x
    y += p.y
    z += p.z
  }
  let n = Double::from_int(points.length())
  Point3::new(x=x / n, y=y / n, z=z / n)
}

///|
pub fn bounding_radius(points : ArrayView[Point3], center : Point3) -> Double {
  let mut r = 0.0
  for p in points {
    let d = distance3(p, center)
    if d > r {
      r = d
    }
  }
  r
}

///|
pub fn finite_point2(p : Point2) -> Bool {
  p.x == p.x && p.y == p.y
}

///|
pub fn finite_point3(p : Point3) -> Bool {
  p.x == p.x && p.y == p.y && p.z == p.z
}

///|
pub fn safe_divide(
  numerator : Double,
  denominator : Double,
) -> Double raise GeometryError {
  if abs(denominator) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("division denominator is zero")
  }
  numerator / denominator
}

///|
pub fn relative_error(actual : Double, expected : Double) -> Double {
  let scale = if abs(expected) > 1.0 { abs(expected) } else { 1.0 }
  abs(actual - expected) / scale
}

///|
pub fn all_close(
  a : ArrayView[Double],
  b : ArrayView[Double],
  tolerance? : Double = 0.000001,
) -> Bool {
  if a.length() != b.length() {
    false
  } else {
    let mut result = true
    for i in 0..<a.length() {
      if abs(a[i] - b[i]) > tolerance {
        result = false
      }
    }
    result
  }
}
