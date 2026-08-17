///|
pub(all) struct CameraView {
  view_id : Int
  intrinsics : CameraIntrinsics
  pose : CameraPose
} derive(Debug, Eq)

///|
pub fn CameraView::new(
  id~ : Int,
  intrinsics~ : CameraIntrinsics,
  pose~ : CameraPose,
) -> CameraView {
  { view_id: id, intrinsics, pose }
}

///|
pub(all) struct ProjectedObservation {
  view_id : Int
  pixel : @core.Point2
} derive(Debug, Eq)

///|
pub(all) struct CameraRig {
  views : Array[CameraView]
} derive(Debug, Eq)

///|
pub fn CameraRig::new(views : ArrayView[CameraView]) -> CameraRig {
  { views: views.to_owned() }
}

///|
pub fn CameraRig::length(rig : CameraRig) -> Int {
  rig.views.length()
}

///|
pub fn CameraRig::project(
  rig : CameraRig,
  point : @core.Point3,
) -> Array[ProjectedObservation] raise @core.GeometryError {
  let result : Array[ProjectedObservation] = []
  for view in rig.views {
    result.push({
      view_id: view.view_id,
      pixel: project_point_with_pose(point, view.intrinsics, view.pose),
    })
  }
  result
}

///|
pub fn CameraRig::find(rig : CameraRig, view_id : Int) -> CameraView? {
  for view in rig.views {
    if view.view_id == view_id {
      return Some(view)
    }
  }
  None
}

///|
pub fn CameraRig::visible_in_all(rig : CameraRig, point : @core.Point3) -> Bool {
  for view in rig.views {
    if !is_visible_from_pose(point, view.pose) {
      return false
    }
  }
  true
}

///|
fn is_visible_from_pose(point : @core.Point3, pose : CameraPose) -> Bool {
  pose.world_to_camera.m20 * point.x +
  pose.world_to_camera.m21 * point.y +
  pose.world_to_camera.m22 * point.z +
  pose.world_to_camera.m23 >
  0.000001
}

///|
pub fn CameraRig::common_projection(
  rig : CameraRig,
  point : @core.Point3,
) -> Array[ProjectedObservation] raise @core.GeometryError {
  if !rig.visible_in_all(point) {
    []
  } else {
    rig.project(point)
  }
}

///|
pub fn rig_baseline(
  rig : CameraRig,
  first_id~ : Int,
  second_id~ : Int,
) -> Double raise @core.GeometryError {
  let first = match rig.find(first_id) {
    Some(value) => value
    None =>
      raise @core.GeometryError::DegenerateInput(
        "first camera view does not exist",
      )
  }
  let second = match rig.find(second_id) {
    Some(value) => value
    None =>
      raise @core.GeometryError::DegenerateInput(
        "second camera view does not exist",
      )
  }
  first.pose.camera_center().minus(second.pose.camera_center()).norm()
}
