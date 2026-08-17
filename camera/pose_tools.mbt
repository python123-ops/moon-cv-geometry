///|
pub fn CameraPose::camera_center(pose : CameraPose) -> @core.Point3 {
  let r = @core.mat3_from_rows(
    (
      pose.world_to_camera.m00,
      pose.world_to_camera.m01,
      pose.world_to_camera.m02,
    ),
    (
      pose.world_to_camera.m10,
      pose.world_to_camera.m11,
      pose.world_to_camera.m12,
    ),
    (
      pose.world_to_camera.m20,
      pose.world_to_camera.m21,
      pose.world_to_camera.m22,
    ),
  )
  let t = @core.Vec3::new(
    x=pose.world_to_camera.m03,
    y=pose.world_to_camera.m13,
    z=pose.world_to_camera.m23,
  )
  let c = r.transpose().mul_vec3(t).scale(-1.0)
  @core.Point3::new(x=c.x, y=c.y, z=c.z)
}

///|
pub fn CameraPose::rotation(pose : CameraPose) -> @core.Mat3 {
  @core.mat3_from_rows(
    (
      pose.world_to_camera.m00,
      pose.world_to_camera.m01,
      pose.world_to_camera.m02,
    ),
    (
      pose.world_to_camera.m10,
      pose.world_to_camera.m11,
      pose.world_to_camera.m12,
    ),
    (
      pose.world_to_camera.m20,
      pose.world_to_camera.m21,
      pose.world_to_camera.m22,
    ),
  )
}

///|
pub fn CameraPose::translation(pose : CameraPose) -> @core.Vec3 {
  @core.Vec3::new(
    x=pose.world_to_camera.m03,
    y=pose.world_to_camera.m13,
    z=pose.world_to_camera.m23,
  )
}

///|
pub fn CameraPose::from_rotation_translation(
  rotation : @core.Mat3,
  translation : @core.Vec3,
) -> CameraPose {
  CameraPose::new(
    world_to_camera=@core.mat34_from_rows(
      (rotation.m00, rotation.m01, rotation.m02, translation.x),
      (rotation.m10, rotation.m11, rotation.m12, translation.y),
      (rotation.m20, rotation.m21, rotation.m22, translation.z),
    ),
  )
}

///|
pub fn CameraPose::transform_point(
  pose : CameraPose,
  point : @core.Point3,
) -> @core.Point3 {
  pose.world_to_camera.transform_point(point)
}

///|
pub fn CameraPose::inverse_transform_point(
  pose : CameraPose,
  point : @core.Point3,
) -> @core.Point3 {
  let center = pose.camera_center()
  let rotation = pose.rotation()
  let delta = point.minus(@core.Point3::new(x=0.0, y=0.0, z=0.0))
  let world = rotation.transpose().mul_vec3(delta).add(center.to_vec())
  @core.Point3::new(x=world.x, y=world.y, z=world.z)
}

///|
pub fn CameraPose::interpolate(
  a : CameraPose,
  b : CameraPose,
  amount : Double,
) -> CameraPose {
  let rotation = a.rotation()
  let rb = b.rotation()
  let t = a.translation()
  let tb = b.translation()
  let translation = @core.Vec3::new(
    x=@core.linear_interpolate(t.x, tb.x, amount),
    y=@core.linear_interpolate(t.y, tb.y, amount),
    z=@core.linear_interpolate(t.z, tb.z, amount),
  )
  let rotation = @core.mat3_from_rows(
    (
      @core.linear_interpolate(rotation.m00, rb.m00, amount),
      @core.linear_interpolate(rotation.m01, rb.m01, amount),
      @core.linear_interpolate(rotation.m02, rb.m02, amount),
    ),
    (
      @core.linear_interpolate(rotation.m10, rb.m10, amount),
      @core.linear_interpolate(rotation.m11, rb.m11, amount),
      @core.linear_interpolate(rotation.m12, rb.m12, amount),
    ),
    (
      @core.linear_interpolate(rotation.m20, rb.m20, amount),
      @core.linear_interpolate(rotation.m21, rb.m21, amount),
      @core.linear_interpolate(rotation.m22, rb.m22, amount),
    ),
  )
  CameraPose::from_rotation_translation(rotation, translation)
}

///|
pub fn CameraIntrinsics::valid(k : CameraIntrinsics) -> Bool {
  k.fx > 0.0 && k.fy > 0.0 && k.fx == k.fx && k.fy == k.fy
}

///|
pub fn CameraIntrinsics::pixel_aspect(
  k : CameraIntrinsics,
) -> Double raise @core.GeometryError {
  if k.fy <= 0.0 {
    raise @core.GeometryError::DegenerateInput("fy must be positive")
  }
  k.fx / k.fy
}

///|
pub fn CameraIntrinsics::focal_mean(k : CameraIntrinsics) -> Double {
  (k.fx + k.fy) / 2.0
}

///|
pub fn CameraIntrinsics::with_principal_point(
  k : CameraIntrinsics,
  principal : @core.Point2,
) -> CameraIntrinsics {
  CameraIntrinsics::new(
    fx=k.fx,
    fy=k.fy,
    cx=principal.x,
    cy=principal.y,
    skew=k.skew,
  )
}

///|
pub fn distortion_strength(d : Distortion) -> Double {
  @core.abs(d.k1) +
  @core.abs(d.k2) +
  @core.abs(d.k3) +
  @core.abs(d.p1) +
  @core.abs(d.p2)
}

///|
pub fn max_distortion_error(
  points : ArrayView[@core.Point2],
  d : Distortion,
) -> Double {
  let mut result = 0.0
  for p in points {
    let error = distort_point(p, d).minus(p).norm()
    if error > result {
      result = error
    }
  }
  result
}

///|
pub fn image_bounds(size : ImageSize) -> @core.Rect2 raise @core.GeometryError {
  size.as_rect()
}

///|
pub fn pixel_in_bounds(size : ImageSize, pixel : @core.Point2) -> Bool {
  pixel.x >= 0.0 &&
  pixel.y >= 0.0 &&
  pixel.x < Double::from_int(size.width) &&
  pixel.y < Double::from_int(size.height)
}

///|
pub fn clamp_pixel(size : ImageSize, pixel : @core.Point2) -> @core.Point2 {
  @core.Point2::new(
    x=@core.clamp(pixel.x, lo=0.0, hi=Double::from_int(size.width - 1)),
    y=@core.clamp(pixel.y, lo=0.0, hi=Double::from_int(size.height - 1)),
  )
}
