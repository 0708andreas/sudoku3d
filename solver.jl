import IterTools: chain
using Random
using Memoize

const vals = "1234"
const entries = 64
const dims = (4, 4, 4)

SudokuPuzzle = String

SudokuPartial = Vector{String}


squares = reshape(1:entries, dims...)
rows = [squares[i, j, :] for i in 1:4 for j in 1:4]
cols = [squares[i, :, j] for i in 1:4 for j in 1:4]
fils = [squares[:, i, j] for i in 1:4 for j in 1:4]

subs = vcat([vec(squares[2*i-1:2*i, 2*j-1:2*j, k]) for i in 1:2 for j in 1:2 for k in 1:4] ,
    [vec(squares[2*i-1:2*i, j, 2*k-1:2*k]) for i in 1:2 for j in 1:4 for k in 1:2] ,
    [vec(squares[i, 2*j-1:2*j, 2*k-1:2*k]) for i in 1:4 for j in 1:2 for k in 1:2] )
unitlist = collect(chain(rows, cols, fils, subs))

units = [filter(u -> s in u, unitlist) for s in squares]
peers = [Set(vcat(map(collect, units[s])...)) for s in squares]
for (i, p) in enumerate(peers)
    pop!(p, i)
end

function assign!(grid :: SudokuPartial, s :: Int64, d :: Char)
    others = replace(grid[s], d => "")
    for d2 in others
        eliminate!(grid, s, d2) || return false
    end
    return true
end

function eliminate!(grid :: SudokuPartial, s :: Int64, d :: Char)
    if ! (d ∈ grid[s])
        return true
    end
    grid[s] = replace(grid[s], d => "")

    propagate!(grid, s, d)
end

function propagate!(grid :: SudokuPartial, s :: Int64, d :: Char)
     if length(grid[s]) == 0
        return false
    elseif length(grid[s]) == 1
        for s2 in peers[s]
            eliminate!(grid, s2, grid[s][1]) || return false
        end
    end

    

    for u in units[s]
        dplaces = filter(s -> d ∈ grid[s], u)
        if length(dplaces) == 0
            return false
        elseif length(dplaces) == 1
            assign!(grid, dplaces[1], d) || return false
        end
    end
    return true
end

solutions = SudokuPuzzle[]

function search(grid, first=true)
    if first
        empty!(solutions)
    end
    if all(length(g) == 1 for g in grid)
        push!(solutions, join(grid))
        return
        # return [join(grid)]
    elseif any(length(g) == 0 for g in grid)
        return
        # return []
    end
    # if length([(length(grid[s]), s) for s in squares if length(grid[s]) > 1]) == 0
    #     println(collect(enumerate(grid)))
    #     println([(length(grid[s]), grid[s], s) for s in squares])
    # end
    
    # sols = SudokuPuzzle[]
    # n, s = findmin([length(p) for p in grid if length(p) > 1])
    n, s = min([(length(grid[s]), s) for s in squares if length(grid[s]) > 1]...)
    for d in grid[s]
        g = copy(grid)
        assign!(g, s, d)
        search(g, false)
        # append!(sols, search(g))
    end
    return solutions
end

function init_multi(puzzle :: SudokuPuzzle)
    return [s ∈ "0." ? vals : string(s) for s in puzzle]
end


function rand_puzzle(N)
    choices = rand(vals, N)
    idx = shuffle(1:entries)[1:N]
    return join([i ∈ idx ? pop!(choices) : "." for i in 1:entries])
end


