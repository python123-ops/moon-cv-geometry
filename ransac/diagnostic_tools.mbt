///|
/// Small diagnostics used by CLI reports and CI smoke checks.
pub fn inlier_indices(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<residuals.length() {
    if @core.abs(residuals[i]) <= threshold {
      result.push(i)
    }
  }
  result
}

///|
pub fn outlier_ratio(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Double {
  if residuals.length() == 0 {
    0.0
  } else {
    1.0 -
    inlier_indices(residuals, threshold).length().to_double() /
    residuals.length().to_double()
  }
}

///|
pub fn median_inlier_residual(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Double raise @core.GeometryError {
  let values : Array[Double] = []
  for residual in residuals {
    if @core.abs(residual) <= threshold {
      values.push(@core.abs(residual))
    }
  }
  @core.median(values)
}

///|
pub fn quality_label(
  inlier_ratio : Double,
  median_error : Double,
  good_ratio : Double,
  max_error : Double,
) -> String {
  if inlier_ratio >= good_ratio && median_error <= max_error {
    "good"
  } else if inlier_ratio >= good_ratio * 0.5 {
    "review"
  } else {
    "poor"
  }
}

///|
pub fn score_margin(best : Double, second : Double) -> Double {
  (best - second).max(0.0)
}

///|
pub fn stable_model(
  best : ModelReport,
  second : ModelReport,
  minimum_margin : Double,
) -> Bool {
  best.is_usable(0.0, 1) &&
  score_margin(best.score, second.score) >= minimum_margin
}
