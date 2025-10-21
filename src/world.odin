package main

TileType :: enum {
    EMPTY,
    WALL,
    INVALID,
}

Tile :: struct {
    type: TileType,
}

World :: struct {
    data: []Tile,
    width: i32,
    height: i32,
    tile_size: i32,
    starting_pos: [2]i32
}

world_init :: proc (width, height: i32, tile_size: i32, starting_pos: [2]i32) -> World {
    world := World {
        data = make([]Tile, width * height),
        width = width,
        height = height,
        tile_size = tile_size,
        starting_pos = starting_pos
    }

    return world
}

world_destroy :: proc (world: World) {
    delete(world.data)
}

world_get_tile :: proc (world: World, coord: [2]i32) -> Tile {
    if coord.y >= world.height || coord.y < 0 || coord.x >= world.width || coord.x < 0 {
        return Tile { type = .INVALID }
    }

    index := coord.y * world.width + coord.x
    return world.data[index]
}
