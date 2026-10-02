///|
pub(all) struct Mat4 {
  m00 : Double
  m01 : Double
  m02 : Double
  m03 : Double
  m10 : Double
  m11 : Double
  m12 : Double
  m13 : Double
  m20 : Double
  m21 : Double
  m22 : Double
  m23 : Double
  m30 : Double
  m31 : Double
  m32 : Double
  m33 : Double
} derive(Debug, Eq)

///|
pub fn mat4_from_rows(
  r0 : (Double, Double, Double, Double),
  r1 : (Double, Double, Double, Double),
  r2 : (Double, Double, Double, Double),
  r3 : (Double, Double, Double, Double),
) -> Mat4 {
  let (m00, m01, m02, m03) = r0
  let (m10, m11, m12, m13) = r1
  let (m20, m21, m22, m23) = r2
  let (m30, m31, m32, m33) = r3
  {
    m00,
    m01,
    m02,
    m03,
    m10,
    m11,
    m12,
    m13,
    m20,
    m21,
    m22,
    m23,
    m30,
    m31,
    m32,
    m33,
  }
}

///|
pub fn identity4() -> Mat4 {
  mat4_from_rows(
    (1.0, 0.0, 0.0, 0.0),
    (0.0, 1.0, 0.0, 0.0),
    (0.0, 0.0, 1.0, 0.0),
    (0.0, 0.0, 0.0, 1.0),
  )
}

///|
pub fn Mat4::mul(a : Mat4, b : Mat4) -> Mat4 {
  let row = fn(r : Int, c : Int) -> Double {
    let av = [
      a.m00,
      a.m01,
      a.m02,
      a.m03,
      a.m10,
      a.m11,
      a.m12,
      a.m13,
      a.m20,
      a.m21,
      a.m22,
      a.m23,
      a.m30,
      a.m31,
      a.m32,
      a.m33,
    ]
    let bv = [
      b.m00,
      b.m01,
      b.m02,
      b.m03,
      b.m10,
      b.m11,
      b.m12,
      b.m13,
      b.m20,
      b.m21,
      b.m22,
      b.m23,
      b.m30,
      b.m31,
      b.m32,
      b.m33,
    ]
    av[r * 4] * bv[c] +
    av[r * 4 + 1] * bv[4 + c] +
    av[r * 4 + 2] * bv[8 + c] +
    av[r * 4 + 3] * bv[12 + c]
  }
  mat4_from_rows(
    (row(0, 0), row(0, 1), row(0, 2), row(0, 3)),
    (row(1, 0), row(1, 1), row(1, 2), row(1, 3)),
    (row(2, 0), row(2, 1), row(2, 2), row(2, 3)),
    (row(3, 0), row(3, 1), row(3, 2), row(3, 3)),
  )
}

///|
pub fn Mat4::transform_point(
  m : Mat4,
  p : Point3,
) -> Point3 raise GeometryError {
  let x = m.m00 * p.x + m.m01 * p.y + m.m02 * p.z + m.m03
  let y = m.m10 * p.x + m.m11 * p.y + m.m12 * p.z + m.m13
  let z = m.m20 * p.x + m.m21 * p.y + m.m22 * p.z + m.m23
  let w = m.m30 * p.x + m.m31 * p.y + m.m32 * p.z + m.m33
  if abs(w) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("Mat4 maps point to infinity")
  }
  Point3::new(x=x / w, y=y / w, z=z / w)
}

///|
pub fn Mat4::transpose(m : Mat4) -> Mat4 {
  mat4_from_rows(
    (m.m00, m.m10, m.m20, m.m30),
    (m.m01, m.m11, m.m21, m.m31),
    (m.m02, m.m12, m.m22, m.m32),
    (m.m03, m.m13, m.m23, m.m33),
  )
}

///|
pub(all) struct Quaternion {
  w : Double
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq)

///|
pub fn Quaternion::new(
  w~ : Double,
  x~ : Double,
  y~ : Double,
  z~ : Double,
) -> Quaternion {
  { w, x, y, z, }
}

///|
pub fn Quaternion::identity() -> Quaternion {
  { w: 1.0, x: 0.0, y: 0.0, z: 0.0, }
}

///|
pub fn Quaternion::norm(q : Quaternion) -> Double {
  (q.w * q.w + q.x * q.x + q.y * q.y + q.z * q.z).sqrt()
}

///|
pub fn Quaternion::normalize(q : Quaternion) -> Quaternion raise GeometryError {
  let n = q.norm()
  if n <= 0.000000000001 {
    raise GeometryError::DegenerateInput("cannot normalize a zero quaternion")
  }
  { w: q.w / n, x: q.x / n, y: q.y / n, z: q.z / n, }
}

///|
pub fn Quaternion::conjugate(q : Quaternion) -> Quaternion {
  { w: q.w, x: -q.x, y: -q.y, z: -q.z, }
}

///|
pub fn Quaternion::mul(a : Quaternion, b : Quaternion) -> Quaternion {
  {
    w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
    x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
    y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
    z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
  }
}

///|
pub fn Quaternion::rotate(q : Quaternion, v : Vec3) -> Vec3 {
  let p = Quaternion::{ w: 0.0, x: v.x, y: v.y, z: v.z, }
  let r = q.mul(p).mul(q.conjugate())
  Vec3::new(x=r.x, y=r.y, z=r.z)
}

///|
pub fn Quaternion::to_mat3(q : Quaternion) -> Mat3 {
  let xx = q.x * q.x
  let yy = q.y * q.y
  let zz = q.z * q.z
  let xy = q.x * q.y
  let xz = q.x * q.z
  let yz = q.y * q.z
  let wx = q.w * q.x
  let wy = q.w * q.y
  let wz = q.w * q.z
  mat3_from_rows(
    (1.0 - 2.0 * (yy + zz), 2.0 * (xy - wz), 2.0 * (xz + wy)),
    (2.0 * (xy + wz), 1.0 - 2.0 * (xx + zz), 2.0 * (yz - wx)),
    (2.0 * (xz - wy), 2.0 * (yz + wx), 1.0 - 2.0 * (xx + yy)),
  )
}

///|
pub fn quaternion_from_axis_angle(
  axis : Vec3,
  angle : Double,
) -> Quaternion raise GeometryError {
  let unit = axis.normalize()
  let half = angle / 2.0
  let s = @math.sin(half)
  Quaternion::new(w=@math.cos(half), x=unit.x * s, y=unit.y * s, z=unit.z * s)
}

///|
pub(all) struct RigidTransform {
  rotation : Mat3
  translation : Vec3
} derive(Debug, Eq)

///|
pub fn RigidTransform::identity() -> RigidTransform {
  { rotation: identity3(), translation: Vec3::new(x=0.0, y=0.0, z=0.0), }
}

///|
pub fn RigidTransform::new(
  rotation~ : Mat3,
  translation~ : Vec3,
) -> RigidTransform {
  { rotation, translation, }
}

///|
pub fn RigidTransform::apply(t : RigidTransform, p : Point3) -> Point3 {
  let v = t.rotation.mul_vec3(p.to_vec()).add(t.translation)
  Point3::new(x=v.x, y=v.y, z=v.z)
}

///|
pub fn RigidTransform::inverse(t : RigidTransform) -> RigidTransform {
  let r = t.rotation.transpose()
  RigidTransform::{
    rotation: r,
    translation: r.mul_vec3(t.translation).scale(-1.0),
  }
}

///|
pub fn RigidTransform::compose(
  a : RigidTransform,
  b : RigidTransform,
) -> RigidTransform {
  {
    rotation: a.rotation.mul(b.rotation),
    translation: a.rotation.mul_vec3(b.translation).add(a.translation),
  }
}

///|
pub fn median(values : ArrayView[Double]) -> Double raise GeometryError {
  if values.length() == 0 {
    raise GeometryError::NotEnoughPoints("median needs at least one value")
  }
  let sorted = values.to_owned()
  sorted.sort()
  let n = sorted.length()
  if n % 2 == 1 {
    sorted[n / 2]
  } else {
    (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
  }
}

///|
pub fn mean(values : ArrayView[Double]) -> Double raise GeometryError {
  if values.length() == 0 {
    raise GeometryError::NotEnoughPoints("mean needs at least one value")
  }
  let mut total = 0.0
  for value in values {
    total += value
  }
  total / Double::from_int(values.length())
}

///|
pub fn variance(values : ArrayView[Double]) -> Double raise GeometryError {
  let average = mean(values)
  let mut total = 0.0
  for value in values {
    let d = value - average
    total += d * d
  }
  total / Double::from_int(values.length())
}

///|
pub fn percentile(
  values : ArrayView[Double],
  fraction~ : Double,
) -> Double raise GeometryError {
  if fraction < 0.0 || fraction > 1.0 {
    raise GeometryError::DegenerateInput("percentile fraction must be in [0,1]")
  }
  if values.length() == 0 {
    raise GeometryError::NotEnoughPoints("percentile needs values")
  }
  let sorted = values.to_owned()
  sorted.sort()
  let position = fraction * Double::from_int(sorted.length() - 1)
  let lower = position.to_int()
  let upper = if lower + 1 < sorted.length() { lower + 1 } else { lower }
  sorted[lower] +
  (sorted[upper] - sorted[lower]) * (position - Double::from_int(lower))
}

///|
pub fn robust_scale(values : ArrayView[Double]) -> Double raise GeometryError {
  let center = median(values)
  let deviations : Array[Double] = []
  for value in values {
    deviations.push(abs(value - center))
  }
  median(deviations)
}

///|
pub fn clamp_unit(value : Double) -> Double {
  if value < -1.0 {
    -1.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
pub fn angle_between(a : Vec3, b : Vec3) -> Double raise GeometryError {
  let na = a.norm()
  let nb = b.norm()
  if na <= 0.000000000001 || nb <= 0.000000000001 {
    raise GeometryError::DegenerateInput("angle needs non-zero vectors")
  }
  @math.acos(clamp_unit(a.dot(b) / (na * nb)))
}
