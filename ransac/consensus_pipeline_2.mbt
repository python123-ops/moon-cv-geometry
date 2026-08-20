///|
/// Candidate consensus summary used for deterministic model ranking.
pub(all) struct ConsensusCandidate2 {
  inliers : Int
  total : Int
  ratio : Double
  score : Double
  residual_sum : Double
  threshold : Double
} derive(Debug, Eq)

///|
pub fn consensus_candidate(
  residuals : ArrayView[Double],
  threshold : Double,
) -> ConsensusCandidate2 {
  let mut inliers = 0
  let mut score = 0.0
  let mut residual_sum = 0.0
  for residual in residuals {
    let value = residual.abs()
    residual_sum += value
    if value <= threshold {
      inliers += 1
      score += threshold - value
    }
  }
  {
    inliers,
    total: residuals.length(),
    ratio: if residuals.length() == 0 {
      0.0
    } else {
      inliers.to_double() / residuals.length().to_double()
    },
    score,
    residual_sum,
    threshold,
  }
}

///|
pub fn evaluate_consensus_candidates(
  residual_sets : ArrayView[Array[Double]],
  threshold~ : Double,
) -> Array[ConsensusCandidate2] {
  let result : Array[ConsensusCandidate2] = []
  for residuals in residual_sets {
    result.push(consensus_candidate(residuals, threshold))
  }
  result
}

///|
pub fn select_best_candidate(
  candidates : ArrayView[ConsensusCandidate2],
) -> ConsensusCandidate2 {
  if candidates.length() == 0 {
    {
      inliers: 0,
      total: 0,
      ratio: 0.0,
      score: 0.0,
      residual_sum: 0.0,
      threshold: 0.0,
    }
  } else {
    let mut best = candidates[0]
    for candidate in candidates[1:] {
      if consensus_candidate_better(candidate, best) {
        best = candidate
      }
    }
    best
  }
}

///|
pub fn consensus_candidate_better(
  left : ConsensusCandidate2,
  right : ConsensusCandidate2,
) -> Bool {
  left.inliers > right.inliers ||
  (left.inliers == right.inliers && left.score > right.score) ||
  (
    left.inliers == right.inliers &&
    left.score == right.score &&
    left.residual_sum < right.residual_sum
  )
}

///|
pub fn rank_consensus_candidates(
  candidates : ArrayView[ConsensusCandidate2],
) -> Array[ConsensusCandidate2] {
  let result = candidates.to_owned()
  result.sort_by(fn(left, right) {
    if consensus_candidate_better(left, right) {
      -1
    } else if consensus_candidate_better(right, left) {
      1
    } else {
      0
    }
  })
  result
}

///|
pub fn candidate_margin(
  best : ConsensusCandidate2,
  second : ConsensusCandidate2,
) -> Double {
  best.score - second.score
}

///|
pub fn candidate_is_confident(
  best : ConsensusCandidate2,
  second : ConsensusCandidate2,
  minimum_margin : Double,
) -> Bool {
  best.inliers > 0 && candidate_margin(best, second) >= minimum_margin
}

///|
pub fn candidate_mask(
  candidate : ConsensusCandidate2,
  residuals : ArrayView[Double],
) -> Array[Bool] {
  let result : Array[Bool] = []
  for residual in residuals {
    result.push(residual.abs() <= candidate.threshold)
  }
  result
}

///|
pub fn candidate_inlier_residuals(
  candidate : ConsensusCandidate2,
  residuals : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  for residual in residuals {
    if residual.abs() <= candidate.threshold {
      result.push(residual)
    }
  }
  result
}

///|
pub fn candidate_outlier_residuals(
  candidate : ConsensusCandidate2,
  residuals : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  for residual in residuals {
    if residual.abs() > candidate.threshold {
      result.push(residual)
    }
  }
  result
}

///|
pub fn candidate_refined_threshold(
  candidate : ConsensusCandidate2,
  residuals : ArrayView[Double],
  multiplier : Double,
  minimum : Double,
) -> Double raise @core.GeometryError {
  let inliers = candidate_inlier_residuals(candidate, residuals)
  (multiplier * @core.median_absolute_deviation2(inliers)).max(minimum)
}

///|
pub fn candidate_score_per_point(candidate : ConsensusCandidate2) -> Double {
  if candidate.total == 0 {
    0.0
  } else {
    candidate.score / candidate.total.to_double()
  }
}

///|
pub fn candidate_support_score(
  candidate : ConsensusCandidate2,
  expected_minimum : Int,
) -> Double {
  if expected_minimum <= 0 {
    candidate.ratio
  } else {
    (candidate.inliers.to_double() / expected_minimum.to_double()).min(1.0)
  }
}
