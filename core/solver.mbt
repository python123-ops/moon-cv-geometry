///|
pub fn solve_2x2(
  a00~ : Double,
  a01~ : Double,
  a10~ : Double,
  a11~ : Double,
  b0~ : Double,
  b1~ : Double,
) -> Vec2 raise GeometryError {
  let det = a00 * a11 - a01 * a10
  if abs(det) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("2x2 system is singular")
  }
  let inv = 1.0 / det
  Vec2::new(x=(a11 * b0 - a01 * b1) * inv, y=(a00 * b1 - a10 * b0) * inv)
}

///|
pub fn solve_3x3(a : Mat3, b : Vec3) -> Vec3 raise GeometryError {
  let det = a.det()
  if abs(det) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("3x3 system is singular")
  }
  let inv = 1.0 / det
  let x = Mat3::det(
      mat3_from_rows(
        (b.x, a.m01, a.m02),
        (b.y, a.m11, a.m12),
        (b.z, a.m21, a.m22),
      ),
    ) *
    inv
  let y = Mat3::det(
      mat3_from_rows(
        (a.m00, b.x, a.m02),
        (a.m10, b.y, a.m12),
        (a.m20, b.z, a.m22),
      ),
    ) *
    inv
  let z = Mat3::det(
      mat3_from_rows(
        (a.m00, a.m01, b.x),
        (a.m10, a.m11, b.y),
        (a.m20, a.m21, b.z),
      ),
    ) *
    inv
  Vec3::new(x~, y~, z~)
}

///|
pub fn solve_symmetric_3x3(a : Mat3, b : Vec3) -> Vec3 raise GeometryError {
  if abs(a.m01 - a.m10) > 0.000001 ||
    abs(a.m02 - a.m20) > 0.000001 ||
    abs(a.m12 - a.m21) > 0.000001 {
    raise GeometryError::DegenerateInput("matrix is not symmetric")
  }
  solve_3x3(a, b)
}

///|
pub fn normal_equation_2d(
  x : ArrayView[Point2],
  values : ArrayView[Double],
) -> Vec2 raise GeometryError {
  if x.length() != values.length() || x.length() < 2 {
    raise GeometryError::NotEnoughPoints("normal equation needs paired samples")
  }
  let mut xx = 0.0
  let mut xy = 0.0
  let mut yy = 0.0
  let mut bx = 0.0
  let mut by = 0.0
  for i in 0..<x.length() {
    xx += x[i].x * x[i].x
    xy += x[i].x * x[i].y
    yy += x[i].y * x[i].y
    bx += x[i].x * values[i]
    by += x[i].y * values[i]
  }
  solve_2x2(a00=xx, a01=xy, a10=xy, a11=yy, b0=bx, b1=by)
}

///|
pub fn rms_error(errors : ArrayView[Double]) -> Double raise GeometryError {
  if errors.length() == 0 {
    raise GeometryError::NotEnoughPoints("RMS needs errors")
  }
  let mut sum = 0.0
  for value in errors {
    sum += value * value
  }
  (sum / Double::from_int(errors.length())).sqrt()
}

///|
pub fn max_error(errors : ArrayView[Double]) -> Double raise GeometryError {
  if errors.length() == 0 {
    raise GeometryError::NotEnoughPoints("maximum needs errors")
  }
  let mut result = abs(errors[0])
  for value in errors {
    if abs(value) > result {
      result = abs(value)
    }
  }
  result
}

///|
pub fn residual_statistics(
  errors : ArrayView[Double],
) -> (Double, Double, Double) raise GeometryError {
  (mean(errors), rms_error(errors), max_error(errors))
}

///|
pub fn finite_difference_vec(
  f : (Double) -> Vec3,
  x : Double,
  epsilon? : Double = 0.000001,
) -> Vec3 {
  let a = f(x - epsilon)
  let b = f(x + epsilon)
  b.sub(a).scale(1.0 / (2.0 * epsilon))
}

///|
pub fn damped_update(
  current : Double,
  gradient : Double,
  damping? : Double = 0.001,
) -> Double {
  current - gradient / (1.0 + damping)
}

///|
pub fn safe_rms(errors : ArrayView[Double]) -> Double {
  rms_error(errors) catch {
    _ => 0.0
  }
}
