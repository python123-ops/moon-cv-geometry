///|
/// Generate a regular camera ray field for scan matching and calibration.
pub fn camera_ray_field(
  size : ImageSize,
  intrinsics : CameraIntrinsics,
  columns~ : Int,
  rows~ : Int,
) -> Array[@core.Ray3] raise @core.GeometryError {
  let result : Array[@core.Ray3] = []
  if columns <= 0 || rows <= 0 {
    return result
  }
  for row in 0..<rows {
    for column in 0..<columns {
      let x = if columns == 1 {
        size.width.to_double() / 2.0
      } else {
        column.to_double() *
        (size.width - 1).to_double() /
        (columns - 1).to_double()
      }
      let y = if rows == 1 {
        size.height.to_double() / 2.0
      } else {
        row.to_double() * (size.height - 1).to_double() / (rows - 1).to_double()
      }
      let normalized = pixel_to_normalized(
        @core.Point2::new(x~, y~),
        intrinsics,
      )
      let direction = @core.Vec3::new(x=normalized.x, y=normalized.y, z=1.0).normalize()
      result.push(
        @core.Ray3::new(
          origin=@core.Point3::new(x=0.0, y=0.0, z=0.0),
          direction~,
        ),
      )
    }
  }
  result
}

///|
pub fn camera_ray_field_directions(
  rays : ArrayView[@core.Ray3],
) -> Array[@core.Vec3] {
  let result : Array[@core.Vec3] = []
  for ray in rays {
    result.push(ray.direction)
  }
  result
}

///|
pub fn camera_ray_field_origins(
  rays : ArrayView[@core.Ray3],
) -> Array[@core.Point3] {
  let result : Array[@core.Point3] = []
  for ray in rays {
    result.push(ray.origin)
  }
  result
}

///|
pub fn camera_ray_field_forward_ratio(rays : ArrayView[@core.Ray3]) -> Double {
  if rays.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for ray in rays {
      if ray.direction.z > 0.0 {
        count += 1
      }
    }
    count.to_double() / rays.length().to_double()
  }
}

///|
pub fn camera_ray_field_mean_direction(
  rays : ArrayView[@core.Ray3],
) -> @core.Vec3 {
  @core.vector_mean(camera_ray_field_directions(rays))
}

///|
pub fn camera_ray_field_direction_spread(
  rays : ArrayView[@core.Ray3],
) -> Double {
  @core.vector_covariance_trace(camera_ray_field_directions(rays))
}

///|
pub fn rotate_ray_field(
  rays : ArrayView[@core.Ray3],
  rotation : @core.Mat3,
) -> Array[@core.Ray3] raise @core.GeometryError {
  let result : Array[@core.Ray3] = []
  for ray in rays {
    result.push(
      @core.Ray3::new(
        origin=ray.origin,
        direction=rotation.mul_vec3(ray.direction),
      ),
    )
  }
  result
}

///|
pub fn translate_ray_field(
  rays : ArrayView[@core.Ray3],
  translation : @core.Vec3,
) -> Array[@core.Ray3] raise @core.GeometryError {
  let result : Array[@core.Ray3] = []
  for ray in rays {
    result.push(
      @core.Ray3::new(
        origin=ray.origin.translate(translation),
        direction=ray.direction,
      ),
    )
  }
  result
}

///|
pub fn transform_ray_field(
  rays : ArrayView[@core.Ray3],
  transform : @core.RigidTransform,
) -> Array[@core.Ray3] raise @core.GeometryError {
  let result : Array[@core.Ray3] = []
  for ray in rays {
    result.push(
      @core.Ray3::new(
        origin=transform.apply(ray.origin),
        direction=transform.rotation.mul_vec3(ray.direction),
      ),
    )
  }
  result
}

///|
pub fn ray_field_bounds(
  rays : ArrayView[@core.Ray3],
) -> @core.Aabb3 raise @core.GeometryError {
  @core.Aabb3::from_points(camera_ray_field_origins(rays))
}

///|
pub fn ray_plane_intersection(
  ray : @core.Ray3,
  plane_z : Double,
) -> @core.Point3? {
  if ray.direction.z.abs() <= 0.000000000001 {
    None
  } else {
    let amount = (plane_z - ray.origin.z) / ray.direction.z
    if amount < 0.0 {
      None
    } else {
      Some(ray.origin.translate(ray.direction.scale(amount)))
    }
  }
}

///|
pub fn ray_plane_intersections(
  rays : ArrayView[@core.Ray3],
  plane_z : Double,
) -> Array[@core.Point3] {
  let result : Array[@core.Point3] = []
  for ray in rays {
    match ray_plane_intersection(ray, plane_z) {
      Some(point) => result.push(point)
      None => ()
    }
  }
  result
}

///|
pub fn ray_sphere_intersection(
  ray : @core.Ray3,
  center : @core.Point3,
  radius : Double,
) -> Bool {
  let offset = ray.origin.minus(center)
  let b = offset.dot(ray.direction)
  let c = offset.norm2() - radius * radius
  b * b - c >= 0.0
}

///|
pub fn ray_sphere_hits(
  rays : ArrayView[@core.Ray3],
  center : @core.Point3,
  radius : Double,
) -> Int {
  let mut result = 0
  for ray in rays {
    if ray_sphere_intersection(ray, center, radius) {
      result += 1
    }
  }
  result
}

///|
pub fn image_feature_grid(size : ImageSize, step~ : Int) -> Array[@core.Point2] {
  let result : Array[@core.Point2] = []
  let spacing = step.max(1)
  for y in 0..<size.height {
    for x in 0..<size.width {
      if x % spacing == 0 && y % spacing == 0 {
        result.push(@core.Point2::new(x=x.to_double(), y=y.to_double()))
      } else {
        ()
      }
    }
  }
  result
}

///|
pub fn image_feature_grid_interior(
  size : ImageSize,
  margin : Int,
  step : Int,
) -> Array[@core.Point2] {
  let result : Array[@core.Point2] = []
  let spacing = step.max(1)
  let start = margin.max(0)
  let end_y = (size.height - margin).max(start)
  let end_x = (size.width - margin).max(start)
  for y in start..<end_y {
    for x in start..<end_x {
      if x % spacing == 0 && y % spacing == 0 {
        result.push(@core.Point2::new(x=x.to_double(), y=y.to_double()))
      } else {
        ()
      }
    }
  }
  result
}

///|
pub fn image_feature_grid_count(size : ImageSize, step : Int) -> Int {
  image_feature_grid(size, step~).length()
}

///|
pub fn feature_grid_spacing(size : ImageSize, desired_count : Int) -> Int {
  if desired_count <= 0 {
    size.width.max(size.height)
  } else {
    ((size.width * size.height).to_double() / desired_count.to_double())
    .sqrt()
    .to_int()
    .max(1)
  }
}

///|
pub fn ray_field_subsample(
  rays : ArrayView[@core.Ray3],
  stride : Int,
) -> Array[@core.Ray3] {
  let result : Array[@core.Ray3] = []
  let spacing = stride.max(1)
  for i in 0..<rays.length() {
    if i % spacing == 0 {
      result.push(rays[i])
    }
  }
  result
}

///|
pub fn ray_field_concat(
  left : ArrayView[@core.Ray3],
  right : ArrayView[@core.Ray3],
) -> Array[@core.Ray3] {
  let result = left.to_owned()
  for ray in right {
    result.push(ray)
  }
  result
}
