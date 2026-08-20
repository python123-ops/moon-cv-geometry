///|
/// Export and validation helpers for point-cloud service boundaries.
pub fn point_cloud_to_flat(points : ArrayView[Point3]) -> Array[Double] {
  let result : Array[Double] = []
  for point in points {
    result.push(point.x)
    result.push(point.y)
    result.push(point.z)
  }
  result
}

///|
pub fn point_cloud_from_flat(values : ArrayView[Double]) -> Array[Point3] {
  let result : Array[Point3] = []
  let count = values.length() / 3
  for i in 0..<count {
    result.push(
      Point3::new(x=values[i * 3], y=values[i * 3 + 1], z=values[i * 3 + 2]),
    )
  }
  result
}

///|
pub fn point_cloud_flat_dimension(values : ArrayView[Double]) -> Int {
  values.length() / 3
}

///|
pub fn point_cloud_flat_remainder(values : ArrayView[Double]) -> Int {
  values.length() % 3
}

///|
pub fn point_cloud_flat_is_valid(values : ArrayView[Double]) -> Bool {
  values.length() % 3 == 0
}

///|
pub fn point_cloud_count_finite(points : ArrayView[Point3]) -> Int {
  let mut result = 0
  for point in points {
    if !point.x.is_nan() && !point.y.is_nan() && !point.z.is_nan() {
      result += 1
    }
  }
  result
}

///|
pub fn point_cloud_finite_ratio(points : ArrayView[Point3]) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    point_cloud_count_finite(points).to_double() / points.length().to_double()
  }
}

///|
pub fn point_cloud_validate(
  points : ArrayView[Point3],
  minimum_count : Int,
  minimum_finite_ratio : Double,
) -> Bool {
  points.length() >= minimum_count.max(0) &&
  point_cloud_finite_ratio(points) >= minimum_finite_ratio
}

///|
pub fn point_cloud_json_number(value : Double) -> String {
  if value.is_nan() {
    "null"
  } else {
    value.to_string()
  }
}

///|
pub fn point_cloud_csv_row(point : Point3) -> String {
  point_cloud_json_number(point.x) +
  "," +
  point_cloud_json_number(point.y) +
  "," +
  point_cloud_json_number(point.z)
}

///|
pub fn point_cloud_csv(points : ArrayView[Point3]) -> String {
  let mut result = "x,y,z"
  for point in points {
    result += "\n" + point_cloud_csv_row(point)
  }
  result
}

///|
pub fn point_cloud_checksum(points : ArrayView[Point3]) -> Double {
  let mut result = 0.0
  for i in 0..<points.length() {
    let point = points[i]
    result += (i + 1).to_double() * (point.x + point.y * 3.0 + point.z * 7.0)
  }
  result
}

///|
pub fn point_cloud_checksum_matches(
  points : ArrayView[Point3],
  checksum : Double,
  tolerance : Double,
) -> Bool {
  (point_cloud_checksum(points) - checksum).abs() <= tolerance.max(0.0)
}

///|
pub fn point_cloud_batch_checksums(
  batches : ArrayView[Array[Point3]],
) -> Array[Double] {
  let result : Array[Double] = []
  for batch in batches {
    result.push(point_cloud_checksum(batch))
  }
  result
}

///|
pub fn point_cloud_batch_total(batches : ArrayView[Array[Point3]]) -> Int {
  let mut result = 0
  for batch in batches {
    result += batch.length()
  }
  result
}

///|
pub fn point_cloud_batch_flatten(
  batches : ArrayView[Array[Point3]],
) -> Array[Point3] {
  let result : Array[Point3] = []
  for batch in batches {
    for point in batch {
      result.push(point)
    }
  }
  result
}

///|
pub fn point_cloud_batch_nonempty(
  batches : ArrayView[Array[Point3]],
) -> Array[Array[Point3]] {
  let result : Array[Array[Point3]] = []
  for batch in batches {
    if batch.length() > 0 {
      result.push(batch)
    }
  }
  result
}

///|
pub fn point_cloud_batch_largest(
  batches : ArrayView[Array[Point3]],
) -> Array[Point3] {
  if batches.length() == 0 {
    []
  } else {
    let mut result = batches[0]
    for batch in batches[1:] {
      if batch.length() > result.length() {
        result = batch
      }
    }
    result
  }
}

///|
pub fn point_cloud_batch_smallest(
  batches : ArrayView[Array[Point3]],
) -> Array[Point3] {
  if batches.length() == 0 {
    []
  } else {
    let mut result = batches[0]
    for batch in batches[1:] {
      if batch.length() < result.length() {
        result = batch
      }
    }
    result
  }
}

///|
pub fn point_cloud_batch_quality(
  batches : ArrayView[Array[Point3]],
  minimum_count : Int,
  maximum_radius : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for batch in batches {
    result.push(point_cloud_quality_score(batch, minimum_count, maximum_radius))
  }
  result
}

///|
pub fn point_cloud_quality_mean(scores : ArrayView[Double]) -> Double {
  mean(scores) catch {
    _ => 0.0
  }
}

///|
pub fn point_cloud_quality_minimum(scores : ArrayView[Double]) -> Double {
  if scores.length() == 0 {
    0.0
  } else {
    let mut result = scores[0]
    for score in scores {
      result = result.min(score)
    }
    result
  }
}

///|
pub fn point_cloud_quality_maximum(scores : ArrayView[Double]) -> Double {
  let mut result = 0.0
  for score in scores {
    result = result.max(score)
  }
  result
}

///|
pub fn point_cloud_quality_pass_count(
  scores : ArrayView[Double],
  threshold : Double,
) -> Int {
  let mut result = 0
  for score in scores {
    if score >= threshold {
      result += 1
    }
  }
  result
}

///|
pub fn point_cloud_quality_pass_ratio(
  scores : ArrayView[Double],
  threshold : Double,
) -> Double {
  if scores.length() == 0 {
    0.0
  } else {
    point_cloud_quality_pass_count(scores, threshold).to_double() /
    scores.length().to_double()
  }
}

///|
pub fn point_cloud_quality_label(score : Double) -> String {
  if score >= 0.8 {
    "good"
  } else if score >= 0.5 {
    "review"
  } else {
    "poor"
  }
}

///|
pub fn point_cloud_quality_labels(scores : ArrayView[Double]) -> Array[String] {
  let result : Array[String] = []
  for score in scores {
    result.push(point_cloud_quality_label(score))
  }
  result
}

///|
pub fn point_cloud_quality_weighted(
  scores : ArrayView[Double],
  weights : ArrayView[Double],
) -> Double {
  let count = scores.length().min(weights.length())
  let mut total = 0.0
  let mut scale = 0.0
  for i in 0..<count {
    let weight = weights[i].max(0.0)
    total += scores[i] * weight
    scale += weight
  }
  if scale <= 0.0 {
    0.0
  } else {
    total / scale
  }
}

///|
pub fn point_cloud_quality_gap(
  before : ArrayView[Double],
  after : ArrayView[Double],
) -> Double {
  point_cloud_quality_mean(after) - point_cloud_quality_mean(before)
}

///|
pub fn point_cloud_quality_improved(
  before : ArrayView[Double],
  after : ArrayView[Double],
  tolerance : Double,
) -> Bool {
  point_cloud_quality_gap(before, after) >= tolerance
}

///|
pub fn point_cloud_quality_report(
  points : ArrayView[Point3],
  minimum_count : Int,
  maximum_radius : Double,
) -> String {
  let summary = point_cloud_pipeline_summary(points)
  let score = point_cloud_quality_score(points, minimum_count, maximum_radius)
  summary.count.to_string() +
  "," +
  summary.radius.to_string() +
  "," +
  score.to_string() +
  "," +
  point_cloud_quality_label(score)
}
