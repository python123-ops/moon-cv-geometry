///|
/// Additional point-cloud transforms for streaming reconstruction jobs.
pub fn point_cloud_reflect_x(points : ArrayView[Point3]) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(Point3::new(x=-point.x, y=point.y, z=point.z))
  }
  result
}

///|
pub fn point_cloud_reflect_y(points : ArrayView[Point3]) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(Point3::new(x=point.x, y=-point.y, z=point.z))
  }
  result
}

///|
pub fn point_cloud_reflect_z(points : ArrayView[Point3]) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(Point3::new(x=point.x, y=point.y, z=-point.z))
  }
  result
}

///|
pub fn point_cloud_axis_scale(
  points : ArrayView[Point3],
  sx : Double,
  sy : Double,
  sz : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(Point3::new(x=point.x * sx, y=point.y * sy, z=point.z * sz))
  }
  result
}

///|
pub fn point_cloud_axis_offset(
  points : ArrayView[Point3],
  ox : Double,
  oy : Double,
  oz : Double,
) -> Array[Point3] {
  point_cloud_translate(points, Vec3::new(x=ox, y=oy, z=oz))
}

///|
pub fn point_cloud_abs(points : ArrayView[Point3]) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(Point3::new(x=point.x.abs(), y=point.y.abs(), z=point.z.abs()))
  }
  result
}

///|
pub fn point_cloud_sign(points : ArrayView[Point3]) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(
      Point3::new(
        x=if point.x < 0.0 { -1.0 } else { 1.0 },
        y=if point.y < 0.0 { -1.0 } else { 1.0 },
        z=if point.z < 0.0 { -1.0 } else { 1.0 },
      ),
    )
  }
  result
}

///|
pub fn point_cloud_axis_minimum(
  points : ArrayView[Point3],
  axis : Int,
) -> Double {
  let (minimum, _) = point_cloud_bounds(points)
  if axis == 0 {
    minimum.x
  } else if axis == 1 {
    minimum.y
  } else {
    minimum.z
  }
}

///|
pub fn point_cloud_axis_maximum(
  points : ArrayView[Point3],
  axis : Int,
) -> Double {
  let (_, maximum) = point_cloud_bounds(points)
  if axis == 0 {
    maximum.x
  } else if axis == 1 {
    maximum.y
  } else {
    maximum.z
  }
}

///|
pub fn point_cloud_axis_mean(points : ArrayView[Point3], axis : Int) -> Double {
  mean(point_cloud_axis_values(points, axis)) catch {
    _ => 0.0
  }
}

///|
pub fn point_cloud_axis_median(
  points : ArrayView[Point3],
  axis : Int,
) -> Double {
  median(point_cloud_axis_values(points, axis)) catch {
    _ => 0.0
  }
}

///|
pub fn point_cloud_axis_quantile(
  points : ArrayView[Point3],
  axis : Int,
  quantile : Double,
) -> Double {
  quantile_linear(point_cloud_axis_values(points, axis), quantile) catch {
    _ => 0.0
  }
}

///|
pub fn point_cloud_axis_center(
  points : ArrayView[Point3],
  axis : Int,
) -> Double {
  (
    point_cloud_axis_minimum(points, axis) +
    point_cloud_axis_maximum(points, axis)
  ) *
  0.5
}

///|
pub fn point_cloud_axis_normalized(
  points : ArrayView[Point3],
  axis : Int,
) -> Array[Double] {
  let center = point_cloud_axis_center(points, axis)
  let scale = point_cloud_axis_range(points, axis)
  let result : Array[Double] = []
  for value in point_cloud_axis_values(points, axis) {
    result.push(if scale <= 0.0 { 0.0 } else { (value - center) / scale })
  }
  result
}

///|
pub fn point_cloud_radius_histogram(
  points : ArrayView[Point3],
  center : Point3,
  bins : Int,
) -> Array[Int] {
  let result = Array::make(bins.max(0), 0)
  let radius = point_cloud_radius(points, center)
  if radius <= 0.0 {
    return result
  }
  for point in points {
    let index = (distance3(point, center) / radius * bins.to_double())
      .to_int()
      .min(result.length() - 1)
      .max(0)
    if result.length() > 0 {
      result[index] += 1
    }
  }
  result
}

///|
pub fn point_cloud_distance_histogram(
  points : ArrayView[Point3],
  bins : Int,
  maximum : Double,
) -> Array[Int] {
  let result = Array::make(bins.max(0), 0)
  if maximum <= 0.0 {
    return result
  }
  for value in point_cloud_pairwise_distances(points) {
    let index = (value / maximum * bins.to_double())
      .to_int()
      .min(result.length() - 1)
      .max(0)
    if result.length() > 0 {
      result[index] += 1
    }
  }
  result
}

///|
pub fn point_cloud_histogram_total(histogram : ArrayView[Int]) -> Int {
  let mut result = 0
  for value in histogram {
    result += value
  }
  result
}

///|
pub fn point_cloud_histogram_peak(histogram : ArrayView[Int]) -> Int {
  let mut result = 0
  for i in 0..<histogram.length() {
    if histogram[i] > histogram[result] {
      result = i
    }
  }
  result
}

///|
pub fn point_cloud_histogram_probability(
  histogram : ArrayView[Int],
) -> Array[Double] {
  let total = point_cloud_histogram_total(histogram).to_double()
  let result : Array[Double] = []
  for value in histogram {
    result.push(if total <= 0.0 { 0.0 } else { value.to_double() / total })
  }
  result
}

///|
pub fn point_cloud_project_xy(points : ArrayView[Point3]) -> Array[Point2] {
  let result : Array[Point2] = []
  for point in points {
    result.push(Point2::new(x=point.x, y=point.y))
  }
  result
}

///|
pub fn point_cloud_project_xz(points : ArrayView[Point3]) -> Array[Point2] {
  let result : Array[Point2] = []
  for point in points {
    result.push(Point2::new(x=point.x, y=point.z))
  }
  result
}

///|
pub fn point_cloud_project_yz(points : ArrayView[Point3]) -> Array[Point2] {
  let result : Array[Point2] = []
  for point in points {
    result.push(Point2::new(x=point.y, y=point.z))
  }
  result
}

///|
pub fn point_cloud_lift_xy(
  points : ArrayView[Point2],
  depth : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(Point3::new(x=point.x, y=point.y, z=depth))
  }
  result
}

///|
pub fn point_cloud_lift_xz(
  points : ArrayView[Point2],
  depth : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(Point3::new(x=point.x, y=depth, z=point.y))
  }
  result
}

///|
pub fn point_cloud_lift_yz(
  points : ArrayView[Point2],
  depth : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(Point3::new(x=depth, y=point.x, z=point.y))
  }
  result
}

///|
pub fn point_cloud_centroid_delta(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
) -> Vec3 {
  point_cloud_centroid(right).minus(point_cloud_centroid(left))
}

///|
pub fn point_cloud_centroid_distance(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
) -> Double {
  point_cloud_centroid_delta(left, right).norm()
}

///|
pub fn point_cloud_chamfer_one_way(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
) -> Double {
  if left.length() == 0 {
    0.0
  } else {
    let mut total = 0.0
    for point in left {
      total += point_cloud_nearest_distance(point, right)
    }
    total / left.length().to_double()
  }
}

///|
pub fn point_cloud_chamfer(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
) -> Double {
  (
    point_cloud_chamfer_one_way(left, right) +
    point_cloud_chamfer_one_way(right, left)
  ) *
  0.5
}

///|
pub fn point_cloud_hausdorff_one_way(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
) -> Double {
  let mut result = 0.0
  for point in left {
    result = result.max(point_cloud_nearest_distance(point, right))
  }
  result
}

///|
pub fn point_cloud_hausdorff(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
) -> Double {
  point_cloud_hausdorff_one_way(left, right).max(
    point_cloud_hausdorff_one_way(right, left),
  )
}

///|
pub fn point_cloud_overlap(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
  tolerance : Double,
) -> Double {
  if left.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for point in left {
      if point_cloud_nearest_distance(point, right) <= tolerance.max(0.0) {
        count += 1
      }
    }
    count.to_double() / left.length().to_double()
  }
}

///|
pub fn point_cloud_symmetric_overlap(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
  tolerance : Double,
) -> Double {
  (
    point_cloud_overlap(left, right, tolerance) +
    point_cloud_overlap(right, left, tolerance)
  ) *
  0.5
}

///|
pub fn point_cloud_match_score(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
  tolerance : Double,
) -> Double {
  let overlap = point_cloud_symmetric_overlap(left, right, tolerance)
  let distance = point_cloud_chamfer(left, right)
  overlap / (1.0 + distance)
}

///|
pub fn point_cloud_subtract_reference(
  points : ArrayView[Point3],
  reference : ArrayView[Point3],
  tolerance : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    if point_cloud_nearest_distance(point, reference) > tolerance.max(0.0) {
      result.push(point)
    }
  }
  result
}

///|
pub fn point_cloud_intersection(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
  tolerance : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in left {
    if point_cloud_nearest_distance(point, right) <= tolerance.max(0.0) {
      result.push(point)
    }
  }
  result
}

///|
pub fn point_cloud_union(
  left : ArrayView[Point3],
  right : ArrayView[Point3],
  tolerance : Double,
) -> Array[Point3] {
  point_cloud_remove_duplicates(point_cloud_merge(left, right), tolerance)
}

///|
pub fn point_cloud_sample_uniform(
  points : ArrayView[Point3],
  count : Int,
) -> Array[Point3] {
  if count <= 0 {
    []
  } else {
    point_cloud_stride(points, (points.length() / count.max(1)).max(1))
  }
}

///|
pub fn point_cloud_sample_endpoints(
  points : ArrayView[Point3],
  count : Int,
) -> Array[Point3] {
  if count <= 1 {
    point_cloud_take(points, count)
  } else {
    point_cloud_resample_line(points[0], points[points.length() - 1], count)
  }
}

///|
pub fn point_cloud_safe_mean_distance(points : ArrayView[Point3]) -> Double {
  point_cloud_mean_distance(points, point_cloud_centroid(points))
}

///|
pub fn point_cloud_safe_radius(points : ArrayView[Point3]) -> Double {
  point_cloud_radius(points, point_cloud_centroid(points))
}

///|
pub fn point_cloud_is_degenerate(
  points : ArrayView[Point3],
  tolerance : Double,
) -> Bool {
  point_cloud_safe_radius(points) <= tolerance.max(0.0) || points.length() < 2
}

///|
pub fn point_cloud_is_planar_xy(
  points : ArrayView[Point3],
  tolerance : Double,
) -> Bool {
  point_cloud_axis_range(points, 2) <= tolerance.max(0.0)
}

///|
pub fn point_cloud_is_planar_xz(
  points : ArrayView[Point3],
  tolerance : Double,
) -> Bool {
  point_cloud_axis_range(points, 1) <= tolerance.max(0.0)
}

///|
pub fn point_cloud_is_planar_yz(
  points : ArrayView[Point3],
  tolerance : Double,
) -> Bool {
  point_cloud_axis_range(points, 0) <= tolerance.max(0.0)
}

///|
pub fn point_cloud_quality_with_reference(
  points : ArrayView[Point3],
  reference : ArrayView[Point3],
  tolerance : Double,
) -> Double {
  point_cloud_match_score(points, reference, tolerance)
}
