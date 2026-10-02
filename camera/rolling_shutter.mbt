///|
pub(all) struct RollingShutter {
  readout_seconds : Double
  image_height : Int
} derive(Debug, Eq)

///|
pub fn RollingShutter::new(
  readout_seconds~ : Double,
  image_height~ : Int,
) -> RollingShutter raise @core.GeometryError {
  if readout_seconds < 0.0 || image_height <= 0 {
    raise @core.GeometryError::DegenerateInput(
      "rolling shutter parameters are invalid",
    )
  }
  { readout_seconds, image_height, }
}

///|
pub fn RollingShutter::row_time(model : RollingShutter, y : Double) -> Double {
  let normalized = @core.clamp(
      y,
      lo=0.0,
      hi=Double::from_int(model.image_height - 1),
    ) /
    Double::from_int(model.image_height)
  model.readout_seconds * normalized
}

///|
pub fn RollingShutter::midpoint_time(model : RollingShutter) -> Double {
  model.readout_seconds / 2.0
}

///|
pub fn rolling_pose(
  pose : CameraPose,
  velocity : @core.Vec3,
  time : Double,
) -> CameraPose {
  let translation = pose.translation().add(velocity.scale(time))
  CameraPose::from_rotation_translation(pose.rotation(), translation)
}

///|
pub fn rolling_project(
  point : @core.Point3,
  intrinsics : CameraIntrinsics,
  pose : CameraPose,
  model : RollingShutter,
  velocity : @core.Vec3,
) -> @core.Point2 raise @core.GeometryError {
  let first = project_point_with_pose(point, intrinsics, pose)
  let updated = rolling_pose(pose, velocity, model.row_time(first.y))
  project_point_with_pose(point, intrinsics, updated)
}

///|
pub fn motion_blur_displacement(
  velocity : @core.Vec3,
  depth~ : Double,
  intrinsics : CameraIntrinsics,
  exposure~ : Double,
) -> @core.Vec2 raise @core.GeometryError {
  if depth <= 0.0 || exposure < 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "motion blur parameters are invalid",
    )
  }
  @core.Vec2::new(
    x=intrinsics.fx * velocity.x / depth * exposure,
    y=intrinsics.fy * velocity.y / depth * exposure,
  )
}
