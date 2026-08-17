///|
test "track graph connects views through shared tracks" {
  let graph = TrackGraph::new(view_count=4)
  graph.add_track([0, 1])
  graph.add_track([1, 2])
  graph.add_track([3])
  assert_true(graph.connected(0, 2))
  assert_false(graph.connected(0, 3))
  assert_eq(graph.edge_count(), 2)
}

///|
test "track graph ignores invalid view ids" {
  let graph = TrackGraph::new(view_count=2)
  graph.add_track([-1, 0, 9])
  assert_eq(graph.edge_count(), 0)
  assert_eq(graph.component_count(), 2)
}
