///|
/// Baseline statistics for view-center distances.
pub(all) struct BaselineStatistics {
  count : Int
  mean : Double
  minimum : Double
  maximum : Double
  rms : Double
} derive(Debug, Eq)

///|
pub fn baseline_statistics(baselines : ArrayView[Double]) -> BaselineStatistics {
  if baselines.length() == 0 {
    return { count: 0, mean: 0.0, minimum: 0.0, maximum: 0.0, rms: 0.0 }
  }
  let mut sum = 0.0
  let mut square = 0.0
  let mut minimum = baselines[0]
  let mut maximum = baselines[0]
  for baseline in baselines {
    sum += baseline
    square += baseline * baseline
    minimum = minimum.min(baseline)
    maximum = maximum.max(baseline)
  }
  {
    count: baselines.length(),
    mean: sum / baselines.length().to_double(),
    minimum,
    maximum,
    rms: (square / baselines.length().to_double()).sqrt(),
  }
}

///|
pub fn baseline_valid_ratio(
  baselines : ArrayView[Double],
  minimum : Double,
) -> Double {
  if baselines.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for baseline in baselines {
      if baseline >= minimum {
        count += 1
      }
    }
    count.to_double() / baselines.length().to_double()
  }
}

///|
pub fn baseline_pairwise_centers(
  centers : ArrayView[@core.Point3],
) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<centers.length() {
    for j in (i + 1)..<centers.length() {
      result.push(centers[i].minus(centers[j]).norm())
    }
  }
  result
}

///|
pub fn baseline_graph_edges(
  centers : ArrayView[@core.Point3],
  minimum : Double,
) -> Array[(Int, Int)] {
  let result : Array[(Int, Int)] = []
  for i in 0..<centers.length() {
    for j in (i + 1)..<centers.length() {
      if centers[i].minus(centers[j]).norm() >= minimum {
        result.push((i, j))
      }
    }
  }
  result
}

///|
pub fn baseline_condition_score(
  statistics : BaselineStatistics,
  target : Double,
) -> Double {
  if target <= 0.0 || statistics.count == 0 {
    0.0
  } else {
    (statistics.mean / target).min(1.0).max(0.0)
  }
}

///|
pub fn baseline_is_degenerate(
  statistics : BaselineStatistics,
  tolerance : Double,
) -> Bool {
  statistics.count == 0 || statistics.maximum - statistics.minimum <= tolerance
}

///|
pub fn camera_center_distances(
  centers : ArrayView[@core.Point3],
) -> Array[Double] {
  let result : Array[Double] = []
  if centers.length() < 2 {
    return result
  }
  for i in 0..<(centers.length() - 1) {
    result.push(centers[i].minus(centers[i + 1]).norm())
  }
  result
}

///|
pub fn camera_path_length(centers : ArrayView[@core.Point3]) -> Double {
  let mut result = 0.0
  for distance in camera_center_distances(centers) {
    result += distance
  }
  result
}

///|
pub fn camera_path_turn_angles(
  centers : ArrayView[@core.Point3],
) -> Array[Double] raise @core.GeometryError {
  let result : Array[Double] = []
  if centers.length() < 3 {
    return result
  }
  for i in 1..<(centers.length() - 1) {
    let first = centers[i].minus(centers[i - 1]).normalize()
    let second = centers[i + 1].minus(centers[i]).normalize()
    let cosine = first.dot(second).max(-1.0).min(1.0)
    result.push(@math.acos(cosine))
  }
  result
}
