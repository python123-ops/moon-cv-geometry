///|
pub(all) struct MlesacConfig {
  inlier_scale : Double
  outlier_scale : Double
} derive(Debug, Eq)

///|
pub fn MlesacConfig::new(
  inlier_scale~ : Double,
  outlier_scale~ : Double,
) -> MlesacConfig {
  { inlier_scale, outlier_scale }
}

///|
pub fn MlesacConfig::valid(config : MlesacConfig) -> Bool {
  config.inlier_scale > 0.0 && config.outlier_scale > config.inlier_scale
}

///|
pub fn score_mlesac(
  residuals : ArrayView[Double],
  config : MlesacConfig,
) -> Double {
  if !config.valid() {
    0.0
  } else {
    let mut score = 0.0
    for residual in residuals {
      let inlier = 1.0 / (1.0 + residual / config.inlier_scale)
      let outlier = 1.0 / (1.0 + residual / config.outlier_scale)
      score += inlier - outlier
    }
    score
  }
}

///|
pub fn score_mlesac_with_threshold(
  residuals : ArrayView[Double],
  threshold~ : Double,
  config : MlesacConfig,
) -> Double {
  if threshold <= 0.0 {
    0.0
  } else {
    score_mlesac(residuals, config) -
    threshold * Double::from_int(residuals.length()) * 0.001
  }
}

///|
pub(all) struct ThresholdSweepResult {
  threshold : Double
  inliers : Int
  score : Double
} derive(Debug, Eq)

///|
pub fn sweep_thresholds(
  residuals : ArrayView[Double],
  thresholds : ArrayView[Double],
) -> ThresholdSweepResult {
  let initial = ThresholdSweepResult::{
    threshold: 0.0,
    inliers: -1,
    score: -1.0e100,
  }
  for result = initial, i = 0; i < thresholds.length(); {
    let threshold = thresholds[i]
    let mut count = 0
    for residual in residuals {
      if residual <= threshold {
        count += 1
      }
    }
    let score = Double::from_int(count) - threshold * 0.001
    let next = if count > result.inliers ||
      (count == result.inliers && score > result.score) {
      ThresholdSweepResult::{ threshold, inliers: count, score }
    } else {
      result
    }
    continue next, i + 1
  } nobreak {
    result
  }
}

///|
pub fn ThresholdSweepResult::ratio(
  result : ThresholdSweepResult,
  total : Int,
) -> Double {
  if total <= 0 {
    0.0
  } else {
    Double::from_int(result.inliers) / Double::from_int(total)
  }
}

///|
pub fn ThresholdSweepResult::acceptable(
  result : ThresholdSweepResult,
  total : Int,
  minimum_ratio~ : Double,
) -> Bool {
  result.ratio(total) >= minimum_ratio
}
