///|
/// Per-track residual statistics for bundle-adjustment diagnostics.
pub(all) struct BundleStatistics {
  count : Int
  mean : Double
  rms : Double
  maximum : Double
}

///|
pub fn bundle_statistics(residuals : ArrayView[Double]) -> BundleStatistics {
  if residuals.length() == 0 {
    return { count: 0, mean: 0.0, rms: 0.0, maximum: 0.0, }
  }
  let mut sum = 0.0
  let mut square = 0.0
  let mut maximum = 0.0
  for residual in residuals {
    let value = @core.abs(residual)
    sum += value
    square += value * value
    maximum = maximum.max(value)
  }
  {
    count: residuals.length(),
    mean: sum / residuals.length().to_double(),
    rms: (square / residuals.length().to_double()).sqrt(),
    maximum,
  }
}

///|
pub fn robust_bundle_cost(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Double {
  let mut cost = 0.0
  for residual in residuals {
    let value = @core.abs(residual)
    cost += if value <= threshold {
      value * value
    } else {
      2.0 * threshold * value - threshold * threshold
    }
  }
  cost
}

///|
pub fn huber_weights(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for residual in residuals {
    let value = @core.abs(residual)
    result.push(
      if value <= threshold || value == 0.0 {
        1.0
      } else {
        threshold / value
      },
    )
  }
  result
}

///|
pub fn residuals_above(
  residuals : ArrayView[Double],
  threshold : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<residuals.length() {
    if @core.abs(residuals[i]) > threshold {
      result.push(i)
    }
  }
  result
}

///|
pub fn weighted_cost(
  residuals : ArrayView[Double],
  weights : ArrayView[Double],
) -> Double {
  let mut result = 0.0
  let count = residuals.length().min(weights.length())
  for i in 0..<count {
    result += residuals[i] * residuals[i] * weights[i].max(0.0)
  }
  result
}
