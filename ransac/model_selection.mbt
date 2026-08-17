///|
pub fn[T] better_result(
  candidate : RansacResult[T],
  incumbent : RansacResult[T],
) -> Bool {
  candidate.inlier_count > incumbent.inlier_count ||
  (
    candidate.inlier_count == incumbent.inlier_count &&
    candidate.score < incumbent.score
  )
}

///|
pub fn[T] normalized_score(result : RansacResult[T]) -> Double {
  if result.inliers.length() == 0 {
    0.0
  } else {
    result.inlier_ratio() /
    (1.0 + result.score / Double::from_int(result.inliers.length()))
  }
}

///|
pub fn[T] rank_results(results : ArrayView[RansacResult[T]]) -> Array[Int] {
  let indices : Array[Int] = []
  for i in 0..<results.length() {
    indices.push(i)
  }
  for i in 0..<indices.length() {
    for j in (i + 1)..<indices.length() {
      if normalized_score(results[indices[j]]) >
        normalized_score(results[indices[i]]) {
        let temp = indices[i]
        indices[i] = indices[j]
        indices[j] = temp
      }
    }
  }
  indices
}

///|
pub fn minimum_consensus_count(
  total~ : Int,
  ratio~ : Double,
) -> Int raise @core.GeometryError {
  if total <= 0 || ratio < 0.0 || ratio > 1.0 {
    raise @core.GeometryError::DegenerateInput(
      "consensus parameters are invalid",
    )
  }
  (Double::from_int(total) * ratio).ceil().to_int()
}

///|
pub fn residual_is_inlier(residual~ : Double, threshold~ : Double) -> Bool {
  residual >= 0.0 && threshold > 0.0 && residual <= threshold
}
