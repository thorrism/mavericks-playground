#!/usr/bin/env python3
"""Sanity-check every chapter map in scripts/chapters.gd without opening Godot.

Rectangular, one P, one X, every door has a button, monsters never in the start room,
and every toy / button / the exit can actually be reached (walking + jumping fences, drone
over low walls, doors opening once a button for them is reachable)."""
import re
import sys
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "scripts" / "chapters.gd"
WALL = "#"
BLOCKS_ALL = set("#SZ^t")          # nobody walks through these (tables: play it safe)
BLOCKS_ROBOT = BLOCKS_ALL | {"W"}   # the drone flies over low walls
NEIGHBOURS = [(1, 0), (-1, 0), (0, 1), (0, -1)]


def maps():
    text = SRC.read_text()
    names = re.findall(r'"name":\s*"([^"]+)"', text)
    blocks = re.findall(r'"map":\s*\[(.*?)\]', text, re.S)
    assert len(names) == len(blocks), "names/maps mismatch"
    for name, block in zip(names, blocks):
        yield name, re.findall(r'"([^"]*)"', block)


def flood(grid, starts, blocked, open_doors):
    rows, cols = len(grid), len(grid[0])
    seen = set(starts)
    stack = list(starts)
    while stack:
        r, c = stack.pop()
        for dr, dc in NEIGHBOURS:
            n = (r + dr, c + dc)
            if not (0 <= n[0] < rows and 0 <= n[1] < cols) or n in seen:
                continue
            ch = grid[n[0]][n[1]]
            if ch in blocked:
                continue
            if ch.isdigit() and ch not in open_doors:
                continue
            if ch == "X":
                seen.add(n)      # you can stand in the exit doorway but not walk on past it
                continue
            seen.add(n)
            stack.append(n)
    return seen


def rooms(grid):
    """Room id per floor cell; walls, low walls, doors and the exit split rooms (like kinder.gd)."""
    rows, cols = len(grid), len(grid[0])
    ids, next_id = {}, 0
    for r in range(rows):
        for c in range(cols):
            ch = grid[r][c]
            if (r, c) in ids or ch in "#WX" or ch.isdigit():
                continue
            stack = [(r, c)]
            ids[(r, c)] = next_id
            while stack:
                cr, cc = stack.pop()
                for dr, dc in NEIGHBOURS:
                    n = (cr + dr, cc + dc)
                    if not (0 <= n[0] < rows and 0 <= n[1] < cols) or n in ids:
                        continue
                    nch = grid[n[0]][n[1]]
                    if nch in "#WX" or nch.isdigit():
                        continue
                    ids[n] = next_id
                    stack.append(n)
            next_id += 1
    return ids


def check(name, grid):
    problems = []
    cols = len(grid[0])
    for i, row in enumerate(grid):
        if len(row) != cols:
            problems.append(f"row {i} is {len(row)} wide, expected {cols}: {row}")
    if problems:
        return problems
    cells = {}
    for r, row in enumerate(grid):
        for c, ch in enumerate(row):
            cells.setdefault(ch, []).append((r, c))
    if len(cells.get("P", [])) != 1:
        problems.append("need exactly one P")
    if len(cells.get("X", [])) != 1:
        problems.append("need exactly one X")
    for r, row in enumerate(grid):
        for c, ch in enumerate(row):
            if r in (0, len(grid) - 1) or c in (0, cols - 1):
                if ch not in "#X":
                    problems.append(f"({r},{c}) '{ch}' on the border - must be # or X")
    doors = {ch for ch in cells if ch.isdigit()}
    buttons = {ch for ch in cells if "a" <= ch <= "i"}
    for d in doors:
        if chr(ord("a") + int(d) - 1) not in buttons:
            problems.append(f"door {d} has no button")
    for b in buttons:
        if str(ord(b) - ord("a") + 1) not in doors:
            problems.append(f"button {b} has no door")
    if problems:
        return problems

    ids = rooms(grid)
    start = cells["P"][0]
    for m in cells.get("M", []) + cells.get("J", []) + cells.get("O", []):
        if ids.get(m) == ids.get(start):
            problems.append(f"monster at {m} shares the start room")

    # what can you reach? doors open once one of their buttons is reachable (robot or drone)
    open_doors = set()
    while True:
        robot = flood(grid, [start], BLOCKS_ROBOT, open_doors)
        drone = flood(grid, list(robot), BLOCKS_ALL, open_doors)
        newly = {str(ord(grid[r][c]) - ord("a") + 1) for (r, c) in drone if "a" <= grid[r][c] <= "i"} - open_doors
        if not newly:
            break
        open_doors |= newly
    for t in cells.get("T", []):
        if t not in robot:
            problems.append(f"toy at {t} can't be reached on foot")
    for d in doors - open_doors:
        problems.append(f"door {d}'s button can't be reached")
    if cells["X"][0] not in robot:
        problems.append("the exit can't be reached")
    for h in cells.get("H", []):
        if h not in robot:
            problems.append(f"cupboard at {h} can't be reached")
        backed = any(0 <= h[0] + dr < len(grid) and 0 <= h[1] + dc < cols and grid[h[0] + dr][h[1] + dc] == WALL
                     for dr, dc in NEIGHBOURS)
        if not backed:
            problems.append(f"cupboard at {h} has no wall behind it")
    for (r, c) in cells.get("P", []) + cells.get("T", []):
        if grid[r][c] == "T" and (r, c) in cells.get("W", []):
            problems.append("?")
    return problems


def main():
    bad = 0
    for i, (name, grid) in enumerate(maps()):
        problems = check(name, grid)
        toys = sum(row.count("T") for row in grid)
        monsters = sum(row.count(ch) for row in grid for ch in "MJO")
        doors = sorted({ch for row in grid for ch in row if ch.isdigit()})
        status = "ok " if not problems else "BAD"
        print(f"{status} chapter {i + 1} {name}: {len(grid[0])}x{len(grid)}, {toys} toys, {monsters} monsters, doors {''.join(doors)}")
        for p in problems:
            print("     -", p)
            bad += 1
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
