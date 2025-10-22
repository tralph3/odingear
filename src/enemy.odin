package main
import "core:math/linalg"
import rl "vendor:raylib"
import "core:fmt"

Enemy :: struct {
    pos: [2]f32,
    speed: f32,
    shape: rl.Rectangle,
}

enemy_move_to_target :: proc (enemy: ^Enemy, target: [2]i32, world: World) {
    path := astar_find_path(world, {i32(enemy.pos.x), i32(enemy.pos.y)}, target)
    fmt.println(path)
    if len(path) <= 1 {
        return
    }

    target_tile := path[len(path) - 2]
    move_direction := [2]f32{f32(target_tile.x) + .5, f32(target_tile.y) + .5} - enemy.pos
    enemy.pos += linalg.normalize(move_direction) * enemy.speed
    // for tile in path {
    //     rl.DrawRectangle(i32(tile.x * world.tile_size), i32(tile.y * world.tile_size), world.tile_size, world.tile_size, rl.PURPLE)
    // }
}

enemy_check_collision :: proc (enemy: Enemy, world: World) {
    current_tile_type := world_get_tile(world, f32_arr_to_i32(enemy.pos)).type

}


