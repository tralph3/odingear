package main

import rl "vendor:raylib"

Rectangle :: struct {
	x:      f32,
	y:      f32,
	width:  f32,
	height: f32,
}

Circle :: struct {
    radius: f32,
    x: f32,
    y: f32,
}

Shape :: union {
    Rectangle,
    Circle,
}

physics_collide_list :: proc (shapes: []Shape) {
    
}