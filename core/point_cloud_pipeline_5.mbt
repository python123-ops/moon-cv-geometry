///|
/// Lightweight point-cloud health indicators for service-level monitoring.
pub fn point_cloud_health_count(points : ArrayView[Point3]) -> Int {
  points.length()
}

///|
pub fn point_cloud_health_finite(points : ArrayView[Point3]) -> Double {
  point_cloud_finite_ratio(points)
}

///|
pub fn point_cloud_health_radius(
  points : ArrayView[Point3],
  maximum : Double,
) -> Double {
  if maximum <= 0.0 {
    0.0
  } else {
    (1.0 - point_cloud_safe_radius(points) / maximum).max(0.0).min(1.0)
  }
}

///|
pub fn point_cloud_health_density(
  points : ArrayView[Point3],
  radius : Double,
) -> Double {
  point_cloud_density(points, point_cloud_centroid(points), radius)
}

///|
pub fn point_cloud_health_duplicates(
  points : ArrayView[Point3],
  tolerance : Double,
) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    point_cloud_remove_duplicates(points, tolerance).length().to_double() /
    points.length().to_double()
  }
}

///|
pub fn point_cloud_health_score(
  points : ArrayView[Point3],
  minimum_count : Int,
  maximum_radius : Double,
  tolerance : Double,
) -> Double {
  let support = if minimum_count <= 0 {
    1.0
  } else {
    (points.length().to_double() / minimum_count.to_double()).min(1.0)
  }
  support *
  point_cloud_finite_ratio(points) *
  point_cloud_health_radius(points, maximum_radius) *
  point_cloud_health_duplicates(points, tolerance)
}

///|
pub fn point_cloud_health_label(score : Double) -> String {
  if score >= 0.8 {
    "healthy"
  } else if score >= 0.5 {
    "degraded"
  } else {
    "failed"
  }
}

///|
pub fn point_cloud_health_report(
  points : ArrayView[Point3],
  minimum_count : Int,
  maximum_radius : Double,
  tolerance : Double,
) -> String {
  let score = point_cloud_health_score(
    points, minimum_count, maximum_radius, tolerance,
  )
  score.to_string() + "," + point_cloud_health_label(score)
}

///|
pub fn point_cloud_health_batch(
  points : ArrayView[Array[Point3]],
  minimum_count : Int,
  maximum_radius : Double,
  tolerance : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for batch in points {
    result.push(
      point_cloud_health_score(batch, minimum_count, maximum_radius, tolerance),
    )
  }
  result
}

///|
pub fn point_cloud_health_batch_mean(
  points : ArrayView[Array[Point3]],
  minimum_count : Int,
  maximum_radius : Double,
  tolerance : Double,
) -> Double {
  mean(
    point_cloud_health_batch(points, minimum_count, maximum_radius, tolerance),
  ) catch {
    _ => 0.0
  }
}
