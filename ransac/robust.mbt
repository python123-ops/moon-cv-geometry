///|
pub fn RansacConfig::validated(
  config : RansacConfig,
  data_size~ : Int,
) -> RansacConfig raise @core.GeometryError {
  if data_size <= 0 {
    raise @core.GeometryError::NotEnoughPoints("RANSAC data must not be empty")
  }
  if config.iterations <= 0 {
    raise @core.GeometryError::DegenerateInput(
      "RANSAC iterations must be positive",
    )
  }
  if config.threshold <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "RANSAC threshold must be positive",
    )
  }
  if config.min_inliers < 1 || config.min_inliers > data_size {
    raise @core.GeometryError::DegenerateInput(
      "RANSAC min_inliers is outside data size",
    )
  }
  config
}

///|
pub fn InlierMask::count(mask : InlierMask) -> Int {
  let mut result = 0
  for value in mask.values {
    if value {
      result += 1
    }
  }
  result
}

///|
pub fn InlierMask::indices(mask : InlierMask) -> Array[Int] {
  let result : Array[Int] = []
  for i in 0..<mask.values.length() {
    if mask.values[i] {
      result.push(i)
    }
  }
  result
}

///|
pub fn[T] RansacResult::outlier_count(result : RansacResult[T]) -> Int {
  result.inliers.length() - result.inlier_count
}

///|
pub fn[T] RansacResult::is_confident(
  result : RansacResult[T],
  minimum_ratio? : Double = 0.5,
) -> Bool {
  result.inlier_ratio() >= minimum_ratio
}

///|
pub fn adaptive_iteration_bound(
  inlier_ratio~ : Double,
  sample_size~ : Int,
  confidence? : Double = 0.99,
) -> Int raise @core.GeometryError {
  if inlier_ratio <= 0.0 ||
    inlier_ratio > 1.0 ||
    sample_size <= 0 ||
    confidence <= 0.0 ||
    confidence >= 1.0 {
    raise @core.GeometryError::DegenerateInput(
      "invalid adaptive RANSAC parameters",
    )
  }
  let mut success = 1.0
  for _ in 0..<sample_size {
    success *= inlier_ratio
  }
  let failure = 1.0 - success
  if failure <= 0.000000000001 {
    1
  } else {
    let mut probability = 1.0
    let mut answer = 1
    while answer < 1000000 && probability > 1.0 - confidence {
      probability *= failure
      answer += 1
    }
    answer
  }
}

///|
pub fn threshold_from_mad(
  residuals : ArrayView[Double],
  multiplier? : Double = 2.5,
) -> Double raise @core.GeometryError {
  if multiplier <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "MAD multiplier must be positive",
    )
  }
  let scale = @core.robust_scale(residuals)
  let center = @core.median(residuals)
  center + multiplier * 1.4826 * scale
}

///|
pub fn score_residuals(
  residuals : ArrayView[Double],
  threshold~ : Double,
) -> RansacResult[Array[Double]] raise @core.GeometryError {
  if threshold <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "residual threshold must be positive",
    )
  }
  let mask : Array[Bool] = []
  let mut count = 0
  let mut score = 0.0
  for residual in residuals {
    let ok = residual <= threshold
    mask.push(ok)
    if ok {
      count += 1
      score += residual
    }
  }
  {
    model: residuals.to_owned(),
    inliers: InlierMask::{ values: mask, },
    inlier_count: count,
    score,
  }
}

///|
pub fn tukey_weight(residual~ : Double, cutoff~ : Double) -> Double {
  if cutoff <= 0.0 {
    0.0
  } else {
    let u = residual / cutoff
    if @core.abs(u) >= 1.0 {
      0.0
    } else {
      let v = 1.0 - u * u
      v * v
    }
  }
}

///|
pub fn huber_loss(residual~ : Double, delta? : Double = 1.0) -> Double {
  let a = @core.abs(residual)
  if a <= delta {
    0.5 * a * a
  } else {
    delta * (a - 0.5 * delta)
  }
}

///|
pub fn robust_cost(
  residuals : ArrayView[Double],
  delta? : Double = 1.0,
) -> Double {
  let mut total = 0.0
  for residual in residuals {
    total += huber_loss(residual~, delta~)
  }
  total
}

///|
pub fn consensus_ratio(mask : InlierMask) -> Double {
  if mask.length() == 0 {
    0.0
  } else {
    Double::from_int(mask.count()) / Double::from_int(mask.length())
  }
}

///|
pub fn deterministic_indices(
  length~ : Int,
  count~ : Int,
  seed~ : UInt,
) -> Array[Int] raise @core.GeometryError {
  if length <= 0 || count <= 0 || count > length {
    raise @core.GeometryError::DegenerateInput("sample dimensions are invalid")
  }
  let result : Array[Int] = []
  let mut state = seed
  for i in 0..<count {
    state = lcg_next(state + i.reinterpret_as_uint())
    let index = pick_index(state, length)
    if !result.contains(index) {
      result.push(index)
    } else {
      let mut candidate = (index + 1) % length
      while result.contains(candidate) {
        candidate = (candidate + 1) % length
      }
      result.push(candidate)
    }
  }
  result
}

///|
pub fn residual_quantiles(
  residuals : ArrayView[Double],
) -> (@core.Point3, Double) raise @core.GeometryError {
  let p50 = @core.percentile(residuals, fraction=0.5)
  let p90 = @core.percentile(residuals, fraction=0.9)
  let p99 = @core.percentile(residuals, fraction=0.99)
  (@core.Point3::new(x=p50, y=p90, z=p99), @core.robust_scale(residuals))
}
