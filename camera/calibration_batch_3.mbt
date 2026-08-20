///|
/// Batch calibration diagnostics for repeated image measurements.
pub(all) struct CalibrationBatchSummary {
  count : Int
  mean_error : Double
  maximum_error : Double
  median_error : Double
  valid_ratio : Double
  score : Double
} derive(Debug, Eq)

///|
pub fn calibration_error_stats(
  errors : ArrayView[Double],
) -> CalibrationBatchSummary {
  let mut valid = 0
  let mut total = 0.0
  let mut maximum = 0.0
  for error in errors {
    if !error.is_nan() && error >= 0.0 {
      valid += 1
      total += error
      maximum = maximum.max(error)
    }
  }
  let valid_values : Array[Double] = []
  for error in errors {
    if !error.is_nan() && error >= 0.0 {
      valid_values.push(error)
    }
  }
  let mean_error = if valid == 0 { 0.0 } else { total / valid.to_double() }
  let median_error = @core.median(valid_values) catch { _ => 0.0 }
  let valid_ratio = if errors.length() == 0 {
    0.0
  } else {
    valid.to_double() / errors.length().to_double()
  }
  {
    count: errors.length(),
    mean_error,
    maximum_error: maximum,
    median_error,
    valid_ratio,
    score: valid_ratio / (1.0 + mean_error),
  }
}

///|
pub fn calibration_errors_from_pairs(
  predicted : ArrayView[@core.Point2],
  observed : ArrayView[@core.Point2],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = predicted.length().min(observed.length())
  for i in 0..<count {
    result.push(predicted[i].minus(observed[i]).norm())
  }
  result
}

///|
pub fn calibration_squared_errors_from_pairs(
  predicted : ArrayView[@core.Point2],
  observed : ArrayView[@core.Point2],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = predicted.length().min(observed.length())
  for i in 0..<count {
    result.push(predicted[i].minus(observed[i]).norm2())
  }
  result
}

///|
pub fn calibration_rms_error(errors : ArrayView[Double]) -> Double {
  if errors.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for error in errors {
      total += error * error
    }
    (total / errors.length().to_double()).sqrt()
  }
}

///|
pub fn calibration_mean_error(errors : ArrayView[Double]) -> Double {
  @core.mean(errors) catch {
    _ => 0.0
  }
}

///|
pub fn calibration_max_error(errors : ArrayView[Double]) -> Double {
  let mut result = 0.0
  for error in errors {
    result = result.max(error.abs())
  }
  result
}

///|
pub fn calibration_percentile_error(
  errors : ArrayView[Double],
  percentile : Double,
) -> Double {
  @core.quantile_linear(errors, percentile) catch {
    _ => 0.0
  }
}

///|
pub fn calibration_inlier_flags(
  errors : ArrayView[Double],
  threshold : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for error in errors {
    result.push(!error.is_nan() && error <= threshold.max(0.0))
  }
  result
}

///|
pub fn calibration_batch_inlier_count(
  errors : ArrayView[Double],
  threshold : Double,
) -> Int {
  let mut result = 0
  for error in errors {
    if !error.is_nan() && error <= threshold.max(0.0) {
      result += 1
    }
  }
  result
}

///|
pub fn calibration_batch_inlier_ratio(
  errors : ArrayView[Double],
  threshold : Double,
) -> Double {
  if errors.length() == 0 {
    0.0
  } else {
    calibration_batch_inlier_count(errors, threshold).to_double() /
    errors.length().to_double()
  }
}

///|
pub fn calibration_trimmed_errors(
  errors : ArrayView[Double],
  trim_ratio : Double,
) -> Array[Double] {
  let sorted = errors.to_owned()
  sorted.sort()
  let remove = (sorted.length().to_double() * trim_ratio.max(0.0).min(0.49)).to_int()
  let result : Array[Double] = []
  let end = (sorted.length() - remove).max(remove)
  for i in remove..<end {
    result.push(sorted[i])
  }
  result
}

///|
pub fn calibration_trimmed_mean(
  errors : ArrayView[Double],
  trim_ratio : Double,
) -> Double {
  @core.mean(calibration_trimmed_errors(errors, trim_ratio)) catch {
    _ => 0.0
  }
}

///|
pub fn calibration_weighted_error(
  errors : ArrayView[Double],
  weights : ArrayView[Double],
) -> Double {
  let count = errors.length().min(weights.length())
  let mut total = 0.0
  let mut scale = 0.0
  for i in 0..<count {
    let weight = weights[i].max(0.0)
    total += errors[i].abs() * weight
    scale += weight
  }
  if scale <= 0.0 {
    0.0
  } else {
    total / scale
  }
}

///|
pub fn calibration_quality_curve(
  errors : ArrayView[Double],
  thresholds : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  for threshold in thresholds {
    result.push(calibration_batch_inlier_ratio(errors, threshold))
  }
  result
}

///|
pub fn calibration_auc(
  thresholds : ArrayView[Double],
  values : ArrayView[Double],
) -> Double {
  let count = thresholds.length().min(values.length())
  if count < 2 {
    0.0
  } else {
    let mut area = 0.0
    for i in 0..<(count - 1) {
      area += (thresholds[i + 1] - thresholds[i]).abs() *
        (values[i + 1] + values[i]) *
        0.5
    }
    area
  }
}

///|
pub fn calibration_error_histogram(
  errors : ArrayView[Double],
  bins : Int,
  maximum : Double,
) -> Array[Int] {
  let result = Array::make(bins.max(0), 0)
  if maximum <= 0.0 {
    return result
  }
  for error in errors {
    let index = (error.max(0.0) / maximum * bins.to_double())
      .to_int()
      .min(result.length() - 1)
      .max(0)
    if result.length() > 0 {
      result[index] += 1
    }
  }
  result
}

///|
pub fn calibration_histogram_peak(histogram : ArrayView[Int]) -> Int {
  let mut result = 0
  for i in 0..<histogram.length() {
    if histogram[i] > histogram[result] {
      result = i
    }
  }
  result
}

///|
pub fn calibration_histogram_mass(
  histogram : ArrayView[Int],
  first : Int,
  last : Int,
) -> Int {
  let mut result = 0
  let start = first.max(0)
  let end = last.min(histogram.length()).max(start)
  for i in start..<end {
    result += histogram[i]
  }
  result
}

///|
pub fn calibration_report_label(summary : CalibrationBatchSummary) -> String {
  if summary.valid_ratio < 0.5 {
    "invalid"
  } else if summary.score >= 0.8 {
    "excellent"
  } else if summary.score >= 0.5 {
    "usable"
  } else {
    "review"
  }
}

///|
pub fn calibration_report_csv(summary : CalibrationBatchSummary) -> String {
  summary.count.to_string() +
  "," +
  summary.mean_error.to_string() +
  "," +
  summary.maximum_error.to_string() +
  "," +
  summary.median_error.to_string() +
  "," +
  summary.valid_ratio.to_string() +
  "," +
  summary.score.to_string()
}

///|
pub fn calibration_batch_merge(
  left : CalibrationBatchSummary,
  right : CalibrationBatchSummary,
) -> CalibrationBatchSummary {
  let count = left.count + right.count
  let mean = if count == 0 {
    0.0
  } else {
    (
      left.mean_error * left.count.to_double() +
      right.mean_error * right.count.to_double()
    ) /
    count.to_double()
  }
  {
    count,
    mean_error: mean,
    maximum_error: left.maximum_error.max(right.maximum_error),
    median_error: (left.median_error + right.median_error) * 0.5,
    valid_ratio: (left.valid_ratio + right.valid_ratio) * 0.5,
    score: (left.score + right.score) * 0.5,
  }
}

///|
pub fn calibration_batch_merge_all(
  summaries : ArrayView[CalibrationBatchSummary],
) -> CalibrationBatchSummary {
  if summaries.length() == 0 {
    calibration_error_stats([])
  } else {
    let mut result = summaries[0]
    for summary in summaries[1:] {
      result = calibration_batch_merge(result, summary)
    }
    result
  }
}

///|
pub fn calibration_error_improvement(
  previous : ArrayView[Double],
  current : ArrayView[Double],
) -> Double {
  let a = calibration_rms_error(previous)
  let b = calibration_rms_error(current)
  if a <= 0.0 {
    0.0
  } else {
    (a - b) / a
  }
}

///|
pub fn calibration_is_improving(
  history : ArrayView[Double],
  tolerance : Double,
) -> Bool {
  if history.length() < 2 {
    true
  } else {
    history[history.length() - 1] <=
    history[history.length() - 2] + tolerance.max(0.0)
  }
}

///|
pub fn calibration_stop(
  history : ArrayView[Double],
  patience : Int,
  tolerance : Double,
) -> Bool {
  if patience <= 0 || history.length() <= patience {
    false
  } else {
    let reference = history[history.length() - patience - 1]
    let mut best = reference
    for value in history[history.length() - patience:] {
      best = best.min(value)
    }
    reference - best <= tolerance.max(0.0)
  }
}

///|
pub fn calibration_parameter_delta(
  before : CameraIntrinsics,
  after : CameraIntrinsics,
) -> Double {
  let values = [
    after.fx - before.fx,
    after.fy - before.fy,
    after.cx - before.cx,
    after.cy - before.cy,
    after.skew - before.skew,
  ]
  let mut total = 0.0
  for value in values {
    total += value * value
  }
  total.sqrt()
}

///|
pub fn calibration_intrinsics_interpolate(
  before : CameraIntrinsics,
  after : CameraIntrinsics,
  amount : Double,
) -> CameraIntrinsics {
  let t = amount.max(0.0).min(1.0)
  CameraIntrinsics::new(
    fx=before.fx + (after.fx - before.fx) * t,
    fy=before.fy + (after.fy - before.fy) * t,
    cx=before.cx + (after.cx - before.cx) * t,
    cy=before.cy + (after.cy - before.cy) * t,
    skew=before.skew + (after.skew - before.skew) * t,
  )
}

///|
pub fn calibration_intrinsics_smooth(
  history : ArrayView[CameraIntrinsics],
) -> CameraIntrinsics {
  if history.length() == 0 {
    CameraIntrinsics::new(fx=1.0, fy=1.0, cx=0.0, cy=0.0, skew=0.0)
  } else {
    let mut result = history[0]
    for value in history[1:] {
      result = calibration_intrinsics_interpolate(result, value, 0.5)
    }
    result
  }
}

///|
pub fn calibration_focal_aspect(intrinsics : CameraIntrinsics) -> Double {
  if intrinsics.fy.abs() <= 0.000000000001 {
    0.0
  } else {
    intrinsics.fx / intrinsics.fy
  }
}

///|
pub fn calibration_principal_offset(
  intrinsics : CameraIntrinsics,
  size : ImageSize,
) -> Double {
  let center_x = size.width.to_double() * 0.5
  let center_y = size.height.to_double() * 0.5
  ((intrinsics.cx - center_x) * (intrinsics.cx - center_x) +
  (intrinsics.cy - center_y) * (intrinsics.cy - center_y)).sqrt()
}

///|
pub fn calibration_intrinsics_score(
  intrinsics : CameraIntrinsics,
  size : ImageSize,
) -> Double {
  if intrinsics.fx <= 0.0 || intrinsics.fy <= 0.0 {
    0.0
  } else {
    1.0 /
    (
      1.0 +
      calibration_principal_offset(intrinsics, size) +
      (calibration_focal_aspect(intrinsics) - 1.0).abs()
    )
  }
}
