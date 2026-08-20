///|
/// Online scalar statistics for long-running reconstruction jobs.
pub(all) struct StreamingSummary {
  mut count : Int
  mut mean : Double
  mut variance : Double
  mut minimum : Double
  mut maximum : Double
} derive(Debug, Eq)

///|
pub fn streaming_summary(values : ArrayView[Double]) -> StreamingSummary {
  let summary = {
    count: 0,
    mean: 0.0,
    variance: 0.0,
    minimum: 0.0,
    maximum: 0.0,
  }
  for value in values {
    streaming_add(summary, value)
  }
  summary
}

///|
pub fn streaming_add(summary : StreamingSummary, value : Double) -> Unit {
  let previous = summary.count
  summary.count += 1
  if previous == 0 {
    summary.mean = value
    summary.variance = 0.0
    summary.minimum = value
    summary.maximum = value
  } else {
    let delta = value - summary.mean
    summary.mean += delta / summary.count.to_double()
    let delta2 = value - summary.mean
    summary.variance += delta * delta2
    summary.minimum = summary.minimum.min(value)
    summary.maximum = summary.maximum.max(value)
  }
}

///|
pub fn StreamingSummary::sample_variance(summary : StreamingSummary) -> Double {
  if summary.count < 2 {
    0.0
  } else {
    summary.variance / (summary.count - 1).to_double()
  }
}

///|
pub fn StreamingSummary::population_variance(
  summary : StreamingSummary,
) -> Double {
  if summary.count == 0 {
    0.0
  } else {
    summary.variance / summary.count.to_double()
  }
}

///|
pub fn StreamingSummary::standard_deviation(
  summary : StreamingSummary,
) -> Double {
  summary.population_variance().sqrt()
}

///|
pub fn StreamingSummary::range(summary : StreamingSummary) -> Double {
  if summary.count == 0 {
    0.0
  } else {
    summary.maximum - summary.minimum
  }
}

///|
pub fn StreamingSummary::is_empty(summary : StreamingSummary) -> Bool {
  summary.count == 0
}

///|
pub fn merge_streaming_summary(
  left : StreamingSummary,
  right : StreamingSummary,
) -> StreamingSummary {
  if left.count == 0 {
    return right
  }
  if right.count == 0 {
    return left
  }
  let total = left.count + right.count
  let delta = right.mean - left.mean
  let result = {
    count: total,
    mean: left.mean + delta * right.count.to_double() / total.to_double(),
    variance: left.variance +
    right.variance +
    delta *
    delta *
    left.count.to_double() *
    right.count.to_double() /
    total.to_double(),
    minimum: left.minimum.min(right.minimum),
    maximum: left.maximum.max(right.maximum),
  }
  result
}

///|
pub fn streaming_summary_chunks(
  chunks : ArrayView[Array[Double]],
) -> StreamingSummary {
  let mut result = {
    count: 0,
    mean: 0.0,
    variance: 0.0,
    minimum: 0.0,
    maximum: 0.0,
  }
  for chunk in chunks {
    result = merge_streaming_summary(result, streaming_summary(chunk))
  }
  result
}

///|
pub fn running_mean(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  let summary = {
    count: 0,
    mean: 0.0,
    variance: 0.0,
    minimum: 0.0,
    maximum: 0.0,
  }
  for value in values {
    streaming_add(summary, value)
    result.push(summary.mean)
  }
  result
}

///|
pub fn running_variance(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  let summary = {
    count: 0,
    mean: 0.0,
    variance: 0.0,
    minimum: 0.0,
    maximum: 0.0,
  }
  for value in values {
    streaming_add(summary, value)
    result.push(summary.population_variance())
  }
  result
}

///|
pub fn running_minimum(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  let mut minimum = 0.0
  for i in 0..<values.length() {
    if i == 0 {
      minimum = values[i]
    } else {
      minimum = minimum.min(values[i])
    }
    result.push(minimum)
  }
  result
}

///|
pub fn running_maximum(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  let mut maximum = 0.0
  for i in 0..<values.length() {
    if i == 0 {
      maximum = values[i]
    } else {
      maximum = maximum.max(values[i])
    }
    result.push(maximum)
  }
  result
}

///|
pub fn exponentially_weighted_variance(
  values : ArrayView[Double],
  decay : Double,
) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let alpha = decay.max(0.0).min(1.0)
    let mut mean = values[0]
    let mut variance = 0.0
    for value in values[1:] {
      let difference = value - mean
      mean += alpha * difference
      variance = (1.0 - alpha) * (variance + alpha * difference * difference)
    }
    variance
  }
}

///|
pub fn covariance_streaming(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let count = left.length().min(right.length())
  if count == 0 {
    0.0
  } else {
    let left_mean = mean_scalars(left)
    let right_mean = mean_scalars(right)
    let mut sum = 0.0
    for i in 0..<count {
      sum += (left[i] - left_mean) * (right[i] - right_mean)
    }
    sum / count.to_double()
  }
}

///|
pub fn correlation_streaming(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let covariance = covariance_streaming(left, right)
  let left_scale = variance_scalars(left).sqrt()
  let right_scale = variance_scalars(right).sqrt()
  if left_scale <= 0.0 || right_scale <= 0.0 {
    0.0
  } else {
    covariance / (left_scale * right_scale)
  }
}
