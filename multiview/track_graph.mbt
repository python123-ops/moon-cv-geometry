///|
/// Sparse view connectivity induced by shared feature tracks.
pub(all) struct TrackGraph {
  view_count : Int
  edges : Array[(Int, Int)]
}

///|
pub fn TrackGraph::new(view_count~ : Int) -> TrackGraph {
  { view_count: view_count.max(0), edges: [], }
}

///|
pub fn TrackGraph::add_track(
  graph : TrackGraph,
  views : ArrayView[Int],
) -> Unit {
  for i in 0..<views.length() {
    for j in (i + 1)..<views.length() {
      let a = views[i]
      let b = views[j]
      if a >= 0 &&
        b >= 0 &&
        a < graph.view_count &&
        b < graph.view_count &&
        a != b {
        let edge = if a < b { (a, b) } else { (b, a) }
        if !graph.edges.contains(edge) {
          graph.edges.push(edge)
        }
      }
    }
  }
}

///|
pub fn TrackGraph::edge_count(graph : TrackGraph) -> Int {
  graph.edges.length()
}

///|
pub fn track_neighbors(graph : TrackGraph, view : Int) -> Array[Int] {
  let result : Array[Int] = []
  for edge in graph.edges {
    let (a, b) = edge
    if a == view {
      result.push(b)
    } else if b == view {
      result.push(a)
    }
  }
  result
}

///|
pub fn TrackGraph::connected(
  graph : TrackGraph,
  start : Int,
  goal : Int,
) -> Bool {
  if start < 0 ||
    goal < 0 ||
    start >= graph.view_count ||
    goal >= graph.view_count {
    return false
  }
  let visited : Array[Int] = [start]
  let queue : Array[Int] = [start]
  while queue.length() > 0 {
    let current = queue.remove(0)
    if current == goal {
      return true
    }
    for next in track_neighbors(graph, current) {
      if !visited.contains(next) {
        visited.push(next)
        queue.push(next)
      }
    }
  }
  false
}

///|
pub fn TrackGraph::component_count(graph : TrackGraph) -> Int {
  let mut count = 0
  for start in 0..<graph.view_count {
    let mut seen_before = false
    for prior in 0..<start {
      if graph.connected(prior, start) {
        seen_before = true
      }
    }
    if !seen_before {
      count += 1
    }
  }
  count
}

///|
pub fn isolated_views(graph : TrackGraph) -> Array[Int] {
  let result : Array[Int] = []
  for view in 0..<graph.view_count {
    if track_neighbors(graph, view).length() == 0 {
      result.push(view)
    }
  }
  result
}
