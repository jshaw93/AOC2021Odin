package aoc

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"

Vec2d :: [2]int
Vec3d :: [3]int

main :: proc() {
    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
                for _, entry in track.allocation_map {
                    fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
                }
            }
            if len(track.bad_free_array) > 0 {
                fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
                for entry in track.bad_free_array {
                    fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
    }

    handle, err := os.open("input.txt")
    defer os.close(handle)
    file, success := os.read_entire_file_from_handle(handle)
    defer delete(file)
    lines, _ := strings.split(string(file), "\r\n")

    // Part 1
    position : Vec2d = {0,0}
    for line in lines {
        directions, _ := strings.split(line, " ", context.temp_allocator)
        spaces, _ := strconv.parse_int(directions[1], 10)
        direction := directions[0]
        if direction == "forward" do position.x += spaces
        else if direction == "down" do position.y += spaces
        else if direction == "up" do position.y -= spaces
        free_all(context.temp_allocator)
    }
    fmt.println("Part 1:", position.x*position.y)

    // Part 2
    position2 : Vec3d = {0,0,0}
    for line in lines {
        directions, _ := strings.split(line, " ", context.temp_allocator)
        spaces, _ := strconv.parse_int(directions[1], 10)
        direction := directions[0]
        if direction == "forward" {
            position2.x += spaces
            position2.y += position2.z*spaces
        } else if direction == "down" do position2.z += spaces
        else if direction == "up" do position2.z -= spaces
        free_all(context.temp_allocator)
    }
    fmt.println("Part 2:", position2.x*position2.y)
}
