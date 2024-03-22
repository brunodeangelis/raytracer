package main

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "core:sync"
import "core:thread"
import "core:time"

import stbi "vendor:stb/image"


// Ray Tracing: The Next Week - Version 4.0.0-alpha.1, 2023-08-06
// https://raytracing.github.io/books/RayTracingTheNextWeek.html

pixel_index: int = 0

main :: proc() {
	world := Hittable_List{}

	material_ground := Material {
		type   = .LAMBERTIAN,
		albedo = {0.5, 0.5, 0.5},
	}
	append(&world.objects, Sphere{{0, -1000, 0}, 1000, &material_ground})

	for a in -11 ..< 11 {
		for b in -11 ..< 11 {
			choose_mat := rand.float64()
			center := Point3{f64(a) + 0.9 * rand.float64(), 0.2, f64(b) + 0.9 * rand.float64()}

			if linalg.length(center - {4, 0.2, 0}) > 0.9 {
				sphere_material: Material

				if choose_mat < 0.75 {
					// diffuse
					sphere_material = Material {
						type   = .LAMBERTIAN,
						albedo = cast(Color)(random_vec3() * random_vec3()),
					}
				} else if choose_mat < 0.9 {
					// metal
					sphere_material = Material {
						type   = .METAL,
						albedo = cast(Color)random_vec3(0.5, 1),
						fuzz   = rand.float64_range(0, 0.5),
					}
				} else {
					// glass
					sphere_material = Material {
						type = .DIELECTRIC,
						ir   = 1.5,
					}
				}

				append(&world.objects, Sphere{center, 0.2, new_clone(sphere_material)})
			}
		}
	}

	material1 := Material {
		type = .DIELECTRIC,
		ir   = 1.5,
	}
	append(&world.objects, Sphere{{0, 1, 0}, 1, &material1})

	material2 := Material {
		type   = .LAMBERTIAN,
		albedo = {0.4, 0.2, 0.1},
	}
	append(&world.objects, Sphere{{-4, 1, 0}, 1, &material2})

	material3 := Material {
		type   = .METAL,
		albedo = {0.7, 0.6, 0.5},
		fuzz   = 0,
	}
	append(&world.objects, Sphere{{4, 1, 0}, 1, &material3})


	image_width, samples_per_pixel, max_depth: int
	when ODIN_DEBUG {
		image_width = 300
		samples_per_pixel = 20
		max_depth = 10
	} else {
		image_width = 1200
		samples_per_pixel = 500
		max_depth = 50
	}

	cam := Camera {
		aspect_ratio      = 16.0 / 9.0,
		image_width       = image_width,
		samples_per_pixel = samples_per_pixel,
		max_depth         = max_depth,
		vfov              = 20,
		look_from         = {13, 2, 3},
		look_at           = {0, 0, 0},
		vup               = {0, 1, 0},
		defocus_angle     = 0.6,
		focus_dist        = 10,
	}

	camera_initialize(cam)

	start := time.now()

	pixels := make([]byte, cam.image_width * image_height * 3)

	NUM_THREADS :: 10
	threads := make([]^thread.Thread, NUM_THREADS)
	for t, i in threads {
		threads[i] = thread.create_and_start_with_poly_data3(raw_data(pixels), &world, &cam, render)
	}
	thread.join_multiple(..threads[:])

	fmt.printfln("\nRENDER TIME: %v", time.diff(start, time.now()))

	out_filename := "render.png"
	stbi.write_png(fmt.ctprintf(out_filename), i32(cam.image_width), i32(image_height), 3, raw_data(pixels), 0)
	fmt.printfln("Written '%v'", out_filename)
}
