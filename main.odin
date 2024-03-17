package main


// Raytracing In One Weekend - Version 4.0.0-alpha.1, 2023-08-06
// https://raytracing.github.io/books/RayTracingInOneWeekend.html

main :: proc() {
	world := Hittable_List{}

	material_ground := Material {
		type   = .LAMBERTIAN,
		albedo = {0.8, 0.8, 0},
	}
	material_center := Material {
		type   = .LAMBERTIAN,
		albedo = {0.7, 0.3, 0.3},
	}
	material_left := Material {
		type   = .METAL,
		albedo = {0.8, 0.8, 0.8},
		fuzz   = 0.3,
	}
	material_right := Material {
		type   = .METAL,
		albedo = {0.8, 0.6, 0.2},
		fuzz   = 1.0,
	}

	append(&world.objects, Sphere{{0, -100.5, -1}, 100, &material_ground})
	append(&world.objects, Sphere{{0, 0, -1}, 0.5, &material_center})
	append(&world.objects, Sphere{{-1, 0, -1}, 0.5, &material_left})
	append(&world.objects, Sphere{{1, 0, -1}, 0.5, &material_right})

	cam := Camera {
		aspect_ratio      = 16.0 / 9.0,
		image_width       = 400,
		samples_per_pixel = 100,
		max_depth         = 50,
	}

	camera_render(cam, world)
}
