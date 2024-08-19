package aoc

import "core:fmt"
import "core:os"
import "core:mem"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"
import "core:math"
import "core:mem/virtual"

Board :: struct {
    rows : [5]string,
    cols : [5]string,
    rowCalled : [5][5]bool,
    colCalled : [5][5]bool,
    lastPlay : string,
}

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

    arena : virtual.Arena
    arenaErr := virtual.arena_init_growing(&arena)
    if arenaErr != nil do fmt.println("Arena Allocation failed!")
    arenaAlloc := virtual.arena_allocator(&arena)
    defer virtual.arena_destroy(&arena)

    handle, err := os.open("input.txt")
    defer os.close(handle)
    file, success := os.read_entire_file_from_handle(handle)
    defer delete(file)
    lines, _ := strings.split(string(file), "\r\n", arenaAlloc)

    plays : [dynamic]string
    defer delete(plays)
    boards : [dynamic]Board = {{}}
    defer delete(boards)
    prepareBoard : bool = false
    boardIndex : int = 0
    rowIndex : int = 0

    for line, index in lines {
        if index == 0 {
            playSplit := strings.split(line, ",", arenaAlloc)
            for play in playSplit do append(&plays, play)
            continue
        }
        if len(line) > 1 {
            prepareBoard = true
            board : ^Board
            if len(boards) == boardIndex + 1 {
                board = &boards[boardIndex]
            } else {
                board = {}
            }
            board.rows[rowIndex] = cleanString(line, arenaAlloc)
            rowIndex += 1
            // fmt.println(boards[boardIndex])
        }
        if len(line) == 0 && prepareBoard {
            prepareBoard = false
            boardIndex += 1
            rowIndex = 0
            newBoard : Board
            append(&boards, newBoard)
        }
    }
    for index in 0..<len(boards) {
        board : ^Board = &boards[index]
        for col in 0..<5 {
            colStrArray : [dynamic]string
            defer delete(colStrArray)
            for row in board.rows {
                rowSplit := strings.split(row, " ", arenaAlloc)
                rowCleanedSplit : [dynamic]string
                defer delete(rowCleanedSplit)
                for str, splitIndex in rowSplit {
                    if str != "" do append(&rowCleanedSplit, str)
                }
                append(&colStrArray, rowCleanedSplit[col])
            }
            board.cols[col] = strings.join(colStrArray[:], " ", arenaAlloc)
        }
    }
    board, play := playBingo(plays[:], boards[:], false, arenaAlloc)
    fmt.println("Part1:", getScore(board, play, arenaAlloc))
    lastBoard, lastPlay := playBingo(plays[:], boards[:], true, arenaAlloc)
    fmt.println("Part2:", getScore(lastBoard, lastPlay, arenaAlloc))
}

cleanString :: proc(str : string, allocator := context.allocator) -> string {
    strSplit := strings.split(str, " ", allocator)
    newStrArray : [dynamic]string
    defer delete(newStrArray)
    for val in strSplit {
        if val != "" do append(&newStrArray, val)
    }
    return strings.join(newStrArray[:], " ", allocator)
}

playBingo :: proc(plays : []string, boards : []Board, flag : bool = false, allocator := context.allocator) -> (^Board, string) {
    bingoBoards : [dynamic]^Board
    defer delete(bingoBoards)
    for play in plays {
        for &board, index in boards {
            for row, i in board.rows {
                rowNums := strings.split(row, " ", allocator)
                for num, j in rowNums {
                    if num == play && !test(&board, bingoBoards[:]) do board.rowCalled[i][j] = true
                }
            }
            for col, i in board.cols {
                colNums := strings.split(col, " ", allocator)
                for num, j in colNums {
                    if num == play && !test(&board, bingoBoards[:]) do board.colCalled[i][j] = true
                }
            }
            for row, i in board.rowCalled {
                bingo : bool = true
                for called in row {
                    if called == false do bingo = false
                }
                if bingo && !flag {
                    return &board, play
                }
                if bingo && !test(&board, bingoBoards[:]) {
                    board.lastPlay = play
                    append(&bingoBoards, &board)
                }
            }
            for col, i in board.colCalled {
                bingo : bool = true
                for called in col {
                    if !called do bingo = false
                }
                if bingo && !flag {
                    return &board, play
                }
                if bingo && !test(&board, bingoBoards[:]) {
                    board.lastPlay = play
                    append(&bingoBoards, &board)
                }
            }
        }
    }
    last := pop(&bingoBoards)
    return last, last.lastPlay
}

getScore :: proc(boardPtr: ^Board, playStr : string, allocator := context.allocator) -> int {
    score : int = 0
    play, _ := strconv.parse_int(playStr, 10)
    board := boardPtr
    rows : [5][5]int
    // Clean up rows for use in maths
    for row, i in board.rows {
        rowSplit := strings.split(row, " ", allocator)
        for numStr, j in rowSplit {
            num, _ := strconv.parse_int(numStr, 10)
            rows[i][j] = num
        }
    }
    // Calculate initial score from UNMARKED cells
    for row, i in rows {
        for cell, j in row {
            if !board.rowCalled[i][j] do score += cell
        }
    }
    return score * play
}

test :: proc(boardCheck : ^Board, boards : []^Board) -> bool {
    for board in boards {
        if board == boardCheck {
            return true
        }
    }
    return false
}
