///|
pub fn enforce_positive_depth(
  points : ArrayView[@core.Point3],
) -> Array[@core.Point3] {
  let result : Array[@core.Point3] = []
  for p in points {
    if p.z > 0.0 {
      result.push(p)
    }
  }
  result
}

///|
pub fn depth_clamp(
  point : @core.Point3,
  minimum~ : Double,
  maximum~ : Double,
) -> @core.Point3 raise @core.GeometryError {
  if minimum <= 0.0 || maximum < minimum {
    raise @core.GeometryError::DegenerateInput(
      "depth clamp interval is invalid",
    )
  }
  @core.Point3::new(
    x=point.x,
    y=point.y,
    z=@core.clamp(point.z, lo=minimum, hi=maximum),
  )
}

///|
pub fn normalize_bearing(
  point : @core.Point2,
) -> @core.Vec3 raise @core.GeometryError {
  @core.Vec3::new(x=point.x, y=point.y, z=1.0).normalize()
}

///|
pub fn bearing_residual(
  a : @core.Vec3,
  b : @core.Vec3,
) -> Double raise @core.GeometryError {
  @core.angle_between(a, b)
}

///|
pub fn angular_residuals(
  a : ArrayView[@core.Vec3],
  b : ArrayView[@core.Vec3],
) -> Array[Double] raise @core.GeometryError {
  if a.length() != b.length() {
    raise @core.GeometryError::DegenerateInput("bearing arrays differ")
  }
  let result : Array[Double] = []
  for i in 0..<a.length() {
    result.push(bearing_residual(a[i], b[i]))
  }
  result
}

///|
pub fn angular_rms(
  a : ArrayView[@core.Vec3],
  b : ArrayView[@core.Vec3],
) -> Double raise @core.GeometryError {
  let errors = angular_residuals(a, b)
  @core.rms_error(errors)
}

///|
pub fn line_point_residual(
  line : @core.Vec3,
  point : @core.Point2,
) -> Double raise @core.GeometryError {
  let normal = @core.Vec2::new(x=line.x, y=line.y).normalize()
  @core.abs(normal.x * point.x + normal.y * point.y + line.z)
}

///|
pub fn symmetric_epipolar_residual(
  f : FundamentalMatrix,
  left : @core.Point2,
  right : @core.Point2,
) -> Double raise @core.GeometryError {
  let forward = epipolar_distance(f, left, right)
  let backward = point_line_distance(
    f.matrix.transpose().mul_vec3(right.to_homogeneous()),
    left,
  )
  (forward + backward) / 2.0
}

///|
pub fn essential_scale(f : FundamentalMatrix) -> Double {
  f.matrix.frobenius_norm()
}

///|
pub fn normalize_fundamental(
  f : FundamentalMatrix,
) -> FundamentalMatrix raise @core.GeometryError {
  let scale = f.matrix.frobenius_norm()
  if scale <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput("fundamental matrix is zero")
  }
  FundamentalMatrix::new(matrix=f.matrix.scale(1.0 / scale))
}

///|
pub fn normalize_homography(
  h : Homography,
) -> Homography raise @core.GeometryError {
  let scale = h.matrix.m22
  if @core.abs(scale) <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput("homography scale is zero")
  }
  Homography::new(matrix=h.matrix.scale(1.0 / scale))
}
