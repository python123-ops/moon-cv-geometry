///|
/// Linear-interpolated quantile for deterministic robust estimators.
pub fn quantile_linear(
  values : ArrayView[Double],
  probability : Double,
) -> Double raise GeometryError {
  if values.length() == 0 {
    raise GeometryError::NotEnoughPoints("quantile needs values")
  }
  if probability < 0.0 || probability > 1.0 {
    raise GeometryError::DegenerateInput(
      "quantile probability must be in [0, 1]",
    )
  }
  let sorted = values.to_owned()
  sorted.sort()
  if sorted.length() == 1 {
    return sorted[0]
  }
  let position = probability * (sorted.length() - 1).to_double()
  let lower = position.floor().to_int()
  let upper = position.ceil().to_int()
  if lower == upper {
    sorted[lower]
  } else {
    sorted[lower] +
    (sorted[upper] - sorted[lower]) * (position - lower.to_double())
  }
}

///|
pub fn median_absolute_deviation2(
  values : ArrayView[Double],
) -> Double raise GeometryError {
  let center = quantile_linear(values, 0.5)
  let deviations : Array[Double] = []
  for value in values {
    deviations.push(abs(value - center))
  }
  quantile_linear(deviations, 0.5)
}

///|
pub fn interquartile_range2(
  values : ArrayView[Double],
) -> Double raise GeometryError {
  quantile_linear(values, 0.75) - quantile_linear(values, 0.25)
}

///|
pub fn robust_clip(
  values : ArrayView[Double],
  center~ : Double,
  scale~ : Double,
  multiplier~ : Double,
) -> Array[Double] {
  let radius = abs(scale) * abs(multiplier)
  let result : Array[Double] = []
  for value in values {
    result.push(value.max(center - radius).min(center + radius))
  }
  result
}

///|
pub fn robust_z_scores2(
  values : ArrayView[Double],
) -> Array[Double] raise GeometryError {
  let center = quantile_linear(values, 0.5)
  let deviation = median_absolute_deviation2(values).max(0.000000000001)
  let result : Array[Double] = []
  for value in values {
    result.push(0.67448975 * (value - center) / deviation)
  }
  result
}

///|
pub fn tukey_fences(
  values : ArrayView[Double],
  multiplier? : Double = 1.5,
) -> (Double, Double) raise GeometryError {
  let q1 = quantile_linear(values, 0.25)
  let q3 = quantile_linear(values, 0.75)
  let radius = (q3 - q1) * multiplier
  (q1 - radius, q3 + radius)
}

///|
pub fn values_inside_fences(
  values : ArrayView[Double],
  lower : Double,
  upper : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    if value >= lower && value <= upper {
      result.push(value)
    }
  }
  result
}

///|
pub fn weighted_mean2(
  values : ArrayView[Double],
  weights : ArrayView[Double],
) -> Double raise GeometryError {
  if values.length() == 0 || values.length() != weights.length() {
    raise GeometryError::NotEnoughPoints("weighted mean needs paired values")
  }
  let mut numerator = 0.0
  let mut denominator = 0.0
  for i in 0..<values.length() {
    if weights[i] < 0.0 {
      raise GeometryError::DegenerateInput("weights cannot be negative")
    }
    numerator += values[i] * weights[i]
    denominator += weights[i]
  }
  if denominator <= 0.0 {
    raise GeometryError::DegenerateInput("weight sum must be positive")
  }
  numerator / denominator
}

///|
pub fn weighted_variance2(
  values : ArrayView[Double],
  weights : ArrayView[Double],
) -> Double raise GeometryError {
  let center = weighted_mean2(values, weights)
  let mut numerator = 0.0
  let mut denominator = 0.0
  for i in 0..<values.length() {
    numerator += weights[i] * (values[i] - center) * (values[i] - center)
    denominator += weights[i]
  }
  numerator / denominator
}

///|
pub fn exponentially_weighted_mean(
  values : ArrayView[Double],
  decay : Double,
) -> Double raise GeometryError {
  if values.length() == 0 {
    raise GeometryError::NotEnoughPoints("EWMA needs values")
  }
  let alpha = decay.max(0.0).min(1.0)
  let mut result = values[0]
  for value in values[1:] {
    result = alpha * value + (1.0 - alpha) * result
  }
  result
}

///|
pub fn running_median_approx(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  let prefix : Array[Double] = []
  for value in values {
    prefix.push(value)
    prefix.sort()
    result.push(prefix[prefix.length() / 2])
  }
  result
}

///|
pub fn robust_threshold(
  values : ArrayView[Double],
  minimum~ : Double,
  multiplier~ : Double,
) -> Double raise GeometryError {
  (median_absolute_deviation2(values) * multiplier).max(minimum)
}
