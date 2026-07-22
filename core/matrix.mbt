///|
pub fn mat3_from_rows(
  r0 : (Double, Double, Double),
  r1 : (Double, Double, Double),
  r2 : (Double, Double, Double),
) -> Mat3 {
  let (m00, m01, m02) = r0
  let (m10, m11, m12) = r1
  let (m20, m21, m22) = r2
  { m00, m01, m02, m10, m11, m12, m20, m21, m22 }
}

///|
pub fn mat34_from_rows(
  r0 : (Double, Double, Double, Double),
  r1 : (Double, Double, Double, Double),
  r2 : (Double, Double, Double, Double),
) -> Mat34 {
  let (m00, m01, m02, m03) = r0
  let (m10, m11, m12, m13) = r1
  let (m20, m21, m22, m23) = r2
  { m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23 }
}

///|
pub fn identity3() -> Mat3 {
  mat3_from_rows((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0))
}

///|
pub fn Mat3::mul_vec3(m : Mat3, v : Vec3) -> Vec3 {
  Vec3::new(
    x=m.m00 * v.x + m.m01 * v.y + m.m02 * v.z,
    y=m.m10 * v.x + m.m11 * v.y + m.m12 * v.z,
    z=m.m20 * v.x + m.m21 * v.y + m.m22 * v.z,
  )
}

///|
pub fn Mat3::mul(a : Mat3, b : Mat3) -> Mat3 {
  mat3_from_rows(
    (
      a.m00 * b.m00 + a.m01 * b.m10 + a.m02 * b.m20,
      a.m00 * b.m01 + a.m01 * b.m11 + a.m02 * b.m21,
      a.m00 * b.m02 + a.m01 * b.m12 + a.m02 * b.m22,
    ),
    (
      a.m10 * b.m00 + a.m11 * b.m10 + a.m12 * b.m20,
      a.m10 * b.m01 + a.m11 * b.m11 + a.m12 * b.m21,
      a.m10 * b.m02 + a.m11 * b.m12 + a.m12 * b.m22,
    ),
    (
      a.m20 * b.m00 + a.m21 * b.m10 + a.m22 * b.m20,
      a.m20 * b.m01 + a.m21 * b.m11 + a.m22 * b.m21,
      a.m20 * b.m02 + a.m21 * b.m12 + a.m22 * b.m22,
    ),
  )
}

///|
pub fn Mat3::transpose(m : Mat3) -> Mat3 {
  mat3_from_rows(
    (m.m00, m.m10, m.m20),
    (m.m01, m.m11, m.m21),
    (m.m02, m.m12, m.m22),
  )
}

///|
pub fn Mat3::det(m : Mat3) -> Double {
  m.m00 * (m.m11 * m.m22 - m.m12 * m.m21) -
  m.m01 * (m.m10 * m.m22 - m.m12 * m.m20) +
  m.m02 * (m.m10 * m.m21 - m.m11 * m.m20)
}

///|
pub fn Mat3::inverse(m : Mat3) -> Mat3 raise GeometryError {
  let d = m.det()
  if abs(d) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("Mat3 is singular")
  }
  let inv = 1.0 / d
  mat3_from_rows(
    (
      (m.m11 * m.m22 - m.m12 * m.m21) * inv,
      (m.m02 * m.m21 - m.m01 * m.m22) * inv,
      (m.m01 * m.m12 - m.m02 * m.m11) * inv,
    ),
    (
      (m.m12 * m.m20 - m.m10 * m.m22) * inv,
      (m.m00 * m.m22 - m.m02 * m.m20) * inv,
      (m.m02 * m.m10 - m.m00 * m.m12) * inv,
    ),
    (
      (m.m10 * m.m21 - m.m11 * m.m20) * inv,
      (m.m01 * m.m20 - m.m00 * m.m21) * inv,
      (m.m00 * m.m11 - m.m01 * m.m10) * inv,
    ),
  )
}

///|
pub fn Mat34::transform_point(m : Mat34, p : Point3) -> Point3 {
  Point3::new(
    x=m.m00 * p.x + m.m01 * p.y + m.m02 * p.z + m.m03,
    y=m.m10 * p.x + m.m11 * p.y + m.m12 * p.z + m.m13,
    z=m.m20 * p.x + m.m21 * p.y + m.m22 * p.z + m.m23,
  )
}
