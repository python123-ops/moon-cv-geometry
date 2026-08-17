///|
pub fn trimmed_mean(
  values : ArrayView[Double],
  trim_fraction? : Double = 0.1,
) -> Double raise GeometryError {
  if values.length() == 0 || trim_fraction < 0.0 || trim_fraction >= 0.5 {
    raise GeometryError::DegenerateInput("trim fraction is invalid")
  }
  let sorted = values.to_owned()
  sorted.sort()
  let trim = (Double::from_int(sorted.length()) * trim_fraction).to_int()
  let mut total = 0.0
  let mut count = 0
  for i in trim..<(sorted.length() - trim) {
    total += sorted[i]
    count += 1
  }
  total / Double::from_int(count)
}

///|
pub fn interquartile_range(
  values : ArrayView[Double],
) -> Double raise GeometryError {
  percentile(values, fraction=0.75) - percentile(values, fraction=0.25)
}

///|
pub fn z_score(
  value : Double,
  center : Double,
  spread : Double,
) -> Double raise GeometryError {
  if spread <= 0.0 {
    raise GeometryError::DegenerateInput("spread must be positive")
  }
  (value - center) / spread
}

///|
pub fn robust_z_scores(
  values : ArrayView[Double],
) -> Array[Double] raise GeometryError {
  let center = median(values)
  let spread = robust_scale(values) * 1.4826
  let result : Array[Double] = []
  if spread <= 0.000000000001 {
    for _ in values {
      result.push(0.0)
    }
  } else {
    for value in values {
      result.push((value - center) / spread)
    }
  }
  result
}

///|
pub fn covariance_3d(points : ArrayView[Point3]) -> Mat4 raise GeometryError {
  let center = centroid3(points)
  if points.length() < 2 {
    raise GeometryError::NotEnoughPoints("3D covariance needs two points")
  }
  let mut xx = 0.0
  let mut xy = 0.0
  let mut xz = 0.0
  let mut yy = 0.0
  let mut yz = 0.0
  let mut zz = 0.0
  for p in points {
    let d = p.minus(center)
    xx += d.x * d.x
    xy += d.x * d.y
    xz += d.x * d.z
    yy += d.y * d.y
    yz += d.y * d.z
    zz += d.z * d.z
  }
  let s = 1.0 / Double::from_int(points.length() - 1)
  mat4_from_rows(
    (xx * s, xy * s, xz * s, 0.0),
    (xy * s, yy * s, yz * s, 0.0),
    (xz * s, yz * s, zz * s, 0.0),
    (0.0, 0.0, 0.0, 1.0),
  )
}

///|
pub fn weighted_centroid3(
  points : ArrayView[Point3],
  weights : ArrayView[Double],
) -> Point3 raise GeometryError {
  if points.length() != weights.length() || points.length() == 0 {
    raise GeometryError::NotEnoughPoints(
      "weighted centroid needs paired points",
    )
  }
  let mut x = 0.0
  let mut y = 0.0
  let mut z = 0.0
  let mut total = 0.0
  for i in 0..<points.length() {
    x += points[i].x * weights[i]
    y += points[i].y * weights[i]
    z += points[i].z * weights[i]
    total += weights[i]
  }
  if total <= 0.0 {
    raise GeometryError::DegenerateInput("weights must be positive")
  }
  Point3::new(x=x / total, y=y / total, z=z / total)
}
