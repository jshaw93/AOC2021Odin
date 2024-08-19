package aoc

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"
import "core:math"

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
    lines, _ := strings.split(string(file), "\r\n", context.temp_allocator)
    defer free_all(context.temp_allocator)

    // Part 1
    part1Gamma : [dynamic]rune
    defer delete(part1Gamma)
    part1Epsilon : [dynamic]rune
    defer delete(part1Epsilon)

    for index in 0..<len(lines[0]) {
        count0 : int = 0
        count1 : int = 0
        for line in lines {
            if line[index] == '0' do count0 += 1
            else do count1 += 1
        }
        if count0 > count1 {
            append(&part1Gamma, '0')
            append(&part1Epsilon, '1')
        } else {
            append(&part1Gamma, '1')
            append(&part1Epsilon, '0')
        }
    }
    part1GammaStr := utf8.runes_to_string(part1Gamma[:])
    part1EpsilonStr := utf8.runes_to_string(part1Epsilon[:])
    defer delete(part1GammaStr)
    defer delete(part1EpsilonStr)
    fmt.println("Part 1:", parseStrBinToInt(part1GammaStr) * parseStrBinToInt(part1EpsilonStr))

    // Part 2
    oxyRating := parseStrBinToInt(findValue(lines, 0, true))
    co2Rating := parseStrBinToInt(findValue(lines, 0, false))
    fmt.println("Part 2:", oxyRating * co2Rating)
}

parseStrBinToInt :: proc(binStr: string) -> int {
    num : f64 = 0
    index : int = 0
    #reverse for char in binStr {
        if char == '1' {
            // fmt.println(num, char, index, math.pow_f64(2, f64(index)))
            num += math.pow_f64(2, f64(index))
        }
        index += 1
    }
    return int(num)
}

findCriteria :: proc(data: []string, index: int, flag: bool) -> bool {
    count0 : int = 0
    count1 : int = 1
    for i in data {
        if i[index] == '0' do count0 += 1
        else do count1 += 1
    }
    if flag do return count1 >= count0
    else do return count0 >= count1
}

findValue :: proc(data: []string, index: int, flag: bool) -> string {
    newData : [dynamic]string
    defer delete(newData)
    for line in data {
        check := findCriteria(data, index, flag)
        check1 : rune
        if check == false do check1 = '0'
        else do check1 = '1'
        if rune(line[index]) == check1 {
            append(&newData, line)
        }
    }
    newIndex := index + 1
    if len(newData) < 1 || newIndex >= len(data[0]) do return data[0]
    return findValue(newData[:], newIndex, flag)
}
