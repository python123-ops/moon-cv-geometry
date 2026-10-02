///|
pub(all) struct PointTrack {
  world : @core.Point3
  observations : Array[@camera.CalibrationObservation]
} derive(Debug, Eq)

///|
pub fn PointTrack::new(
  world~ : @core.Point3,
  observations~ : Array[@camera.CalibrationObservation],
) -> PointTrack {
  { world, observations, }
}

///|
pub fn track_reprojection_errors(
  track : PointTrack,
  intrinsics : @camera.CameraIntrinsics,
  pose : @camera.CameraPose,
) -> Array[Double] raise @core.GeometryError {
  let result : Array[Double] = []
  for observation in track.observations {
    let predicted = @camera.project_point_with_pose(
      track.world,
      intrinsics,
      pose,
    )
    result.push(predicted.minus(observation.pixel).norm())
  }
  result
}

///|
pub fn tracks_cost(
  tracks : ArrayView[PointTrack],
  intrinsics : @camera.CameraIntrinsics,
  pose : @camera.CameraPose,
) -> Double raise @core.GeometryError {
  let mut cost = 0.0
  let mut count = 0
  for track in tracks {
    let values = track_reprojection_errors(track, intrinsics, pose)
    for value in values {
      cost += value * value
      count += 1
    }
  }
  if count == 0 {
    raise @core.GeometryError::NotEnoughPoints("tracks need observations")
  }
  cost / Double::from_int(count)
}

///|
pub fn track_visibility(
  track : PointTrack,
  pose : @camera.CameraPose,
  near? : Double = 0.000001,
) -> Bool {
  is_visible(track.world, pose, near~)
}

///|
pub fn visible_track_count(
  tracks : ArrayView[PointTrack],
  pose : @camera.CameraPose,
) -> Int {
  let mut result = 0
  for track in tracks {
    if track_visibility(track, pose) {
      result += 1
    }
  }
  result
}

///|
pub fn robust_track_cost(
  tracks : ArrayView[PointTrack],
  intrinsics : @camera.CameraIntrinsics,
  pose : @camera.CameraPose,
  delta? : Double = 1.0,
) -> Double raise @core.GeometryError {
  let mut cost = 0.0
  for track in tracks {
    let errors = track_reprojection_errors(track, intrinsics, pose)
    for error in errors {
      let a = @core.abs(error)
      cost += if a <= delta { 0.5 * a * a } else { delta * (a - 0.5 * delta) }
    }
  }
  cost
}

///|
pub fn observation_count(tracks : ArrayView[PointTrack]) -> Int {
  let mut result = 0
  for track in tracks {
    result += track.observations.length()
  }
  result
}

///|
pub fn track_bounds(
  tracks : ArrayView[PointTrack],
) -> @core.Rect2 raise @core.GeometryError {
  let pixels : Array[@core.Point2] = []
  for track in tracks {
    for observation in track.observations {
      pixels.push(observation.pixel)
    }
  }
  @core.rect2_from_points(pixels)
}

///|
pub fn normalized_track_error(
  track : PointTrack,
  intrinsics : @camera.CameraIntrinsics,
  pose : @camera.CameraPose,
) -> Double raise @core.GeometryError {
  let errors = track_reprojection_errors(track, intrinsics, pose)
  if errors.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints("track has no observations")
  }
  @core.mean(errors)
}
