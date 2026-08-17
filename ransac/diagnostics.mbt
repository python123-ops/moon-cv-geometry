///|
pub(all) struct ConsensusReport {
  total : Int
  inliers : Int
  ratio : Double
  mean_inlier_error : Double
  max_inlier_error : Double
} derive(Debug, Eq)

///|
pub fn report_from_residuals(
  residuals : ArrayView[Double],
  threshold~ : Double,
) -> ConsensusReport raise @core.GeometryError {
  if threshold <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "report threshold must be positive",
    )
  }
  let mut count = 0
  let mut total = 0.0
  let mut maximum = 0.0
  for residual in residuals {
    if residual <= threshold {
      count += 1
      total += residual
      if residual > maximum {
        maximum = residual
      }
    }
  }
  let mean = if count == 0 { 0.0 } else { total / Double::from_int(count) }
  let ratio = if residuals.length() == 0 {
    0.0
  } else {
    Double::from_int(count) / Double::from_int(residuals.length())
  }
  {
    total: residuals.length(),
    inliers: count,
    ratio,
    mean_inlier_error: mean,
    max_inlier_error: maximum,
  }
}

///|
pub fn ConsensusReport::acceptable(
  report : ConsensusReport,
  minimum_ratio~ : Double,
  maximum_mean_error~ : Double,
) -> Bool {
  report.ratio >= minimum_ratio &&
  report.mean_inlier_error <= maximum_mean_error
}

///|
pub fn ConsensusReport::summary_score(report : ConsensusReport) -> Double {
  report.ratio / (1.0 + report.mean_inlier_error + report.max_inlier_error)
}

///|
pub fn clipped_residuals(
  residuals : ArrayView[Double],
  cutoff~ : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for residual in residuals {
    result.push(if residual < cutoff { residual } else { cutoff })
  }
  result
}

///|
pub fn inlier_weight(residual~ : Double, threshold~ : Double) -> Double {
  if threshold <= 0.0 || residual >= threshold {
    0.0
  } else {
    let ratio = residual / threshold
    1.0 - ratio * ratio
  }
}

///|
pub fn weighted_consensus(
  residuals : ArrayView[Double],
  threshold~ : Double,
) -> Double {
  let mut total = 0.0
  for residual in residuals {
    total += inlier_weight(residual~, threshold~)
  }
  total
}

///|
pub fn validate_mask(mask : InlierMask, expected_length~ : Int) -> Bool {
  mask.length() == expected_length && mask.count() <= expected_length
}
