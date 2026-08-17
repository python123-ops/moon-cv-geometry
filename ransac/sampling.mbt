///|
pub fn sample_without_replacement(
  length~ : Int,
  count~ : Int,
  seed~ : UInt,
) -> Array[Int] raise @core.GeometryError {
  deterministic_indices(length~, count~, seed~)
}

///|
pub fn sample_probability(
  inlier_ratio~ : Double,
  sample_size~ : Int,
) -> Double raise @core.GeometryError {
  if inlier_ratio < 0.0 || inlier_ratio > 1.0 || sample_size <= 0 {
    raise @core.GeometryError::DegenerateInput(
      "invalid sample probability parameters",
    )
  }
  let mut result = 1.0
  for _ in 0..<sample_size {
    result *= inlier_ratio
  }
  result
}

///|
pub fn expected_successes(
  iterations~ : Int,
  inlier_ratio~ : Double,
  sample_size~ : Int,
) -> Double raise @core.GeometryError {
  if iterations < 0 {
    raise @core.GeometryError::DegenerateInput(
      "iterations must be non-negative",
    )
  }
  let probability = sample_probability(inlier_ratio~, sample_size~)
  let mut failure = 1.0
  for _ in 0..<iterations {
    failure *= 1.0 - probability
  }
  1.0 - failure
}

///|
pub fn residual_threshold_from_sigma(
  sigma~ : Double,
  confidence_multiplier? : Double = 2.5,
) -> Double raise @core.GeometryError {
  if sigma < 0.0 || confidence_multiplier <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "sigma threshold parameters are invalid",
    )
  }
  sigma * confidence_multiplier
}

///|
pub fn select_best_score(
  scores : ArrayView[Double],
) -> Int raise @core.GeometryError {
  if scores.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints("scores must not be empty")
  }
  let mut best = 0
  for i in 1..<scores.length() {
    if scores[i] < scores[best] {
      best = i
    }
  }
  best
}
