package main

import "core:fmt"
import "core:strings"


Color :: Vec3

write_color :: proc(sb: ^strings.Builder, px_color: Color) {
	ir := i32(255 * px_color.r)
	ig := i32(255 * px_color.g)
	ib := i32(255 * px_color.b)
	fmt.sbprintf(sb, "%v %v %v\n", ir, ig, ib)
}
