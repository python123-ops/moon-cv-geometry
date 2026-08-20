///|
/// Ray-field diagnostics for camera coverage and scan planning.
pub fn ray_field_direction_z_minimum(rays : ArrayView[@core.Ray3]) -> Double {
  if rays.length() == 0 {
    0.0
  } else {
    let mut result = rays[0].direction.z
    for ray in rays {
      result = result.min(ray.direction.z)
    }
    result
  }
}

///|
pub fn ray_field_direction_z_maximum(rays : ArrayView[@core.Ray3]) -> Double {
  let mut result = 0.0
  for ray in rays {
    result = result.max(ray.direction.z)
  }
  result
}

///|
pub fn ray_field_direction_z_mean(rays : ArrayView[@core.Ray3]) -> Double {
  if rays.length() == 0 {
    0.0
  } else {
    let mut result = 0.0
    for ray in rays {
      result += ray.direction.z
    }
    result / rays.length().to_double()
  }
}

///|
pub fn ray_field_direction_z_ratio(
  rays : ArrayView[@core.Ray3],
  threshold : Double,
) -> Double {
  if rays.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for ray in rays {
      if ray.direction.z >= threshold {
        count += 1
      }
    }
    count.to_double() / rays.length().to_double()
  }
}

///|
pub fn ray_field_origin_bounds(
  rays : ArrayView[@core.Ray3],
) -> (@core.Point3, @core.Point3) {
  let points = camera_ray_field_origins(rays)
  @core.point_cloud_bounds(points)
}

///|
pub fn ray_field_origin_centroid(rays : ArrayView[@core.Ray3]) -> @core.Point3 {
  @core.point_cloud_centroid(camera_ray_field_origins(rays))
}

///|
pub fn ray_field_origin_spread(rays : ArrayView[@core.Ray3]) -> Double {
  @core.point_cloud_safe_radius(camera_ray_field_origins(rays))
}

///|
pub fn ray_field_origin_quality(
  rays : ArrayView[@core.Ray3],
  maximum_spread : Double,
) -> Double {
  if maximum_spread <= 0.0 {
    0.0
  } else {
    (1.0 - ray_field_origin_spread(rays) / maximum_spread).max(0.0).min(1.0)
  }
}

///|
pub fn ray_field_direction_quality(
  rays : ArrayView[@core.Ray3],
  minimum_forward_ratio : Double,
) -> Double {
  (camera_ray_field_forward_ratio(rays) /
  minimum_forward_ratio.max(0.000000000001)).min(1.0)
}

///|
pub fn ray_field_quality(
  rays : ArrayView[@core.Ray3],
  minimum_forward_ratio : Double,
  maximum_spread : Double,
) -> Double {
  ray_field_direction_quality(rays, minimum_forward_ratio) *
  ray_field_origin_quality(rays, maximum_spread)
}

///|
pub fn ray_field_filter_forward(
  rays : ArrayView[@core.Ray3],
  minimum_z : Double,
) -> Array[@core.Ray3] {
  let result : Array[@core.Ray3] = []
  for ray in rays {
    if ray.direction.z >= minimum_z {
      result.push(ray)
    }
  }
  result
}

///|
pub fn ray_field_filter_origin_z(
  rays : ArrayView[@core.Ray3],
  minimum_z : Double,
  maximum_z : Double,
) -> Array[@core.Ray3] {
  let result : Array[@core.Ray3] = []
  for ray in rays {
    if ray.origin.z >= minimum_z && ray.origin.z <= maximum_z {
      result.push(ray)
    }
  }
  result
}

///|
pub fn ray_field_direction_dot_sum(
  left : ArrayView[@core.Ray3],
  right : ArrayView[@core.Ray3],
) -> Double {
  let count = left.length().min(right.length())
  let mut result = 0.0
  for i in 0..<count {
    result += left[i].direction.dot(right[i].direction)
  }
  result
}

///|
pub fn ray_field_mean_angular_agreement(
  left : ArrayView[@core.Ray3],
  right : ArrayView[@core.Ray3],
) -> Double {
  let count = left.length().min(right.length())
  if count == 0 {
    0.0
  } else {
    ray_field_direction_dot_sum(left, right) / count.to_double()
  }
}

///|
pub fn ray_field_reproject_depth(
  rays : ArrayView[@core.Ray3],
  depth : Double,
) -> Array[@core.Point3] {
  let result : Array[@core.Point3] = []
  for ray in rays {
    result.push(ray.point_at(depth))
  }
  result
}

///|
pub fn ray_field_depth_range(
  rays : ArrayView[@core.Ray3],
  depth : Double,
) -> (@core.Point3, @core.Point3) {
  @core.point_cloud_bounds(ray_field_reproject_depth(rays, depth))
}

///|
pub fn ray_field_depth_centroid(
  rays : ArrayView[@core.Ray3],
  depth : Double,
) -> @core.Point3 {
  @core.point_cloud_centroid(ray_field_reproject_depth(rays, depth))
}

///|
pub fn ray_field_depth_radius(
  rays : ArrayView[@core.Ray3],
  depth : Double,
) -> Double {
  let points = ray_field_reproject_depth(rays, depth)
  @core.point_cloud_safe_radius(points)
}

///|
pub fn ray_field_depth_quality(
  rays : ArrayView[@core.Ray3],
  depth : Double,
  maximum_radius : Double,
) -> Double {
  if maximum_radius <= 0.0 {
    0.0
  } else {
    (1.0 - ray_field_depth_radius(rays, depth) / maximum_radius)
    .max(0.0)
    .min(1.0)
  }
}

///|
pub fn ray_field_scan_score(
  rays : ArrayView[@core.Ray3],
  depth : Double,
  minimum_forward_ratio : Double,
  maximum_radius : Double,
) -> Double {
  ray_field_quality(rays, minimum_forward_ratio, maximum_radius) *
  ray_field_depth_quality(rays, depth, maximum_radius)
}

///|
pub fn ray_field_depth_schedule(
  minimum : Double,
  maximum : Double,
  steps : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let count = steps.max(1)
  if count == 1 {
    result.push(minimum)
    return result
  }
  for i in 0..<count {
    result.push(
      minimum + (maximum - minimum) * i.to_double() / (count - 1).to_double(),
    )
  }
  result
}

///|
pub fn ray_field_schedule_quality(
  rays : ArrayView[@core.Ray3],
  schedule : ArrayView[Double],
  minimum_forward_ratio : Double,
  maximum_radius : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for depth in schedule {
    result.push(
      ray_field_scan_score(rays, depth, minimum_forward_ratio, maximum_radius),
    )
  }
  result
}
