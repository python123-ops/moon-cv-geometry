///|
/// Detailed diagnostics for a residual consensus set.
pub(all) struct DiagnosticReport {
  total : Int
  inliers : Int
  outliers : Int
  inlier_ratio : Double
  mean_inlier : Double
  rms : Double
  maximum : Double
  label : String
} derive(Debug, Eq)

///|
pub fn make_diagnostic_report(
  residuals : ArrayView[Double],
  threshold~ : Double,
) -> DiagnosticReport {
  let mut inliers = 0
  let mut sum = 0.0
  let mut square = 0.0
  let mut maximum = 0.0
  for residual in residuals {
    let value = residual.abs()
    square += value * value
    maximum = maximum.max(value)
    if value <= threshold {
      inliers += 1
      sum += value
    }
  }
  let ratio = if residuals.length() == 0 {
    0.0
  } else {
    inliers.to_double() / residuals.length().to_double()
  }
  let mean = if inliers == 0 { 0.0 } else { sum / inliers.to_double() }
  let rms = if residuals.length() == 0 {
    0.0
  } else {
    (square / residuals.length().to_double()).sqrt()
  }
  {
    total: residuals.length(),
    inliers,
    outliers: residuals.length() - inliers,
    inlier_ratio: ratio,
    mean_inlier: mean,
    rms,
    maximum,
    label: diagnostic_label(ratio, mean, threshold),
  }
}

///|
pub fn diagnostic_label(
  inlier_ratio : Double,
  mean_inlier : Double,
  threshold : Double,
) -> String {
  if inlier_ratio >= 0.75 && mean_inlier <= threshold * 0.5 {
    "good"
  } else if inlier_ratio >= 0.5 {
    "review"
  } else {
    "poor"
  }
}

///|
pub fn diagnostic_report_is_good(
  report : DiagnosticReport,
  minimum_ratio : Double,
  maximum_rms : Double,
) -> Bool {
  report.inlier_ratio >= minimum_ratio &&
  report.rms <= maximum_rms &&
  report.inliers > 0
}

///|
pub fn diagnostic_outlier_indices(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<residuals.length() {
    if residuals[i].abs() > threshold {
      result.push(i)
    }
  }
  result
}

///|
pub fn diagnostic_inlier_indices(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<residuals.length() {
    if residuals[i].abs() <= threshold {
      result.push(i)
    }
  }
  result
}

///|
pub fn diagnostic_residual_histogram(
  residuals : ArrayView[Double],
  bins : Int,
  maximum : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<bins.max(0) {
    result.push(0)
  }
  let width = maximum.abs().max(0.000000000001)
  for residual in residuals {
    if result.length() > 0 {
      let index = (residual.abs() / width * result.length().to_double())
        .to_int()
        .min(result.length() - 1)
        .max(0)
      result[index] += 1
    }
  }
  result
}

///|
pub fn diagnostic_percentile(
  residuals : ArrayView[Double],
  probability : Double,
) -> Double raise @core.GeometryError {
  let values : Array[Double] = []
  for residual in residuals {
    values.push(residual.abs())
  }
  @core.quantile_linear(values, probability)
}

///|
pub fn diagnostic_mad(
  residuals : ArrayView[Double],
) -> Double raise @core.GeometryError {
  let values : Array[Double] = []
  for residual in residuals {
    values.push(residual.abs())
  }
  @core.median_absolute_deviation2(values)
}

///|
pub fn diagnostic_adaptive_threshold(
  residuals : ArrayView[Double],
  multiplier : Double,
  minimum : Double,
) -> Double raise @core.GeometryError {
  (diagnostic_mad(residuals) * multiplier).max(minimum)
}

///|
pub fn diagnostic_score(report : DiagnosticReport, scale : Double) -> Double {
  let denominator = scale.abs().max(0.000000000001)
  report.inlier_ratio * (1.0 - report.mean_inlier / denominator).max(0.0)
}

///|
pub fn diagnostic_compare(
  left : DiagnosticReport,
  right : DiagnosticReport,
) -> Int {
  if left.inliers != right.inliers {
    if left.inliers > right.inliers {
      -1
    } else {
      1
    }
  } else if left.rms < right.rms {
    -1
  } else if left.rms > right.rms {
    1
  } else {
    0
  }
}

///|
pub fn diagnostic_rank(
  reports : ArrayView[DiagnosticReport],
) -> Array[DiagnosticReport] {
  let result = reports.to_owned()
  result.sort_by(fn(left, right) { diagnostic_compare(left, right) })
  result
}
