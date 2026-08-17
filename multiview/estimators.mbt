///|
pub(all) struct Affine2D {
  a00 : Double
  a01 : Double
  a02 : Double
  a10 : Double
  a11 : Double
  a12 : Double
} derive(Debug, Eq)

///|
pub fn Affine2D::identity() -> Affine2D {
  { a00: 1.0, a01: 0.0, a02: 0.0, a10: 0.0, a11: 1.0, a12: 0.0 }
}

///|
pub fn Affine2D::apply(a : Affine2D, p : @core.Point2) -> @core.Point2 {
  @core.Point2::new(
    x=a.a00 * p.x + a.a01 * p.y + a.a02,
    y=a.a10 * p.x + a.a11 * p.y + a.a12,
  )
}

///|
pub fn Affine2D::determinant(a : Affine2D) -> Double {
  a.a00 * a.a11 - a.a01 * a.a10
}

///|
pub fn Affine2D::inverse(a : Affine2D) -> Affine2D raise @core.GeometryError {
  let d = a.determinant()
  if @core.abs(d) <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput("affine transform is singular")
  }
  let inv = 1.0 / d
  {
    a00: a.a11 * inv,
    a01: -a.a01 * inv,
    a02: (a.a01 * a.a12 - a.a11 * a.a02) * inv,
    a10: -a.a10 * inv,
    a11: a.a00 * inv,
    a12: (a.a10 * a.a02 - a.a00 * a.a12) * inv,
  }
}

///|
pub fn estimate_affine(
  src : ArrayView[@core.Point2],
  dst : ArrayView[@core.Point2],
) -> Affine2D raise @core.GeometryError {
  if src.length() != dst.length() || src.length() < 3 {
    raise @core.GeometryError::NotEnoughPoints(
      "affine estimation needs three pairs",
    )
  }
  let source_center = @core.mean_point2(src)
  let target_center = @core.mean_point2(dst)
  let mut xx = 0.0
  let mut xy = 0.0
  let mut yy = 0.0
  let mut ux = 0.0
  let mut uy = 0.0
  let mut vx = 0.0
  let mut vy = 0.0
  for i in 0..<src.length() {
    let s = src[i].minus(source_center)
    let d = dst[i].minus(target_center)
    xx += s.x * s.x
    xy += s.x * s.y
    yy += s.y * s.y
    ux += d.x * s.x
    uy += d.x * s.y
    vx += d.y * s.x
    vy += d.y * s.y
  }
  let det = xx * yy - xy * xy
  if @core.abs(det) <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput("source points are collinear")
  }
  let inv = 1.0 / det
  let a00 = (ux * yy - uy * xy) * inv
  let a01 = (uy * xx - ux * xy) * inv
  let a10 = (vx * yy - vy * xy) * inv
  let a11 = (vy * xx - vx * xy) * inv
  {
    a00,
    a01,
    a02: target_center.x - a00 * source_center.x - a01 * source_center.y,
    a10,
    a11,
    a12: target_center.y - a10 * source_center.x - a11 * source_center.y,
  }
}

///|
pub fn affine_reprojection_errors(
  a : Affine2D,
  src : ArrayView[@core.Point2],
  dst : ArrayView[@core.Point2],
) -> Array[Double] raise @core.GeometryError {
  if src.length() != dst.length() {
    raise @core.GeometryError::DegenerateInput(
      "affine errors need paired points",
    )
  }
  let result : Array[Double] = []
  for i in 0..<src.length() {
    result.push(a.apply(src[i]).minus(dst[i]).norm())
  }
  result
}

///|
pub fn normalize_homogeneous(
  v : @core.Vec3,
) -> @core.Vec3 raise @core.GeometryError {
  if @core.abs(v.z) <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput(
      "homogeneous vector has zero scale",
    )
  }
  v.scale(1.0 / v.z)
}

///|
pub fn bearing_angle(
  a : @core.Point2,
  b : @core.Point2,
) -> Double raise @core.GeometryError {
  let va = @core.Vec3::new(x=a.x, y=a.y, z=1.0)
  let vb = @core.Vec3::new(x=b.x, y=b.y, z=1.0)
  @core.angle_between(va, vb)
}

///|
pub fn parallax_degrees(a : @core.Ray3, b : @core.Ray3) -> Double {
  triangulation_angle(a, b) * 57.29577951308232
}

///|
pub fn median_parallax(
  rays_left : ArrayView[@core.Ray3],
  rays_right : ArrayView[@core.Ray3],
) -> Double raise @core.GeometryError {
  if rays_left.length() != rays_right.length() || rays_left.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints("parallax needs paired rays")
  }
  let values : Array[Double] = []
  for i in 0..<rays_left.length() {
    values.push(parallax_degrees(rays_left[i], rays_right[i]))
  }
  @core.median(values)
}

///|
pub fn epipolar_inlier_mask(
  f : FundamentalMatrix,
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
  threshold~ : Double,
) -> Array[Bool] raise @core.GeometryError {
  if threshold <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "epipolar threshold must be positive",
    )
  }
  let values : Array[Bool] = []
  for i in 0..<left.length() {
    values.push(sampson_error(f, left[i], right[i]).sqrt() <= threshold)
  }
  values
}

///|
pub fn homography_inlier_mask(
  h : Homography,
  src : ArrayView[@core.Point2],
  dst : ArrayView[@core.Point2],
  threshold~ : Double,
) -> Array[Bool] raise @core.GeometryError {
  if src.length() != dst.length() {
    raise @core.GeometryError::DegenerateInput(
      "homography mask needs paired points",
    )
  }
  let values : Array[Bool] = []
  for i in 0..<src.length() {
    values.push(homography_reprojection_error(h, src[i], dst[i]) <= threshold)
  }
  values
}

///|
pub fn count_inliers(values : ArrayView[Bool]) -> Int {
  let mut result = 0
  for value in values {
    if value {
      result += 1
    }
  }
  result
}
