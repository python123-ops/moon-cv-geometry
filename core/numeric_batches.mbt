///|
/// Batch arithmetic helpers for solver assembly and deterministic tests.
pub fn add_scalars(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = left.length().min(right.length())
  for i in 0..<count {
    result.push(left[i] + right[i])
  }
  result
}

///|
pub fn subtract_scalars(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = left.length().min(right.length())
  for i in 0..<count {
    result.push(left[i] - right[i])
  }
  result
}

///|
pub fn scale_scalars(
  values : ArrayView[Double],
  scale : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    result.push(value * scale)
  }
  result
}

///|
pub fn dot_scalars(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let mut result = 0.0
  let count = left.length().min(right.length())
  for i in 0..<count {
    result += left[i] * right[i]
  }
  result
}

///|
pub fn norm_scalars(values : ArrayView[Double]) -> Double {
  dot_scalars(values, values).sqrt()
}

///|
pub fn mean_scalars(values : ArrayView[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut sum = 0.0
    for value in values {
      sum += value
    }
    sum / values.length().to_double()
  }
}

///|
pub fn variance_scalars(values : ArrayView[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let center = mean_scalars(values)
    let mut total = 0.0
    for value in values {
      let delta = value - center
      total += delta * delta
    }
    total / values.length().to_double()
  }
}

///|
pub fn clamp_scalars(
  values : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    result.push(value.max(minimum).min(maximum))
  }
  result
}

///|
pub fn count_below(values : ArrayView[Double], threshold : Double) -> Int {
  let mut result = 0
  for value in values {
    if value < threshold {
      result += 1
    }
  }
  result
}

///|
pub fn count_above(values : ArrayView[Double], threshold : Double) -> Int {
  let mut result = 0
  for value in values {
    if value > threshold {
      result += 1
    }
  }
  result
}

///|
pub fn cumulative_sum(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  let mut sum = 0.0
  for value in values {
    sum += value
    result.push(sum)
  }
  result
}

///|
pub fn finite_scalars(values : ArrayView[Double]) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    if value == value {
      result.push(value)
    }
  }
  result
}

///|
pub fn range_scalars(values : ArrayView[Double]) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    let mut minimum = values[0]
    let mut maximum = values[0]
    for value in values {
      minimum = minimum.min(value)
      maximum = maximum.max(value)
    }
    maximum - minimum
  }
}

///|
pub fn l1_distance(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let mut result = 0.0
  let count = left.length().min(right.length())
  for i in 0..<count {
    result += abs(left[i] - right[i])
  }
  result
}

///|
pub fn l2_distance(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let mut result = 0.0
  let count = left.length().min(right.length())
  for i in 0..<count {
    let d = left[i] - right[i]
    result += d * d
  }
  result.sqrt()
}

///|
pub fn soft_threshold(value : Double, threshold : Double) -> Double {
  if value > threshold {
    value - threshold
  } else if value < -threshold {
    value + threshold
  } else {
    0.0
  }
}

///|
pub fn soft_threshold_batch(
  values : ArrayView[Double],
  threshold : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    result.push(soft_threshold(value, threshold))
  }
  result
}
