///|
pub(all) struct PointCloud {
  points : Array[Point3]
} derive(Debug, Eq)

///|
pub fn PointCloud::from_points(points : ArrayView[Point3]) -> PointCloud {
  { points: points.to_owned() }
}

///|
pub fn PointCloud::length(cloud : PointCloud) -> Int {
  cloud.points.length()
}

///|
pub fn PointCloud::is_empty(cloud : PointCloud) -> Bool {
  cloud.points.length() == 0
}

///|
pub fn PointCloud::centroid(cloud : PointCloud) -> Point3 raise GeometryError {
  centroid3(cloud.points)
}

///|
pub fn PointCloud::valid_depth_count(cloud : PointCloud) -> Int {
  let mut result = 0
  for point in cloud.points {
    if point.z > 0.0 {
      result += 1
    }
  }
  result
}

///|
pub fn PointCloud::positive_depth_ratio(cloud : PointCloud) -> Double {
  if cloud.is_empty() {
    0.0
  } else {
    Double::from_int(cloud.valid_depth_count()) /
    Double::from_int(cloud.length())
  }
}

///|
pub fn PointCloud::depth_range(
  cloud : PointCloud,
) -> (Double, Double) raise GeometryError {
  if cloud.is_empty() {
    raise GeometryError::NotEnoughPoints("point cloud has no points")
  }
  let mut minimum = cloud.points[0].z
  let mut maximum = cloud.points[0].z
  for point in cloud.points {
    if point.z < minimum {
      minimum = point.z
    }
    if point.z > maximum {
      maximum = point.z
    }
  }
  (minimum, maximum)
}

///|
pub fn PointCloud::filter_depth(
  cloud : PointCloud,
  minimum~ : Double,
  maximum~ : Double,
) -> PointCloud raise GeometryError {
  if maximum < minimum {
    raise GeometryError::DegenerateInput("depth filter bounds are reversed")
  }
  let result : Array[Point3] = []
  for point in cloud.points {
    if point.z >= minimum && point.z <= maximum {
      result.push(point)
    }
  }
  PointCloud::from_points(result)
}

///|
pub fn PointCloud::bounds(cloud : PointCloud) -> Aabb3 raise GeometryError {
  Aabb3::from_points(cloud.points)
}

///|
pub fn PointCloud::rms_radius(cloud : PointCloud) -> Double raise GeometryError {
  let center = cloud.centroid()
  if cloud.is_empty() {
    raise GeometryError::NotEnoughPoints("point cloud has no points")
  }
  let mut sum = 0.0
  for point in cloud.points {
    let distance = distance3(point, center)
    sum += distance * distance
  }
  (sum / Double::from_int(cloud.length())).sqrt()
}

///|
pub fn merge_point_clouds(left : PointCloud, right : PointCloud) -> PointCloud {
  let result = left.points.copy()
  for point in right.points {
    result.push(point)
  }
  PointCloud::from_points(result)
}
