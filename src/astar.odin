package main

import "core:math"
import "core:slice"
import "core:container/priority_queue"

Node :: struct {
    parent: [2]i32,
    g: i32,
    h: i32,
}

astar_find_path :: proc (world: World, start, end: [2]i32, allocator:=context.allocator) -> [][2]i32 {
    open_map: map[[2]i32]Node
    closed_map: map[[2]i32]Node

    open_map.allocator = context.temp_allocator
    closed_map.allocator = context.temp_allocator

    reserve_map(&open_map, 128 * size_of(open_map))
    reserve_map(&closed_map, 128 * size_of(closed_map))

    open_map[start] = Node {
        parent = { -1, -1 },
    }

    neighbors_template: [8][2]i32 = {
        { -1, -1 }, { 0, -1 }, { 1, -1 },
        { -1,  0 },            { 1,  0 },
        { -1,  1 }, { 0,  1 }, { 1,  1 },
    }

    for {
        min_node: Node
        min_node_key := [2]i32{ -1, -1 }
        for node_pos, node in open_map {
            if min_node_key == { -1, -1 } {
                min_node = node
                min_node_key = node_pos
            }

            f := node.g + node.h
            if (f < min_node.g + min_node.h) ||
                (f == min_node.g + min_node.h && node.h <= min_node.h)
            {
                min_node = node
                min_node_key = node_pos
            }
        }


        closed_map[min_node_key] = min_node
        delete_key(&open_map, min_node_key)

        if min_node_key == end {
            break
        }

        for neighbor_offset in neighbors_template {
            neighbor := min_node_key + neighbor_offset
            tile := world_get_tile(world, neighbor)

            invalid_tile_types := bit_set[TileType]{ .INVALID, .WALL }
            if tile.type in invalid_tile_types || neighbor in closed_map {
                continue
            }

            new_neighbor_node := Node {
                g = get_squared_distance(start, neighbor),
                h = get_squared_distance(neighbor, end),
                parent = min_node_key,
            }

            if neighbor not_in open_map {
                open_map[neighbor] = new_neighbor_node
            } else {
                old_node := open_map[neighbor]
                old_node_f := old_node.g + old_node.h
                new_node_f := new_neighbor_node.g + new_neighbor_node.h

                if old_node_f > new_node_f {
                    open_map[neighbor] = new_neighbor_node
                }
            }
        }
    }

    return reconstruct_path(closed_map, end)
}

get_squared_distance :: proc (p1, p2: [2]i32) -> i32 {
    return i32(math.pow(f32(p2.x - p1.x), 2) + math.pow(f32(p2.y - p1.y), 2))
}

reconstruct_path :: proc (closed_map: map[[2]i32]Node, end_pos: [2]i32, allocator:=context.allocator) -> [][2]i32 {
    node := closed_map[end_pos]
    path: [dynamic][2]i32
    append(&path, end_pos)

    for {
        append(&path, node.parent)
        if node.parent == { -1, -1 } {
            break
        }
        node = closed_map[node.parent]
    }

    return path[:]
}
