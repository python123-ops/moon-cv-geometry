///|
/// Generate a uniformly spaced disparity search interval.
pub fn disparity_scan(
  minimum~ : Double,
  maximum~ : Double,
  steps~ : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if steps <= 0 {
    return result
  }
  if steps == 1 {
    result.push(minimum)
    return result
  }
  for i in 0..<steps {
    result.push(
      minimum + (maximum - minimum) * i.to_double() / (steps - 1).to_double(),
    )
  }
  result
}

///|
pub fn disparity_is_valid(
  disparity : Double,
  minimum : Double,
  maximum : Double,
) -> Bool {
  disparity == disparity && disparity >= minimum && disparity <= maximum
}

///|
pub fn disparity_valid_indices(
  disparities : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<disparities.length() {
    if disparity_is_valid(disparities[i], minimum, maximum) {
      result.push(i)
    }
  }
  result
}

///|
pub fn disparity_mean(
  disparities : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Double {
  let indices = disparity_valid_indices(disparities, minimum, maximum)
  if indices.length() == 0 {
    0.0
  } else {
    let mut result = 0.0
    for index in indices {
      result += disparities[index]
    }
    result / indices.length().to_double()
  }
}

///|
pub fn disparity_variance(
  disparities : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Double {
  let mean = disparity_mean(disparities, minimum, maximum)
  let indices = disparity_valid_indices(disparities, minimum, maximum)
  if indices.length() == 0 {
    0.0
  } else {
    let mut result = 0.0
    for index in indices {
      let d = disparities[index] - mean
      result += d * d
    }
    result / indices.length().to_double()
  }
}

///|
pub fn disparity_confidence(
  disparity : Double,
  minimum : Double,
  maximum : Double,
) -> Double {
  if maximum <= minimum {
    0.0
  } else {
    let center = (minimum + maximum) / 2.0
    let half = (maximum - minimum) / 2.0
    (1.0 - (disparity - center).abs() / half).max(0.0).min(1.0)
  }
}

///|
pub fn stereo_depth_gradient(
  disparities : ArrayView[Double],
  baseline : Double,
  focal : Double,
) -> Array[Double] {
  let depths = stereo_depths2(disparities, baseline, focal)
  let result : Array[Double] = []
  for i in 0..<depths.length() {
    if i == 0 {
      result.push(0.0)
    } else {
      result.push(depths[i] - depths[i - 1])
    }
  }
  result
}

///|
pub fn stereo_depth_smoothness(
  disparities : ArrayView[Double],
  baseline : Double,
  focal : Double,
) -> Double {
  let gradient = stereo_depth_gradient(disparities, baseline, focal)
  if gradient.length() == 0 {
    0.0
  } else {
    let mut sum = 0.0
    for value in gradient {
      sum += value.abs()
    }
    sum / gradient.length().to_double()
  }
}

///|
pub fn stereo_depth_clamp(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for depth in depths {
    result.push(depth.max(minimum).min(maximum))
  }
  result
}

///|
pub fn stereo_depth_valid_mask(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for depth in depths {
    result.push(depth > 0.0 && depth >= minimum && depth <= maximum)
  }
  result
}

///|
pub fn stereo_depth_percentile(
  depths : ArrayView[Double],
  probability : Double,
) -> Double raise @core.GeometryError {
  @core.quantile_linear(depths, probability)
}

///|
pub fn stereo_baseline_focal_product(
  baseline : Double,
  focal : Double,
) -> Double {
  baseline.max(0.0) * focal.max(0.0)
}

///|
pub fn stereo_depth_error_bound(
  disparity : Double,
  error : Double,
  baseline : Double,
  focal : Double,
) -> Double {
  disparity_error_to_depth_error(disparity, error, baseline, focal)
}

///|
pub fn stereo_scan_best_disparity(
  disparities : ArrayView[Double],
  scores : ArrayView[Double],
) -> Double? {
  let count = disparities.length().min(scores.length())
  if count == 0 {
    return None
  }
  let mut best = 0
  for i in 1..<count {
    if scores[i] > scores[best] {
      best = i
    }
  }
  Some(disparities[best])
}

///|
pub fn stereo_scan_best_score(scores : ArrayView[Double]) -> Double {
  if scores.length() == 0 {
    0.0
  } else {
    let mut result = scores[0]
    for score in scores {
      result = result.max(score)
    }
    result
  }
}
