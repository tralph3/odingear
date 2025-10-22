package main

import rl "vendor:raylib"
import "core:fmt"
import "core:time"
import "core:prof/spall"
import "core:sync"
import "base:runtime"

Player :: struct {
    pos: [2]f32,
    speed: f32,
    size: i32,
}

main :: proc () {
    rl.InitWindow(800, 600, "Metal Gear")
    rl.SetTargetFPS(60)

    spall_ctx = spall.context_create("trace_test.spall")
	defer spall.context_destroy(&spall_ctx)

	buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
	defer delete(buffer_backing)

	spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
	defer spall.buffer_destroy(&spall_ctx, &spall_buffer)

	spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)

    world := world_init(
        width=32,
        height=32,
        tile_size=20,
        starting_pos={ 15, 15 }
    )
    defer world_destroy(world)

    player := Player {
        speed = 0.3,
        size = 10,
        pos = { f32(world.starting_pos.x), f32(world.starting_pos.y) }
    }

    enemy := Enemy {
        speed = 0.15,
        pos = { 3, 3 }
    }

    camera := rl.Camera2D {
        zoom = 1
    }


    start_path := [2]i32{ 0, 0 }
    end_path := [2]i32{ 0, 0 }

    frame_counter: i32

    for !rl.WindowShouldClose() {
        frame_counter += 1
        camera.offset = {f32(rl.GetRenderWidth()) / 2.0, f32(rl.GetRenderHeight()) / 2.0}

        if rl.IsMouseButtonPressed(.LEFT) || rl.IsMouseButtonPressed(.RIGHT) {
            mouse_pos := rl.GetMousePosition()
            world_pos := rl.GetScreenToWorld2D(mouse_pos, camera)
            tile_pos := world_pos / f32(world.tile_size)

            if rl.IsKeyDown(.LEFT_CONTROL) {
                if rl.IsMouseButtonPressed(.LEFT) {
                    start_path = { i32(tile_pos.x), i32(tile_pos.y) }
                } else {
                    end_path = { i32(tile_pos.x), i32(tile_pos.y) }
                }

            } else {
                index := i32(tile_pos.y) * world.width + i32(tile_pos.x)
                if !(index < 0 || index >= i32(len(world.data))) {
                    world.data[index] = Tile {
                        type = .WALL,
                    }
                }
            }
        }

        old_player_pos := player.pos

        if rl.IsKeyDown(.DOWN) {
            player.pos.y += player.speed
        } else if rl.IsKeyDown(.UP) {
            player.pos.y -= player.speed
        } else if rl.IsKeyDown(.LEFT) {
            player.pos.x -= player.speed
        } else if rl.IsKeyDown(.RIGHT) {
            player.pos.x += player.speed
        }

        if is_player_colliding_with_world(player, world) {
            player.pos = old_player_pos
        }
        camera.target = player.pos * f32(world.tile_size)

        // before := time.now()
        // path := astar_find_path(world, start_path, end_path, context.temp_allocator)
        // after := time.now()
        // fmt.println(f32(after._nsec - before._nsec) / 1000 / 1000)
        
        rl.BeginDrawing()

        rl.BeginMode2D(camera)
        
        rl.ClearBackground(rl.BLACK)

        rl.DrawRectangle(0,0, world.width * world.tile_size, world.width * world.tile_size, rl.GRAY)
        draw_world(world)
        enemy_move_to_target(&enemy, {i32(player.pos.x), i32(player.pos.y)}, world)
        
        
        rl.DrawRectangle(i32(player.pos.x * f32(world.tile_size)), i32(player.pos.y * f32(world.tile_size)), player.size, player.size, rl.RED)
        rl.DrawRectangle(i32(enemy.pos.x * f32(world.tile_size)), i32(enemy.pos.y * f32(world.tile_size)), 10, 10, rl.MAGENTA)
        
        // for tile in path {
        //     rl.DrawRectangle(i32(tile.x * world.tile_size), i32(tile.y * world.tile_size), world.tile_size, world.tile_size, rl.PURPLE)
        // }

        rl.EndMode2D()

        rl.DrawFPS(0, 0)
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
}


draw_world :: proc (world: World) {
    for tile, i in world.data {
        if tile.type == .EMPTY { continue }

        y := i32(i) / world.width
        x := i32(i) % world.width

        rl.DrawRectangle(x * world.tile_size, y * world.tile_size, world.tile_size, world.tile_size, rl.GREEN)
    }
}

is_player_colliding_with_world :: proc (player: Player, world: World) -> bool {
    for tile, i in world.data {
        if tile.type == .EMPTY { continue }

        tile_y := i32(i) / world.width
        tile_x := i32(i) % world.width

        if rl.CheckCollisionRecs(
            {player.pos.x, player.pos.y, 0.5, 0.5},
            {f32(tile_x), f32(tile_y), 1, 1},
        ) { return true }
    }

    return false
}

spall_ctx: spall.Context
@(thread_local) spall_buffer: spall.Buffer


@(instrumentation_enter)
spall_enter :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
	spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
}

@(instrumentation_exit)
spall_exit :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
	spall._buffer_end(&spall_ctx, &spall_buffer)
}
