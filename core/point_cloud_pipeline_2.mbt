///|
/// Production point-cloud operators used by calibration and reconstruction.
///
/// The functions in this file deliberately operate on plain arrays.  This keeps
/// the package usable in Wasm, native batch tools, and embedded applications
/// without forcing callers to adopt a storage backend.
pub(all) struct PointCloudPipelineSummary {
  count : Int
  centroid : Point3
  minimum : Point3
  maximum : Point3
  radius : Double
  mean_distance : Double
  maximum_distance : Double
} derive(Debug, Eq)

///|
fn point3_zero() -> Point3 {
  Point3::new(x=0.0, y=0.0, z=0.0)
}

///|
fn point3_add(a : Point3, b : Point3) -> Point3 {
  Point3::new(x=a.x + b.x, y=a.y + b.y, z=a.z + b.z)
}

///|
fn point3_scale(a : Point3, scale : Double) -> Point3 {
  Point3::new(x=a.x * scale, y=a.y * scale, z=a.z * scale)
}

///|
fn point3_min(a : Point3, b : Point3) -> Point3 {
  Point3::new(x=a.x.min(b.x), y=a.y.min(b.y), z=a.z.min(b.z))
}

///|
fn point3_max(a : Point3, b : Point3) -> Point3 {
  Point3::new(x=a.x.max(b.x), y=a.y.max(b.y), z=a.z.max(b.z))
}

///|
pub fn point_cloud_centroid(points : ArrayView[Point3]) -> Point3 {
  if points.length() == 0 {
    return point3_zero()
  }
  let mut sum = point3_zero()
  for point in points {
    sum = point3_add(sum, point)
  }
  point3_scale(sum, 1.0 / points.length().to_double())
}

///|
pub fn point_cloud_bounds(points : ArrayView[Point3]) -> (Point3, Point3) {
  if points.length() == 0 {
    return (point3_zero(), point3_zero())
  }
  let mut minimum = points[0]
  let mut maximum = points[0]
  for point in points {
    minimum = point3_min(minimum, point)
    maximum = point3_max(maximum, point)
  }
  (minimum, maximum)
}

///|
pub fn point_cloud_radius(
  points : ArrayView[Point3],
  center : Point3,
) -> Double {
  let mut result = 0.0
  for point in points {
    result = result.max(distance3(point, center))
  }
  result
}

///|
pub fn point_cloud_mean_distance(
  points : ArrayView[Point3],
  center : Point3,
) -> Double {
  if points.length() == 0 {
    return 0.0
  }
  let mut total = 0.0
  for point in points {
    total += distance3(point, center)
  }
  total / points.length().to_double()
}

///|
pub fn point_cloud_pipeline_summary(
  points : ArrayView[Point3],
) -> PointCloudPipelineSummary {
  let centroid = point_cloud_centroid(points)
  let (minimum, maximum) = point_cloud_bounds(points)
  {
    count: points.length(),
    centroid,
    minimum,
    maximum,
    radius: point_cloud_radius(points, centroid),
    mean_distance: point_cloud_mean_distance(points, centroid),
    maximum_distance: point_cloud_radius(points, centroid),
  }
}

///|
pub fn point_cloud_translate(
  points : ArrayView[Point3],
  offset : Vec3,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(point.translate(offset))
  }
  result
}

///|
pub fn point_cloud_scale(
  points : ArrayView[Point3],
  scale : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(point3_scale(point, scale))
  }
  result
}

///|
pub fn point_cloud_centered(points : ArrayView[Point3]) -> Array[Point3] {
  let center = point_cloud_centroid(points)
  point_cloud_translate(
    points,
    Vec3::new(x=-center.x, y=-center.y, z=-center.z),
  )
}

///|
pub fn point_cloud_normalize_radius(
  points : ArrayView[Point3],
) -> Array[Point3] {
  let center = point_cloud_centroid(points)
  let radius = point_cloud_radius(points, center)
  if radius <= 0.000000000001 {
    point_cloud_centered(points)
  } else {
    point_cloud_scale(point_cloud_centered(points), 1.0 / radius)
  }
}

///|
pub fn point_cloud_filter_radius(
  points : ArrayView[Point3],
  center : Point3,
  radius : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  let limit = radius.max(0.0)
  for point in points {
    if distance3(point, center) <= limit {
      result.push(point)
    }
  }
  result
}

///|
pub fn point_cloud_filter_box(
  points : ArrayView[Point3],
  minimum : Point3,
  maximum : Point3,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    if point.x >= minimum.x &&
      point.x <= maximum.x &&
      point.y >= minimum.y &&
      point.y <= maximum.y &&
      point.z >= minimum.z &&
      point.z <= maximum.z {
      result.push(point)
    }
  }
  result
}

///|
pub fn point_cloud_distances(
  points : ArrayView[Point3],
  center : Point3,
) -> Array[Double] {
  let result : Array[Double] = []
  for point in points {
    result.push(distance3(point, center))
  }
  result
}

///|
pub fn point_cloud_squared_distances(
  points : ArrayView[Point3],
  center : Point3,
) -> Array[Double] {
  let result : Array[Double] = []
  for point in points {
    result.push(point.minus(center).norm2())
  }
  result
}

///|
pub fn point_cloud_nearest_distance(
  point : Point3,
  points : ArrayView[Point3],
) -> Double {
  if points.length() == 0 {
    return 0.0
  }
  let mut result = distance3(point, points[0])
  for candidate in points[1:] {
    result = result.min(distance3(point, candidate))
  }
  result
}

///|
pub fn point_cloud_nearest_distances(
  points : ArrayView[Point3],
) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<points.length() {
    let mut best = 0.0
    let mut initialized = false
    for j in 0..<points.length() {
      if i != j {
        let value = distance3(points[i], points[j])
        if !initialized || value < best {
          best = value
          initialized = true
        }
      }
    }
    result.push(if initialized { best } else { 0.0 })
  }
  result
}

///|
pub fn point_cloud_pairwise_distances(
  points : ArrayView[Point3],
) -> Array[Double] {
  let result : Array[Double] = []
  for i in 0..<points.length() {
    for j in (i + 1)..<points.length() {
      result.push(distance3(points[i], points[j]))
    }
  }
  result
}

///|
pub fn point_cloud_pairwise_mean(points : ArrayView[Point3]) -> Double {
  let values = point_cloud_pairwise_distances(points)
  mean(values) catch {
    _ => 0.0
  }
}

///|
pub fn point_cloud_pairwise_maximum(points : ArrayView[Point3]) -> Double {
  let mut result = 0.0
  for value in point_cloud_pairwise_distances(points) {
    result = result.max(value)
  }
  result
}

///|
pub fn point_cloud_count_within(
  points : ArrayView[Point3],
  center : Point3,
  radius : Double,
) -> Int {
  let mut count = 0
  for point in points {
    if distance3(point, center) <= radius.max(0.0) {
      count += 1
    }
  }
  count
}

///|
pub fn point_cloud_density(
  points : ArrayView[Point3],
  center : Point3,
  radius : Double,
) -> Double {
  let r = radius.max(0.0)
  if r <= 0.0 {
    0.0
  } else {
    point_cloud_count_within(points, center, r).to_double() /
    (4.0 / 3.0 * 3.141592653589793 * r * r * r)
  }
}

///|
pub fn point_cloud_remove_duplicates(
  points : ArrayView[Point3],
  tolerance : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  let limit = tolerance.max(0.0)
  for point in points {
    let mut duplicate = false
    for existing in result {
      if distance3(point, existing) <= limit {
        duplicate = true
      }
    }
    if !duplicate {
      result.push(point)
    }
  }
  result
}

///|
pub fn point_cloud_merge(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
) -> Array[Point3] {
  let result = left.to_owned()
  for point in right {
    result.push(point)
  }
  result
}

///|
pub fn point_cloud_chunk(
  points : ArrayView[Point3],
  chunk_size : Int,
) -> Array[Array[Point3]] {
  let result : Array[Array[Point3]] = []
  let width = chunk_size.max(1)
  let mut start = 0
  while start < points.length() {
    let end = (start + width).min(points.length())
    let chunk : Array[Point3] = []
    for i in start..<end {
      chunk.push(points[i])
    }
    result.push(chunk)
    start = end
  }
  result
}

///|
pub fn point_cloud_take(
  points : ArrayView[Point3],
  count : Int,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for i in 0..<count.max(0).min(points.length()) {
    result.push(points[i])
  }
  result
}

///|
pub fn point_cloud_drop(
  points : ArrayView[Point3],
  count : Int,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for i in count.max(0).min(points.length())..<points.length() {
    result.push(points[i])
  }
  result
}

///|
pub fn point_cloud_stride(
  points : ArrayView[Point3],
  stride : Int,
) -> Array[Point3] {
  let result : Array[Point3] = []
  let step = stride.max(1)
  for i in 0..<points.length() {
    if i % step == 0 {
      result.push(points[i])
    }
  }
  result
}

///|
pub fn point_cloud_interleave(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
) -> Array[Point3] {
  let result : Array[Point3] = []
  let count = left.length().max(right.length())
  for i in 0..<count {
    if i < left.length() {
      result.push(left[i])
    }
    if i < right.length() {
      result.push(right[i])
    }
  }
  result
}

///|
pub fn point_cloud_lerp(a : Point3, b : Point3, amount : Double) -> Point3 {
  let t = amount.max(0.0).min(1.0)
  Point3::new(
    x=a.x + (b.x - a.x) * t,
    y=a.y + (b.y - a.y) * t,
    z=a.z + (b.z - a.z) * t,
  )
}

///|
pub fn point_cloud_resample_line(
  start : Point3,
  end : Point3,
  count : Int,
) -> Array[Point3] {
  let result : Array[Point3] = []
  let samples = count.max(1)
  if samples == 1 {
    result.push(start)
    return result
  }
  for i in 0..<samples {
    result.push(
      point_cloud_lerp(start, end, i.to_double() / (samples - 1).to_double()),
    )
  }
  result
}

///|
pub fn point_cloud_path_length(points : ArrayView[Point3]) -> Double {
  if points.length() < 2 {
    return 0.0
  }
  let mut result = 0.0
  for i in 0..<(points.length() - 1) {
    result += distance3(points[i], points[i + 1])
  }
  result
}

///|
pub fn point_cloud_is_finite(points : ArrayView[Point3]) -> Bool {
  for point in points {
    if point.x.is_nan() || point.y.is_nan() || point.z.is_nan() {
      return false
    }
  }
  true
}

///|
pub fn point_cloud_axis_range(points : ArrayView[Point3], axis : Int) -> Double {
  let (minimum, maximum) = point_cloud_bounds(points)
  if axis == 0 {
    maximum.x - minimum.x
  } else if axis == 1 {
    maximum.y - minimum.y
  } else {
    maximum.z - minimum.z
  }
}

///|
pub fn point_cloud_axis_values(
  points : ArrayView[Point3],
  axis : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  for point in points {
    result.push(
      if axis == 0 {
        point.x
      } else if axis == 1 {
        point.y
      } else {
        point.z
      },
    )
  }
  result
}

///|
pub fn point_cloud_variance_axis(
  points : ArrayView[Point3],
  axis : Int,
) -> Double {
  variance(point_cloud_axis_values(points, axis)) catch {
    _ => 0.0
  }
}

///|
pub fn point_cloud_voxel_sample(
  points : ArrayView[Point3],
  voxel : Double,
) -> Array[Point3] {
  if points.length() == 0 {
    return []
  }
  if voxel <= 0.0 {
    return points.to_owned()
  }
  let result : Array[Point3] = []
  for point in points {
    let mut occupied = false
    for representative in result {
      let dx = ((point.x - representative.x) / voxel).abs()
      let dy = ((point.y - representative.y) / voxel).abs()
      let dz = ((point.z - representative.z) / voxel).abs()
      if dx < 1.0 && dy < 1.0 && dz < 1.0 {
        occupied = true
      }
    }
    if !occupied {
      result.push(point)
    }
  }
  result
}

///|
pub fn point_cloud_voxel_count(
  points : ArrayView[Point3],
  voxel : Double,
) -> Int {
  point_cloud_voxel_sample(points, voxel).length()
}

///|
pub fn point_cloud_outlier_flags(
  points : ArrayView[Point3],
  threshold : Double,
) -> Array[Bool] {
  let distances = point_cloud_nearest_distances(points)
  let center = mean(distances) catch { _ => 0.0 }
  let spread = (variance(distances) catch { _ => 0.0 }).sqrt()
  let limit = center + threshold.max(0.0) * spread
  let result : Array[Bool] = []
  for distance in distances {
    result.push(distance > limit && spread > 0.0)
  }
  result
}

///|
pub fn point_cloud_remove_outliers(
  points : ArrayView[Point3],
  threshold : Double,
) -> Array[Point3] {
  let flags = point_cloud_outlier_flags(points, threshold)
  let result : Array[Point3] = []
  for i in 0..<points.length() {
    if !flags[i] {
      result.push(points[i])
    }
  }
  result
}

///|
pub fn point_cloud_weighted_centroid(
  points : ArrayView[Point3],
  weights : ArrayView[Double],
) -> Point3 {
  let count = points.length().min(weights.length())
  if count == 0 {
    return point3_zero()
  }
  let mut sum = point3_zero()
  let mut total = 0.0
  for i in 0..<count {
    let weight = weights[i].max(0.0)
    sum = point3_add(sum, point3_scale(points[i], weight))
    total += weight
  }
  if total <= 0.0 {
    point_cloud_centroid(points[:count])
  } else {
    point3_scale(sum, 1.0 / total)
  }
}

///|
pub fn point_cloud_weighted_radius(
  points : ArrayView[Point3],
  weights : ArrayView[Double],
) -> Double {
  point_cloud_radius(points, point_cloud_weighted_centroid(points, weights))
}

///|
pub fn point_cloud_align_centroids(
  source : ArrayView[Point3],
  target : ArrayView[Point3],
) -> Array[Point3] {
  let delta = point_cloud_centroid(target).minus(point_cloud_centroid(source))
  point_cloud_translate(source, delta)
}

///|
pub fn point_cloud_quality_score(
  points : ArrayView[Point3],
  minimum_count : Int,
  maximum_radius : Double,
) -> Double {
  let support = if minimum_count <= 0 {
    1.0
  } else {
    (points.length().to_double() / minimum_count.to_double()).min(1.0)
  }
  let compactness = if maximum_radius <= 0.0 {
    0.0
  } else {
    (maximum_radius / point_cloud_radius(points, point_cloud_centroid(points))).min(
      1.0,
    )
  }
  support * compactness
}
