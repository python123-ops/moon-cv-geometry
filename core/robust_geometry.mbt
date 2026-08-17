///|
/// Compute a weighted 3D centroid with explicit weight validation.
pub fn robust_weighted_centroid3(
  points : ArrayView[Point3],
  weights : ArrayView[Double],
) -> Point3 raise GeometryError {
  if points.length() == 0 || points.length() != weights.length() {
    raise GeometryError::NotEnoughPoints(
      "weighted centroid needs paired points",
    )
  }
  let mut sx = 0.0
  let mut sy = 0.0
  let mut sz = 0.0
  let mut total = 0.0
  for i in 0..<points.length() {
    if weights[i] < 0.0 {
      raise GeometryError::DegenerateInput("weights must be non-negative")
    }
    sx += points[i].x * weights[i]
    sy += points[i].y * weights[i]
    sz += points[i].z * weights[i]
    total += weights[i]
  }
  if total <= 0.0 {
    raise GeometryError::DegenerateInput("weight sum is zero")
  }
  Point3::new(x=sx / total, y=sy / total, z=sz / total)
}

///|
/// Weighted covariance matrix for uncertainty propagation and outlier gating.
pub fn robust_weighted_covariance3(
  points : ArrayView[Point3],
  weights : ArrayView[Double],
) -> Mat3 raise GeometryError {
  let center = robust_weighted_centroid3(points, weights)
  let mut xx = 0.0
  let mut xy = 0.0
  let mut xz = 0.0
  let mut yy = 0.0
  let mut yz = 0.0
  let mut zz = 0.0
  let mut total = 0.0
  for i in 0..<points.length() {
    let d = points[i].minus(center)
    let w = weights[i]
    xx += w * d.x * d.x
    xy += w * d.x * d.y
    xz += w * d.x * d.z
    yy += w * d.y * d.y
    yz += w * d.y * d.z
    zz += w * d.z * d.z
    total += w
  }
  mat3_from_rows(
    (xx / total, xy / total, xz / total),
    (xy / total, yy / total, yz / total),
    (xz / total, yz / total, zz / total),
  )
}

///|
pub(all) struct NumericRange {
  min : Double
  max : Double
} derive(Debug, Eq)

///|
/// Approximate a percentile interval using sorted samples.
pub fn percentile_range(
  values : ArrayView[Double],
  lower : Double,
  upper : Double,
) -> NumericRange raise GeometryError {
  if values.length() == 0 || lower < 0.0 || upper > 1.0 || lower > upper {
    raise GeometryError::NotEnoughPoints("percentile range is invalid")
  }
  let sorted = values.to_owned()
  sorted.sort()
  let low_index = (lower * (sorted.length() - 1).to_double()).to_int()
  let high_index = (upper * (sorted.length() - 1).to_double()).to_int()
  { min: sorted[low_index], max: sorted[high_index] }
}

///|
/// Filter NaN and infinity values before passing data to a solver.
pub fn finite_points3(points : ArrayView[Point3]) -> Array[Point3] {
  let result : Array[Point3] = []
  for p in points {
    if p.x == p.x && p.y == p.y && p.z == p.z {
      result.push(p)
    }
  }
  result
}

///|
/// Return a robust median absolute deviation estimate.
pub fn median_absolute_deviation(
  values : ArrayView[Double],
) -> Double raise GeometryError {
  let center = median(values)
  let deviations : Array[Double] = []
  for value in values {
    deviations.push(abs(value - center))
  }
  median(deviations)
}

///|
/// Winsorize measurements to a symmetric robust interval.
pub fn winsorize(
  values : ArrayView[Double],
  center : Double,
  scale : Double,
  limit? : Double = 3.0,
) -> Array[Double] {
  let result : Array[Double] = []
  let radius = abs(scale) * limit
  for value in values {
    result.push(value.max(center - radius).min(center + radius))
  }
  result
}
