# -*- encoding: utf-8 -*-
#
# Copyright (c) 2012-2017 Sung Pae <self@sungpae.com>
# Distributed under the MIT license.
# http://www.opensource.org/licenses/mit-license.php

module NERV; end
module NERV::Util; end

# I am aware of RGL and TSort; this implementation for amusement only!
class NERV::Util::DirectedGraph
  class CyclicDependencyError < RuntimeError; end

  DIRECTION = { :in => 0, :out => 1 }

  attr_reader :table

  # Takes a list of vertices and outbound edges.
  def initialize list
    # The graph is actually stored in a hash table (a.k.a. adjacency list)
    @table, din, dout = {}, DIRECTION[:in], DIRECTION[:out]

    # Storing only incoming (or outgoing) edges per node allows for fast
    # appends, but storing both sets of edges per node allows for fast
    # bi-directional traversal, and simple reversals.
    #
    # We are interested in analyzing a static graph, so we choose the latter
    list.each do |v, es|
      # [inbound, outbound]
      table[v] ||= [[], []]
      es.each do |e|
        table[e] ||= [[], []]
        # Storing object references makes for expensive deep-copies, so we
        # just record the vertex ids instead.
        table[e][dout].push v
        table[v][din ].push e
      end
    end
  end

  # Return a new graph rooted at given node.
  def subgraph id, direction = :in
    stack, dir = [], DIRECTION[direction]

    # Walk the graph, populating our new node list
    (walk = lambda do |v|
      es = table[v][dir]
      stack.push [v, es]
      es.each { |e| walk.call e }
    end).call id

    self.class.new stack
  end

  # Tarjan's topological sort. Order determined via reverse depth-first
  # traversal.
  def tsort
    visited, traversed, stack, dir = {}, {}, [], DIRECTION[:out]

    dfs = lambda do |v|
      if visited.has_key? v
        if traversed.has_key? v
          next
        else
          # We are revisiting a node that is currently being traversed.
          raise CyclicDependencyError, '%s <-> %s' % [v, table[v][dir].find(v).first]
        end
      end
      visited[v] = true
      table[v][dir].each { |e| dfs.call e }
      traversed[v] = true
      stack.push v
    end

    table.each_key { |id| dfs.call id }
    stack.reverse
  end

  # Each "level" of a directed acyclic graph is defined by the longest path
  # to a root node.
  def levels
    parents, dir = {}, DIRECTION[:out]

    tsort.reverse_each do |id|
      parents[id] = table[id][dir].map { |e| (parents[e] || 0) + 1 }.max || 0
    end

    parents.group_by { |id,n| n }.sort_by { |k,v| k }.map { |k,v| [k, v.map(&:first)] }
  end

  # Returns a new graph of the union of the two graphs
  def + other
    alist = {}

    (table.to_a + other.table.to_a).each do |id, (ins, outs)|
      alist[id] = alist.has_key?(id) ? (alist[id] + ins).uniq : [ins]
    end

    self.class.new alist
  end

  # Return a new graph with edge directions swapped.
  def reverse
    self.class.new table.inject([]) { |s, (v, (ins, outs))| s.push [v, outs] }
  end

  # Options are passed to GraphViz#output
  def output opts = { :pdf => 'graph.pdf' }
    # Graphviz is a heavy library dependency, so we load on demand
    require 'graphviz'

    GraphViz.digraph :G, :rankdir => :LR do |g|
      g.add_nodes table.keys
      table.each { |v, (ins, outs)| g.add_edges v, ins }
    end.output opts
  end
end
