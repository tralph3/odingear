package main

f32_arr_to_i32 :: proc (arr: [2]f32) -> [2]i32 {
    return { i32(arr.x), i32(arr.y) }
}