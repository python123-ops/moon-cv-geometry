///|
/// Validate paired 2D/3D correspondences before estimation.
pub fn validate_correspondences3d2d(
  points3 : ArrayView[Point3],
  points2 : ArrayView[Point2],
  minimum : Int,
) -> Bool {
  points3.length() == points2.length() &&
  points3.length() >= minimum &&
  points3.length() > 0
}

///|
pub fn duplicate_point_indices(
  points : ArrayView[Point2],
  tolerance : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<points.length() {
    for j in 0..<i {
      if points[i].minus(points[j]).norm() <= tolerance {
        result.push(i)
        break
      }
    }
  }
  result
}

///|
pub fn remove_duplicate_points(
  points : ArrayView[Point2],
  tolerance : Double,
) -> Array[Point2] {
  let result : Array[Point2] = []
  for point in points {
    let mut duplicate = false
    for kept in result {
      if point.minus(kept).norm() <= tolerance {
        duplicate = true
        break
      }
    }
    if !duplicate {
      result.push(point)
    }
  }
  result
}

///|
pub fn has_non_collinear_triplet(
  points : ArrayView[Point2],
  tolerance : Double,
) -> Bool {
  for i in 0..<points.length() {
    for j in (i + 1)..<points.length() {
      for k in (j + 1)..<points.length() {
        let a = points[j].minus(points[i])
        let b = points[k].minus(points[i])
        if abs(a.x * b.y - a.y * b.x) > tolerance {
          return true
        }
      }
    }
  }
  false
}

///|
pub fn normalized_residuals(
  residuals : ArrayView[Double],
  scale : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  let divisor = scale.abs().max(0.000000000001)
  for residual in residuals {
    result.push(residual / divisor)
  }
  result
}

///|
pub fn max_residual(residuals : ArrayView[Double]) -> Double {
  let mut result = 0.0
  for residual in residuals {
    result = result.max(abs(residual))
  }
  result
}

///|
pub fn residual_percentile(
  residuals : ArrayView[Double],
  percentile : Double,
) -> Double raise GeometryError {
  let values : Array[Double] = []
  for residual in residuals {
    values.push(abs(residual))
  }
  percentile_range(values, percentile, percentile).min
}
