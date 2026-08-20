///|
/// Apply a rigid transform to a point batch.
pub fn transform_points_batch(
  transform : RigidTransform,
  points : ArrayView[Point3],
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(transform.apply(point))
  }
  result
}

///|
pub fn transform_vectors_batch(
  transform : RigidTransform,
  vectors : ArrayView[Vec3],
) -> Array[Vec3] {
  let result : Array[Vec3] = []
  for vector in vectors {
    result.push(transform.rotation.mul_vec3(vector))
  }
  result
}

///|
pub fn transform_chain_batch(
  chain : TransformChain,
  points : ArrayView[Point3],
) -> Array[Point3] {
  transform_points(chain, points)
}

///|
pub fn inverse_transform_points_batch(
  transform : RigidTransform,
  points : ArrayView[Point3],
) -> Array[Point3] {
  let inverse = transform.inverse()
  transform_points_batch(inverse, points)
}

///|
pub fn transform_point_with_scale(
  transform : RigidTransform,
  point : Point3,
  scale : Double,
) -> Point3 {
  let scaled = Point3::new(
    x=point.x * scale,
    y=point.y * scale,
    z=point.z * scale,
  )
  transform.apply(scaled)
}

///|
pub fn transform_points_with_scale(
  transform : RigidTransform,
  points : ArrayView[Point3],
  scale : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(transform_point_with_scale(transform, point, scale))
  }
  result
}

///|
pub fn compose_transforms(
  transforms : ArrayView[RigidTransform],
) -> RigidTransform {
  let mut result = RigidTransform::identity()
  for transform in transforms {
    result = result.compose(transform)
  }
  result
}

///|
pub fn compose_inverse_transforms(
  transforms : ArrayView[RigidTransform],
) -> RigidTransform {
  let mut result = RigidTransform::identity()
  for transform in transforms {
    result = result.compose(transform.inverse())
  }
  result
}

///|
pub fn transform_centroid(
  transform : RigidTransform,
  points : ArrayView[Point3],
) -> Point3 raise GeometryError {
  transform.apply(centroid3(points))
}

///|
pub fn transform_bounds(
  transform : RigidTransform,
  points : ArrayView[Point3],
) -> Aabb3 raise GeometryError {
  Aabb3::from_points(transform_points_batch(transform, points))
}

///|
pub fn transform_rms_radius(
  transform : RigidTransform,
  points : ArrayView[Point3],
) -> Double raise GeometryError {
  PointCloud::from_points(transform_points_batch(transform, points)).rms_radius()
}

///|
pub fn rotate_about_point(
  rotation : Mat3,
  center : Point3,
  point : Point3,
) -> Point3 {
  let offset = point.minus(center)
  let rotated = rotation.mul_vec3(offset)
  Point3::new(
    x=center.x + rotated.x,
    y=center.y + rotated.y,
    z=center.z + rotated.z,
  )
}

///|
pub fn rotate_points_about_point(
  rotation : Mat3,
  center : Point3,
  points : ArrayView[Point3],
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(rotate_about_point(rotation, center, point))
  }
  result
}

///|
pub fn translate_points(
  points : ArrayView[Point3],
  translation : Vec3,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(point.translate(translation))
  }
  result
}

///|
pub fn translate_vectors(
  vectors : ArrayView[Vec3],
  translation : Vec3,
) -> Array[Vec3] {
  let result : Array[Vec3] = []
  for vector in vectors {
    result.push(vector.add(translation))
  }
  result
}

///|
pub fn scale_points(
  points : ArrayView[Point3],
  scale : Double,
) -> Array[Point3] {
  let result : Array[Point3] = []
  for point in points {
    result.push(
      Point3::new(x=point.x * scale, y=point.y * scale, z=point.z * scale),
    )
  }
  result
}

///|
pub fn scale_vectors(vectors : ArrayView[Vec3], scale : Double) -> Array[Vec3] {
  let result : Array[Vec3] = []
  for vector in vectors {
    result.push(vector.scale(scale))
  }
  result
}

///|
pub fn centroid_after_transform(
  transform : RigidTransform,
  points : ArrayView[Point3],
) -> Point3 raise GeometryError {
  centroid3(transform_points_batch(transform, points))
}

///|
pub fn pairwise_transform_distances(
  transform : RigidTransform,
  points : ArrayView[Point3],
) -> Array[Double] {
  let transformed = transform_points_batch(transform, points)
  pairwise_distances(transformed)
}

///|
pub fn transform_is_identity(
  transform : RigidTransform,
  tolerance : Double,
) -> Bool {
  let translation = transform.translation.norm()
  rotation_residual(transform.rotation) <= tolerance && translation <= tolerance
}

///|
pub fn transform_translation_norm(transform : RigidTransform) -> Double {
  transform.translation.norm()
}

///|
pub fn transform_rotation_residual(transform : RigidTransform) -> Double {
  rotation_residual(transform.rotation)
}

///|
pub fn transform_distance(
  left : RigidTransform,
  right : RigidTransform,
) -> Double {
  let translation = left.translation.sub(right.translation).norm()
  let rotation = rotation_residual(
    left.rotation.transpose().mul(right.rotation),
  )
  translation + rotation
}

///|
pub fn transform_interpolate(
  left : RigidTransform,
  right : RigidTransform,
  amount : Double,
) -> RigidTransform {
  interpolate_pose(left, right, amount)
}

///|
pub fn transform_trajectory_sample(
  transforms : ArrayView[RigidTransform],
  amount : Double,
) -> RigidTransform {
  if transforms.length() == 0 {
    RigidTransform::identity()
  } else if transforms.length() == 1 {
    transforms[0]
  } else {
    let position = amount.max(0.0).min(1.0) *
      (transforms.length() - 1).to_double()
    let lower = position.floor().to_int()
    let upper = position.ceil().to_int().min(transforms.length() - 1)
    transform_interpolate(
      transforms[lower],
      transforms[upper],
      position - lower.to_double(),
    )
  }
}

///|
pub fn transform_trajectory_sample_many(
  transforms : ArrayView[RigidTransform],
  count : Int,
) -> Array[RigidTransform] {
  let result : Array[RigidTransform] = []
  for i in 0..<count.max(0) {
    let amount = if count <= 1 {
      0.0
    } else {
      i.to_double() / (count - 1).to_double()
    }
    result.push(transform_trajectory_sample(transforms, amount))
  }
  result
}

///|
pub fn transform_trajectory_length(
  transforms : ArrayView[RigidTransform],
) -> Double {
  if transforms.length() < 2 {
    0.0
  } else {
    let mut result = 0.0
    for i in 0..<(transforms.length() - 1) {
      result += transforms[i].translation
        .sub(transforms[i + 1].translation)
        .norm()
    }
    result
  }
}

///|
pub fn transform_relative(
  left : RigidTransform,
  right : RigidTransform,
) -> RigidTransform {
  left.inverse().compose(right)
}

///|
pub fn transform_relative_points(
  left : RigidTransform,
  right : RigidTransform,
  points : ArrayView[Point3],
) -> Array[Point3] {
  transform_points_batch(transform_relative(left, right), points)
}
