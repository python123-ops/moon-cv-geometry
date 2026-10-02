///|
pub(all) struct CameraIntrinsics {
  fx : Double
  fy : Double
  cx : Double
  cy : Double
  skew : Double
} derive(Debug, Eq)

///|
pub fn CameraIntrinsics::new(
  fx~ : Double,
  fy~ : Double,
  cx~ : Double,
  cy~ : Double,
  skew? : Double = 0.0,
) -> CameraIntrinsics {
  { fx, fy, cx, cy, skew, }
}

///|
pub(all) struct Distortion {
  k1 : Double
  k2 : Double
  p1 : Double
  p2 : Double
  k3 : Double
} derive(Debug, Eq)

///|
pub fn Distortion::none() -> Distortion {
  { k1: 0.0, k2: 0.0, p1: 0.0, p2: 0.0, k3: 0.0, }
}

///|
pub fn Distortion::brown_conrady(
  k1? : Double = 0.0,
  k2? : Double = 0.0,
  p1? : Double = 0.0,
  p2? : Double = 0.0,
  k3? : Double = 0.0,
) -> Distortion {
  { k1, k2, p1, p2, k3, }
}

///|
pub(all) struct CameraPose {
  world_to_camera : @core.Mat34
} derive(Debug, Eq)

///|
pub fn CameraPose::identity() -> CameraPose {
  {
    world_to_camera: @core.mat34_from_rows(
      (1.0, 0.0, 0.0, 0.0),
      (0.0, 1.0, 0.0, 0.0),
      (0.0, 0.0, 1.0, 0.0),
    ),
  }
}

///|
pub fn CameraPose::new(world_to_camera~ : @core.Mat34) -> CameraPose {
  { world_to_camera, }
}

///|
pub fn distort_point(p : @core.Point2, distortion : Distortion) -> @core.Point2 {
  let x = p.x
  let y = p.y
  let r2 = x * x + y * y
  let r4 = r2 * r2
  let r6 = r4 * r2
  let radial = 1.0 +
    distortion.k1 * r2 +
    distortion.k2 * r4 +
    distortion.k3 * r6
  let xy2 = 2.0 * x * y
  @core.Point2::new(
    x=x * radial + distortion.p1 * xy2 + distortion.p2 * (r2 + 2.0 * x * x),
    y=y * radial + distortion.p1 * (r2 + 2.0 * y * y) + distortion.p2 * xy2,
  )
}

///|
pub fn undistort_point_iterative(
  distorted : @core.Point2,
  distortion : Distortion,
  iterations? : Int = 5,
) -> @core.Point2 {
  for estimate = distorted, i = 0; i < iterations; {
    let forward = distort_point(estimate, distortion)
    let dx = distorted.x - forward.x
    let dy = distorted.y - forward.y
    continue @core.Point2::new(x=estimate.x + dx, y=estimate.y + dy), i + 1
  } nobreak {
    estimate
  }
}

///|
pub fn normalized_to_pixel(
  p : @core.Point2,
  intrinsics : CameraIntrinsics,
) -> @core.Point2 {
  @core.Point2::new(
    x=intrinsics.fx * p.x + intrinsics.skew * p.y + intrinsics.cx,
    y=intrinsics.fy * p.y + intrinsics.cy,
  )
}

///|
pub fn pixel_to_normalized(
  pixel : @core.Point2,
  intrinsics : CameraIntrinsics,
) -> @core.Point2 {
  let y = (pixel.y - intrinsics.cy) / intrinsics.fy
  let x = (pixel.x - intrinsics.cx - intrinsics.skew * y) / intrinsics.fx
  @core.Point2::new(x~, y~)
}

///|
pub fn focal_from_fov(
  sensor_extent~ : Double,
  fov_radians~ : Double,
) -> Double raise @core.GeometryError {
  if sensor_extent <= 0.0 || fov_radians <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "sensor extent and fov must be positive",
    )
  }
  sensor_extent / (2.0 * @math.tan(fov_radians / 2.0))
}

///|
pub fn horizontal_fov(
  intrinsics : CameraIntrinsics,
  width~ : Double,
) -> Double raise @core.GeometryError {
  if intrinsics.fx <= 0.0 || width <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "fx and image width must be positive",
    )
  }
  2.0 * @math.atan(width / (2.0 * intrinsics.fx))
}

///|
pub fn vertical_fov(
  intrinsics : CameraIntrinsics,
  height~ : Double,
) -> Double raise @core.GeometryError {
  if intrinsics.fy <= 0.0 || height <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "fy and image height must be positive",
    )
  }
  2.0 * @math.atan(height / (2.0 * intrinsics.fy))
}

///|
pub fn project_point(
  camera_point : @core.Point3,
  intrinsics : CameraIntrinsics,
  distortion? : Distortion = Distortion::none(),
) -> @core.Point2 raise @core.GeometryError {
  if camera_point.z <= 0.000000000001 {
    raise @core.GeometryError::DegenerateInput(
      "point is behind the camera or on the image plane",
    )
  }
  let normalized = @core.Point2::new(
    x=camera_point.x / camera_point.z,
    y=camera_point.y / camera_point.z,
  )
  normalized_to_pixel(distort_point(normalized, distortion), intrinsics)
}

///|
pub fn project_point_with_pose(
  world_point : @core.Point3,
  intrinsics : CameraIntrinsics,
  pose : CameraPose,
  distortion? : Distortion = Distortion::none(),
) -> @core.Point2 raise @core.GeometryError {
  let camera_point = pose.world_to_camera.transform_point(world_point)
  project_point(camera_point, intrinsics, distortion~)
}

///|
pub fn bearing_from_pixel(
  pixel : @core.Point2,
  intrinsics : CameraIntrinsics,
  distortion? : Distortion = Distortion::none(),
) -> @core.Vec3 raise @core.GeometryError {
  let normalized = pixel_to_normalized(pixel, intrinsics)
  let undistorted = undistort_point_iterative(normalized, distortion)
  @core.Vec3::new(x=undistorted.x, y=undistorted.y, z=1.0).normalize()
}
