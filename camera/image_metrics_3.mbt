///|
/// Final image-metric helpers for benchmark reports.
pub fn image_metric_mae(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  image_window_mean_abs_difference(left, right)
}

///|
pub fn image_metric_mse(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  image_window_mean_squared_difference(left, right)
}

///|
pub fn image_metric_rmse(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  image_metric_mse(left, right).sqrt()
}

///|
pub fn image_metric_psnr(
  left : ArrayView[Double],
  right : ArrayView[Double],
  peak : Double,
) -> Double {
  let mse = image_metric_mse(left, right)
  if mse <= 0.0 {
    0.0
  } else {
    20.0 * @math.ln(peak.max(0.000000000001) / mse.sqrt()) / @math.ln(10.0)
  }
}

///|
pub fn image_metric_ncc(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  image_window_normalized_cross_correlation(left, right)
}

///|
pub fn image_metric_valid_ratio(values : ArrayView[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for value in values {
      if !value.is_nan() {
        count += 1
      }
    }
    count.to_double() / values.length().to_double()
  }
}

///|
pub fn image_metric_range(values : ArrayView[Double]) -> Double {
  let stats = image_window_stats(values)
  stats.maximum - stats.minimum
}

///|
pub fn image_metric_contrast(values : ArrayView[Double]) -> Double {
  let stats = image_window_stats(values)
  if stats.mean.abs() <= 0.000000000001 {
    0.0
  } else {
    (stats.maximum - stats.minimum) / stats.mean.abs()
  }
}

///|
pub fn image_metric_quality(
  values : ArrayView[Double],
  minimum_contrast : Double,
) -> Double {
  let contrast = image_metric_contrast(values)
  if minimum_contrast <= 0.0 {
    1.0
  } else {
    (contrast / minimum_contrast).min(1.0) * image_metric_valid_ratio(values)
  }
}

///|
pub fn image_metric_report(
  values : ArrayView[Double],
  reference : ArrayView[Double],
) -> String {
  image_metric_mae(values, reference).to_string() +
  "," +
  image_metric_rmse(values, reference).to_string() +
  "," +
  image_metric_ncc(values, reference).to_string() +
  "," +
  image_metric_quality(values, 0.1).to_string()
}
