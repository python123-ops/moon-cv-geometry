///|
/// Validate an intrinsic calibration against image dimensions.
pub fn intrinsics_is_valid(
  intrinsics : CameraIntrinsics,
  size : ImageSize,
) -> Bool {
  intrinsics.fx > 0.0 &&
  intrinsics.fy > 0.0 &&
  intrinsics.cx >= 0.0 &&
  intrinsics.cy >= 0.0 &&
  intrinsics.cx < size.width.to_double() &&
  intrinsics.cy < size.height.to_double()
}

///|
pub fn intrinsics_focal_mean(intrinsics : CameraIntrinsics) -> Double {
  (intrinsics.fx + intrinsics.fy) / 2.0
}

///|
pub fn intrinsics_aspect_ratio(intrinsics : CameraIntrinsics) -> Double {
  if intrinsics.fy <= 0.0 {
    0.0
  } else {
    intrinsics.fx / intrinsics.fy
  }
}

///|
pub fn intrinsics_skew_ratio(intrinsics : CameraIntrinsics) -> Double {
  if intrinsics.fx.abs() <= 0.000000000001 {
    0.0
  } else {
    intrinsics.skew / intrinsics.fx
  }
}

///|
pub fn intrinsics_principal_point(
  intrinsics : CameraIntrinsics,
) -> @core.Point2 {
  @core.Point2::new(x=intrinsics.cx, y=intrinsics.cy)
}

///|
pub fn intrinsics_is_square_pixel(
  intrinsics : CameraIntrinsics,
  tolerance : Double,
) -> Bool {
  (intrinsics.fx - intrinsics.fy).abs() <= tolerance
}

///|
pub fn intrinsics_distance(
  left : CameraIntrinsics,
  right : CameraIntrinsics,
) -> Double {
  ((left.fx - right.fx) * (left.fx - right.fx) +
  (left.fy - right.fy) * (left.fy - right.fy) +
  (left.cx - right.cx) * (left.cx - right.cx) +
  (left.cy - right.cy) * (left.cy - right.cy) +
  (left.skew - right.skew) * (left.skew - right.skew)).sqrt()
}

///|
pub fn interpolate_intrinsics(
  left : CameraIntrinsics,
  right : CameraIntrinsics,
  amount : Double,
) -> CameraIntrinsics {
  let t = amount.max(0.0).min(1.0)
  CameraIntrinsics::new(
    fx=left.fx * (1.0 - t) + right.fx * t,
    fy=left.fy * (1.0 - t) + right.fy * t,
    cx=left.cx * (1.0 - t) + right.cx * t,
    cy=left.cy * (1.0 - t) + right.cy * t,
    skew=left.skew * (1.0 - t) + right.skew * t,
  )
}

///|
pub fn scale_intrinsics(
  intrinsics : CameraIntrinsics,
  scale : Double,
) -> CameraIntrinsics {
  CameraIntrinsics::new(
    fx=intrinsics.fx * scale,
    fy=intrinsics.fy * scale,
    cx=intrinsics.cx * scale,
    cy=intrinsics.cy * scale,
    skew=intrinsics.skew * scale,
  )
}

///|
pub fn shift_intrinsics(
  intrinsics : CameraIntrinsics,
  shift : @core.Vec2,
) -> CameraIntrinsics {
  CameraIntrinsics::new(
    fx=intrinsics.fx,
    fy=intrinsics.fy,
    cx=intrinsics.cx + shift.x,
    cy=intrinsics.cy + shift.y,
    skew=intrinsics.skew,
  )
}

///|
pub fn normalized_principal_point(
  intrinsics : CameraIntrinsics,
  size : ImageSize,
) -> @core.Point2 {
  @core.Point2::new(
    x=intrinsics.cx / size.width.to_double(),
    y=intrinsics.cy / size.height.to_double(),
  )
}

///|
pub fn normalized_focal(
  intrinsics : CameraIntrinsics,
  size : ImageSize,
) -> @core.Vec2 {
  @core.Vec2::new(
    x=intrinsics.fx / size.width.to_double(),
    y=intrinsics.fy / size.height.to_double(),
  )
}

///|
pub fn field_of_view_pair(
  intrinsics : CameraIntrinsics,
  size : ImageSize,
) -> (Double, Double) raise @core.GeometryError {
  (
    horizontal_fov(intrinsics, width=size.width.to_double()),
    vertical_fov(intrinsics, height=size.height.to_double()),
  )
}

///|
pub fn image_diagonal_fov(
  intrinsics : CameraIntrinsics,
  size : ImageSize,
) -> Double raise @core.GeometryError {
  let diagonal = (size.width.to_double() * size.width.to_double() +
  size.height.to_double() * size.height.to_double()).sqrt()
  horizontal_fov(intrinsics, width=diagonal)
}

///|
pub fn focal_from_horizontal_fov_safe(
  size : ImageSize,
  fov : Double,
) -> Double raise @core.GeometryError {
  focal_from_fov(sensor_extent=size.width.to_double(), fov_radians=fov)
}

///|
pub fn camera_parameter_vector(intrinsics : CameraIntrinsics) -> Array[Double] {
  [intrinsics.fx, intrinsics.fy, intrinsics.cx, intrinsics.cy, intrinsics.skew]
}

///|
pub fn camera_parameter_delta(
  left : CameraIntrinsics,
  right : CameraIntrinsics,
) -> Array[Double] {
  let l = camera_parameter_vector(left)
  let r = camera_parameter_vector(right)
  @core.subtract_scalars(l, r)
}

///|
pub fn camera_parameter_norm(intrinsics : CameraIntrinsics) -> Double {
  @core.norm_scalars(camera_parameter_vector(intrinsics))
}

///|
pub fn camera_parameter_clamp(
  intrinsics : CameraIntrinsics,
  minimum_focal : Double,
  maximum_focal : Double,
) -> CameraIntrinsics {
  CameraIntrinsics::new(
    fx=intrinsics.fx.max(minimum_focal).min(maximum_focal),
    fy=intrinsics.fy.max(minimum_focal).min(maximum_focal),
    cx=intrinsics.cx.max(0.0),
    cy=intrinsics.cy.max(0.0),
    skew=intrinsics.skew,
  )
}
