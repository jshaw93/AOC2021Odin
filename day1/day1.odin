package aoc

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"

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
    count : int = 0
    lastDepth : int
    for line in lines {
        depth, _ := strconv.parse_int(line, 10)
        if lastDepth == 0 {
            lastDepth = depth
            continue
        }
        if depth > lastDepth do count += 1
        lastDepth = depth
    }
    fmt.println("Part 1:", count)

    // Part 2
    count = 0
    lastDepth = 0
    measurements : [dynamic]int
    defer delete(measurements)
    summation : int = 0
    for i in 0..<len(lines) {
        depth, _ := strconv.parse_int(lines[i], 10)
        for j in 0..<2 {
            if i+j+1 >= len(lines) do break
            next, ok := strconv.parse_int(lines[i+j+1])
            depth += next
        }
        append(&measurements, depth)
    }
    for measurement in measurements {
        if lastDepth == 0 {
            lastDepth = measurement
            continue
        }
        if measurement > lastDepth do count += 1
        lastDepth = measurement
    }
    fmt.println("Part 2:", count)
}
