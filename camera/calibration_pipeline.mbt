///|
/// Aggregated reprojection diagnostics for one calibration batch.
pub(all) struct CalibrationBatchReport {
  count : Int
  mean : Double
  rms : Double
  maximum : Double
  valid_count : Int
} derive(Debug, Eq)

///|
pub fn calibration_batch_report(
  points : ArrayView[@core.Point3],
  pixels : ArrayView[@core.Point2],
  intrinsics : CameraIntrinsics,
  pose? : CameraPose = CameraPose::identity(),
) -> CalibrationBatchReport raise @core.GeometryError {
  if points.length() != pixels.length() {
    raise @core.GeometryError::DegenerateInput(
      "calibration arrays have different lengths",
    )
  }
  let mut sum = 0.0
  let mut square = 0.0
  let mut maximum = 0.0
  let mut valid = 0
  for i in 0..<points.length() {
    let projected = project_point_with_pose(points[i], intrinsics, pose)
    let error = projected.minus(pixels[i]).norm()
    sum += error
    square += error * error
    maximum = maximum.max(error)
    valid += 1
  }
  {
    count: points.length(),
    mean: if valid == 0 {
      0.0
    } else {
      sum / valid.to_double()
    },
    rms: if valid == 0 {
      0.0
    } else {
      (square / valid.to_double()).sqrt()
    },
    maximum,
    valid_count: valid,
  }
}

///|
pub(all) struct CalibrationResidual {
  index : Int
  residual : @core.Vec2
  norm : Double
  valid : Bool
} derive(Debug, Eq)

///|
pub fn calibration_residuals(
  points : ArrayView[@core.Point3],
  pixels : ArrayView[@core.Point2],
  intrinsics : CameraIntrinsics,
  pose? : CameraPose = CameraPose::identity(),
) -> Array[CalibrationResidual] raise @core.GeometryError {
  if points.length() != pixels.length() {
    raise @core.GeometryError::DegenerateInput(
      "calibration arrays have different lengths",
    )
  }
  let result : Array[CalibrationResidual] = []
  for i in 0..<points.length() {
    let predicted = project_point_with_pose(points[i], intrinsics, pose) catch {
      _ => pixels[i]
    }
    let residual = predicted.minus(pixels[i])
    result.push({
      index: i,
      residual,
      norm: residual.norm(),
      valid: points[i].z > 0.0,
    })
  }
  result
}

///|
pub fn residual_norms(
  residuals : ArrayView[CalibrationResidual],
) -> Array[Double] {
  let result : Array[Double] = []
  for residual in residuals {
    result.push(residual.norm)
  }
  result
}

///|
pub fn calibration_inlier_mask(
  residuals : ArrayView[CalibrationResidual],
  threshold : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for residual in residuals {
    result.push(residual.valid && residual.norm <= threshold)
  }
  result
}

///|
pub fn calibration_inlier_count(
  residuals : ArrayView[CalibrationResidual],
  threshold : Double,
) -> Int {
  let mut count = 0
  for residual in residuals {
    if residual.valid && residual.norm <= threshold {
      count += 1
    }
  }
  count
}

///|
pub fn calibration_inlier_ratio(
  residuals : ArrayView[CalibrationResidual],
  threshold : Double,
) -> Double {
  if residuals.length() == 0 {
    0.0
  } else {
    calibration_inlier_count(residuals, threshold).to_double() /
    residuals.length().to_double()
  }
}

///|
pub fn calibration_report_is_usable(
  report : CalibrationBatchReport,
  maximum_rms : Double,
  minimum_valid : Int,
) -> Bool {
  report.valid_count >= minimum_valid && report.rms <= maximum_rms
}

///|
pub fn split_calibration_residuals(
  residuals : ArrayView[CalibrationResidual],
  threshold : Double,
) -> (Array[CalibrationResidual], Array[CalibrationResidual]) {
  let inliers : Array[CalibrationResidual] = []
  let outliers : Array[CalibrationResidual] = []
  for residual in residuals {
    if residual.valid && residual.norm <= threshold {
      inliers.push(residual)
    } else {
      outliers.push(residual)
    }
  }
  (inliers, outliers)
}

///|
pub fn weighted_calibration_error(
  residuals : ArrayView[CalibrationResidual],
  weights : ArrayView[Double],
) -> Double raise @core.GeometryError {
  if residuals.length() != weights.length() {
    raise @core.GeometryError::DegenerateInput(
      "residual weights have different lengths",
    )
  }
  let mut numerator = 0.0
  let mut denominator = 0.0
  for i in 0..<residuals.length() {
    numerator += residuals[i].norm * weights[i]
    denominator += weights[i]
  }
  if denominator <= 0.0 {
    0.0
  } else {
    numerator / denominator
  }
}

///|
pub fn calibration_error_percentile(
  residuals : ArrayView[CalibrationResidual],
  probability : Double,
) -> Double raise @core.GeometryError {
  let values = residual_norms(residuals)
  @core.quantile_linear(values, probability)
}

///|
pub fn calibration_quality_score(
  report : CalibrationBatchReport,
  expected_count : Int,
  target_rms : Double,
) -> Double {
  let support = if expected_count <= 0 {
    0.0
  } else {
    report.valid_count.to_double() / expected_count.to_double()
  }
  let precision = if target_rms <= 0.0 {
    0.0
  } else {
    (1.0 - report.rms / target_rms).max(0.0)
  }
  (support * precision).max(0.0).min(1.0)
}

///|
pub fn calibration_batch_chunks(
  points : ArrayView[@core.Point3],
  chunk_size : Int,
) -> Array[Array[@core.Point3]] {
  let result : Array[Array[@core.Point3]] = []
  if chunk_size <= 0 {
    return result
  }
  let mut start = 0
  while start < points.length() {
    let chunk : Array[@core.Point3] = []
    let end = (start + chunk_size).min(points.length())
    for i in start..<end {
      chunk.push(points[i])
    }
    result.push(chunk)
    start = end
  }
  result
}

///|
pub fn reprojection_residual_sum(
  residuals : ArrayView[CalibrationResidual],
) -> Double {
  let mut result = 0.0
  for residual in residuals {
    result += residual.norm
  }
  result
}

///|
pub fn reprojection_residual_rms(
  residuals : ArrayView[CalibrationResidual],
) -> Double {
  if residuals.length() == 0 {
    0.0
  } else {
    let mut result = 0.0
    for residual in residuals {
      result += residual.norm * residual.norm
    }
    (result / residuals.length().to_double()).sqrt()
  }
}
