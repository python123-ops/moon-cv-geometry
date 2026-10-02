///|
pub(all) struct PointCloudReport {
  total : Int
  positive_depth : Int
  minimum_depth : Double
  maximum_depth : Double
  centroid : @core.Point3
} derive(Debug, Eq)

///|
pub fn PointCloudReport::from_points(
  points : ArrayView[@core.Point3],
) -> PointCloudReport {
  let mut positive = 0
  let mut minimum = 0.0
  let mut maximum = 0.0
  if points.length() > 0 {
    minimum = points[0].z
    maximum = points[0].z
  }
  for point in points {
    if point.z > 0.0 {
      positive += 1
    }
    if point.z < minimum {
      minimum = point.z
    }
    if point.z > maximum {
      maximum = point.z
    }
  }
  let centroid = if points.length() == 0 {
    @core.Point3::new(x=0.0, y=0.0, z=0.0)
  } else {
    @core.centroid3(points) catch {
      _ => @core.Point3::new(x=0.0, y=0.0, z=0.0)
    }
  }
  {
    total: points.length(),
    positive_depth: positive,
    minimum_depth: minimum,
    maximum_depth: maximum,
    centroid,
  }
}

///|
pub fn PointCloudReport::positive_ratio(report : PointCloudReport) -> Double {
  if report.total == 0 {
    0.0
  } else {
    Double::from_int(report.positive_depth) / Double::from_int(report.total)
  }
}

///|
pub fn PointCloudReport::depth_span(report : PointCloudReport) -> Double {
  report.maximum_depth - report.minimum_depth
}

///|
pub fn PointCloudReport::is_usable(
  report : PointCloudReport,
  minimum_ratio? : Double = 0.8,
) -> Bool {
  report.total > 0 &&
  report.positive_ratio() >= minimum_ratio &&
  report.depth_span() > 0.0
}

///|
pub(all) struct ReprojectionSummary {
  total : Int
  inliers : Int
  outliers : Int
  rms : Double
  mean_inlier : Double
} derive(Debug, Eq)

///|
pub fn reprojection_summary(
  residuals : ArrayView[Double],
  outlier_threshold~ : Double,
) -> ReprojectionSummary {
  let mut inliers = 0
  let mut sum = 0.0
  let mut square = 0.0
  for residual in residuals {
    square += residual * residual
    if residual <= outlier_threshold {
      inliers += 1
      sum += residual
    }
  }
  let total = residuals.length()
  {
    total,
    inliers,
    outliers: total - inliers,
    rms: if total == 0 {
      0.0
    } else {
      (square / Double::from_int(total)).sqrt()
    },
    mean_inlier: if inliers == 0 {
      0.0
    } else {
      sum / Double::from_int(inliers)
    },
  }
}

///|
pub fn ReprojectionSummary::inlier_ratio(
  summary : ReprojectionSummary,
) -> Double {
  if summary.total == 0 {
    0.0
  } else {
    Double::from_int(summary.inliers) / Double::from_int(summary.total)
  }
}

///|
pub fn ReprojectionSummary::is_good(
  summary : ReprojectionSummary,
  maximum_rms? : Double = 2.0,
) -> Bool {
  summary.total > 0 && summary.rms <= maximum_rms && summary.inliers > 0
}

///|
pub(all) struct ViewGraph {
  adjacency : Array[Array[Bool]]
} derive(Debug, Eq)

///|
pub fn ViewGraph::new(view_count : Int) -> ViewGraph {
  let rows : Array[Array[Bool]] = []
  for _ in 0..<view_count {
    let row : Array[Bool] = []
    for _ in 0..<view_count {
      row.push(false)
    }
    rows.push(row)
  }
  { adjacency: rows, }
}

///|
pub fn ViewGraph::view_count(graph : ViewGraph) -> Int {
  graph.adjacency.length()
}

///|
pub fn ViewGraph::add_edge(graph : ViewGraph, left : Int, right : Int) -> Unit {
  if left >= 0 &&
    right >= 0 &&
    left < graph.view_count() &&
    right < graph.view_count() {
    graph.adjacency[left][right] = true
    graph.adjacency[right][left] = true
  }
}

///|
pub fn ViewGraph::has_edge(graph : ViewGraph, left : Int, right : Int) -> Bool {
  left >= 0 &&
  right >= 0 &&
  left < graph.view_count() &&
  right < graph.view_count() &&
  graph.adjacency[left][right]
}

///|
pub fn ViewGraph::component_count(graph : ViewGraph) -> Int {
  let visited : Array[Bool] = []
  for _ in 0..<graph.view_count() {
    visited.push(false)
  }
  let mut components = 0
  for start in 0..<graph.view_count() {
    if !visited[start] {
      components += 1
      let queue : Array[Int] = [start]
      visited[start] = true
      let mut cursor = 0
      while cursor < queue.length() {
        let current = queue[cursor]
        for next in 0..<graph.view_count() {
          if graph.adjacency[current][next] && !visited[next] {
            visited[next] = true
            queue.push(next)
          }
        }
        cursor += 1
      }
    }
  }
  components
}
