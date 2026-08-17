///|
pub fn dot_array(
  a : ArrayView[Double],
  b : ArrayView[Double],
) -> Double raise GeometryError {
  if a.length() != b.length() {
    raise GeometryError::DegenerateInput("dot arrays need equal length")
  }
  let mut sum = 0.0
  for i in 0..<a.length() {
    sum += a[i] * b[i]
  }
  sum
}

///|
pub fn squared_norm_array(values : ArrayView[Double]) -> Double {
  dot_array(values, values) catch {
    _ => 0.0
  }
}

///|
pub fn scale_array(values : ArrayView[Double], scale : Double) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    result.push(value * scale)
  }
  result
}

///|
pub fn add_arrays(
  a : ArrayView[Double],
  b : ArrayView[Double],
) -> Array[Double] raise GeometryError {
  if a.length() != b.length() {
    raise GeometryError::DegenerateInput("array addition needs equal length")
  }
  let result : Array[Double] = []
  for i in 0..<a.length() {
    result.push(a[i] + b[i])
  }
  result
}

///|
pub fn linear_interpolate(a : Double, b : Double, amount : Double) -> Double {
  a + (b - a) * amount
}

///|
pub fn point2_lerp(a : Point2, b : Point2, amount : Double) -> Point2 {
  Point2::new(
    x=linear_interpolate(a.x, b.x, amount),
    y=linear_interpolate(a.y, b.y, amount),
  )
}

///|
pub fn point3_lerp(a : Point3, b : Point3, amount : Double) -> Point3 {
  Point3::new(
    x=linear_interpolate(a.x, b.x, amount),
    y=linear_interpolate(a.y, b.y, amount),
    z=linear_interpolate(a.z, b.z, amount),
  )
}

///|
pub fn finite_difference(
  f : (Double) -> Double,
  x : Double,
  epsilon? : Double = 0.000001,
) -> Double {
  (f(x + epsilon) - f(x - epsilon)) / (2.0 * epsilon)
}

///|
pub fn mean_point2(points : ArrayView[Point2]) -> Point2 raise GeometryError {
  if points.length() == 0 {
    raise GeometryError::NotEnoughPoints("mean point needs observations")
  }
  let mut x = 0.0
  let mut y = 0.0
  for p in points {
    x += p.x
    y += p.y
  }
  Point2::new(
    x=x / Double::from_int(points.length()),
    y=y / Double::from_int(points.length()),
  )
}

///|
pub fn covariance_2d(points : ArrayView[Point2]) -> Mat3 raise GeometryError {
  let center = mean_point2(points)
  if points.length() < 2 {
    raise GeometryError::NotEnoughPoints("covariance needs two points")
  }
  let mut xx = 0.0
  let mut xy = 0.0
  let mut yy = 0.0
  for p in points {
    let dx = p.x - center.x
    let dy = p.y - center.y
    xx += dx * dx
    xy += dx * dy
    yy += dy * dy
  }
  let scale = 1.0 / Double::from_int(points.length() - 1)
  mat3_from_rows(
    (xx * scale, xy * scale, 0.0),
    (xy * scale, yy * scale, 0.0),
    (0.0, 0.0, 1.0),
  )
}

///|
pub fn normalize_weights(
  weights : ArrayView[Double],
) -> Array[Double] raise GeometryError {
  let total = mean(weights) * Double::from_int(weights.length())
  if total <= 0.0 {
    raise GeometryError::DegenerateInput("weights must have positive sum")
  }
  let result : Array[Double] = []
  for weight in weights {
    result.push(weight / total)
  }
  result
}

///|
pub fn weighted_mean(
  values : ArrayView[Double],
  weights : ArrayView[Double],
) -> Double raise GeometryError {
  if values.length() != weights.length() || values.length() == 0 {
    raise GeometryError::NotEnoughPoints("weighted mean needs paired values")
  }
  let mut sum = 0.0
  let mut total = 0.0
  for i in 0..<values.length() {
    sum += values[i] * weights[i]
    total += weights[i]
  }
  if total <= 0.0 {
    raise GeometryError::DegenerateInput("weights must have positive sum")
  }
  sum / total
}
