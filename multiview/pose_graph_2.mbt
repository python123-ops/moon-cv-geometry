///|
/// Weighted graph of relative camera constraints.
pub(all) struct WeightedPoseGraph {
  vertices : Int
  mut weights : Array[Array[Double]]
}

///|
pub fn WeightedPoseGraph::new(vertices : Int) -> WeightedPoseGraph {
  let rows : Array[Array[Double]] = []
  for _ in 0..<vertices.max(0) {
    let row : Array[Double] = []
    for _ in 0..<vertices.max(0) {
      row.push(0.0)
    }
    rows.push(row)
  }
  { vertices: vertices.max(0), weights: rows }
}

///|
pub fn WeightedPoseGraph::connect(
  graph : WeightedPoseGraph,
  left : Int,
  right : Int,
  weight : Double,
) -> Unit {
  if left >= 0 &&
    right >= 0 &&
    left < graph.vertices &&
    right < graph.vertices &&
    left != right {
    graph.weights[left][right] = weight.max(0.0)
    graph.weights[right][left] = weight.max(0.0)
  }
}

///|
pub fn WeightedPoseGraph::disconnect(
  graph : WeightedPoseGraph,
  left : Int,
  right : Int,
) -> Unit {
  graph.connect(left, right, 0.0)
}

///|
pub fn WeightedPoseGraph::weight(
  graph : WeightedPoseGraph,
  left : Int,
  right : Int,
) -> Double {
  if left < 0 || right < 0 || left >= graph.vertices || right >= graph.vertices {
    0.0
  } else {
    graph.weights[left][right]
  }
}

///|
pub fn WeightedPoseGraph::has_edge(
  graph : WeightedPoseGraph,
  left : Int,
  right : Int,
) -> Bool {
  graph.weight(left, right) > 0.0
}

///|
pub fn WeightedPoseGraph::neighbors(
  graph : WeightedPoseGraph,
  vertex : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  if vertex < 0 || vertex >= graph.vertices {
    return result
  }
  for i in 0..<graph.vertices {
    if graph.weights[vertex][i] > 0.0 {
      result.push(i)
    }
  }
  result
}

///|
pub fn WeightedPoseGraph::degree(
  graph : WeightedPoseGraph,
  vertex : Int,
) -> Int {
  graph.neighbors(vertex).length()
}

///|
pub fn WeightedPoseGraph::edge_count(graph : WeightedPoseGraph) -> Int {
  let mut count = 0
  for i in 0..<graph.vertices {
    for j in (i + 1)..<graph.vertices {
      if graph.weights[i][j] > 0.0 {
        count += 1
      }
    }
  }
  count
}

///|
pub fn WeightedPoseGraph::weight_sum(graph : WeightedPoseGraph) -> Double {
  let mut result = 0.0
  for i in 0..<graph.vertices {
    for j in (i + 1)..<graph.vertices {
      result += graph.weights[i][j]
    }
  }
  result
}

///|
pub fn WeightedPoseGraph::connected(
  graph : WeightedPoseGraph,
  start : Int,
  goal : Int,
) -> Bool {
  if start < 0 || goal < 0 || start >= graph.vertices || goal >= graph.vertices {
    return false
  }
  let visited : Array[Int] = [start]
  let queue : Array[Int] = [start]
  while queue.length() > 0 {
    let current = queue.remove(0)
    if current == goal {
      return true
    }
    for neighbor in graph.neighbors(current) {
      if !visited.contains(neighbor) {
        visited.push(neighbor)
        queue.push(neighbor)
      }
    }
  }
  false
}

///|
pub fn WeightedPoseGraph::component_count(graph : WeightedPoseGraph) -> Int {
  let mut count = 0
  for vertex in 0..<graph.vertices {
    let mut previous = false
    for earlier in 0..<vertex {
      if graph.connected(earlier, vertex) {
        previous = true
      }
    }
    if !previous {
      count += 1
    }
  }
  count
}

///|
pub fn WeightedPoseGraph::isolated_vertices(
  graph : WeightedPoseGraph,
) -> Array[Int] {
  let result : Array[Int] = []
  for vertex in 0..<graph.vertices {
    if graph.degree(vertex) == 0 {
      result.push(vertex)
    }
  }
  result
}

///|
pub fn WeightedPoseGraph::strongest_neighbor(
  graph : WeightedPoseGraph,
  vertex : Int,
) -> Int? {
  let neighbors = graph.neighbors(vertex)
  if neighbors.length() == 0 {
    return None
  }
  let mut best = neighbors[0]
  for neighbor in neighbors[1:] {
    if graph.weight(vertex, neighbor) > graph.weight(vertex, best) {
      best = neighbor
    }
  }
  Some(best)
}

///|
pub fn WeightedPoseGraph::normalize_weights(
  graph : WeightedPoseGraph,
) -> WeightedPoseGraph {
  let sum = graph.weight_sum()
  if sum <= 0.0 {
    graph
  } else {
    for i in 0..<graph.vertices {
      for j in 0..<graph.vertices {
        graph.weights[i][j] /= sum
      }
    }
    graph
  }
}
