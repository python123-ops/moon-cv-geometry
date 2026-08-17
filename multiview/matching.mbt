///|
pub(all) struct PointMatch {
  left_index : Int
  right_index : Int
  distance : Double
} derive(Debug, Eq)

///|
pub fn nearest_point(
  point : @core.Point2,
  candidates : ArrayView[@core.Point2],
) -> PointMatch raise @core.GeometryError {
  if candidates.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints("nearest point needs candidates")
  }
  let mut best = 0
  let mut best_distance = point.minus(candidates[0]).norm()
  for i in 1..<candidates.length() {
    let current = point.minus(candidates[i]).norm()
    if current < best_distance {
      best = i
      best_distance = current
    }
  }
  { left_index: -1, right_index: best, distance: best_distance }
}

///|
pub fn nearest_matches(
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
  maximum_distance~ : Double,
) -> Array[PointMatch] raise @core.GeometryError {
  if maximum_distance <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "match distance must be positive",
    )
  }
  let result : Array[PointMatch] = []
  for i in 0..<left.length() {
    let item = nearest_point(left[i], right)
    if item.distance <= maximum_distance {
      result.push({
        left_index: i,
        right_index: item.right_index,
        distance: item.distance,
      })
    }
  }
  result
}

///|
pub fn mutual_matches(
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
  maximum_distance~ : Double,
) -> Array[PointMatch] raise @core.GeometryError {
  let result : Array[PointMatch] = []
  let forward = nearest_matches(left, right, maximum_distance~)
  for item in forward {
    let backward = nearest_point(right[item.right_index], left)
    if backward.right_index == item.left_index {
      result.push(item)
    }
  }
  result
}

///|
pub fn match_distance_statistics(
  matches : ArrayView[PointMatch],
) -> (Double, Double) raise @core.GeometryError {
  if matches.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints("match statistics need matches")
  }
  let values : Array[Double] = []
  for item in matches {
    values.push(item.distance)
  }
  (@core.mean(values), @core.median(values))
}

///|
pub fn filter_matches(
  matches : ArrayView[PointMatch],
  maximum_distance~ : Double,
) -> Array[PointMatch] {
  let result : Array[PointMatch] = []
  for item in matches {
    if item.distance <= maximum_distance {
      result.push(item)
    }
  }
  result
}

///|
pub fn match_indices(
  matches : ArrayView[PointMatch],
) -> (Array[Int], Array[Int]) {
  let left : Array[Int] = []
  let right : Array[Int] = []
  for item in matches {
    left.push(item.left_index)
    right.push(item.right_index)
  }
  (left, right)
}

///|
pub fn unique_right_matches(
  matches : ArrayView[PointMatch],
) -> Array[PointMatch] {
  let result : Array[PointMatch] = []
  for item in matches {
    let mut exists = false
    for previous in result {
      if previous.right_index == item.right_index {
        exists = true
      }
    }
    if !exists {
      result.push(item)
    }
  }
  result
}
