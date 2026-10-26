"""Make portable HASM raster inputs from the two XYZ point clouds.

Only the Python standard library is used. Coordinates retain the CSV's
unspecified units. A deterministic 1,200-point subset fits the deliberately
coarse initial radial surface; HASM itself uses each complete original CSV.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import random
from pathlib import Path


NODATA = -9999


def read_points(path: Path) -> list[tuple[float, float, float]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None or not {"x", "y", "z"}.issubset(
            {field.strip().lower() for field in reader.fieldnames}
        ):
            raise ValueError(f"{path}: expected x,y,z headers")
        points = []
        for row in reader:
            point = (float(row["x"]), float(row["y"]), float(row["z"]))
            if not all(math.isfinite(value) for value in point):
                raise ValueError(f"{path}: nonfinite point")
            points.append(point)
    if len(points) < 20:
        raise ValueError(f"{path}: too few points")
    return points


def xy_axes(points: list[tuple[float, float, float]]) -> tuple[float, ...]:
    n = len(points)
    cx = sum(point[0] for point in points) / n
    cy = sum(point[1] for point in points) / n
    xx = sum((point[0] - cx) ** 2 for point in points) / n
    yy = sum((point[1] - cy) ** 2 for point in points) / n
    xy = sum((point[0] - cx) * (point[1] - cy) for point in points) / n
    angle = 0.5 * math.atan2(2 * xy, xx - yy)
    trace = xx + yy
    delta = math.hypot(xx - yy, 2 * xy)
    major = 2 * math.sqrt(max((trace + delta) / 2, 1e-12))
    minor = 2 * math.sqrt(max((trace - delta) / 2, 1e-12))
    return cx, cy, major, minor, angle


def radius(x: float, y: float, axes: tuple[float, ...]) -> float:
    cx, cy, major, minor, angle = axes
    dx, dy = x - cx, y - cy
    along = math.cos(angle) * dx + math.sin(angle) * dy
    across = -math.sin(angle) * dx + math.cos(angle) * dy
    return math.hypot(along / major, across / minor)


def solve_linear(a: list[list[float]], b: list[float]) -> list[float]:
    n = len(b)
    a = [row[:] + [b[i]] for i, row in enumerate(a)]
    for col in range(n):
        pivot = max(range(col, n), key=lambda row: abs(a[row][col]))
        a[col], a[pivot] = a[pivot], a[col]
        if abs(a[col][col]) < 1e-12:
            raise ValueError("Radial model fit is singular")
        divisor = a[col][col]
        for j in range(col, n + 1):
            a[col][j] /= divisor
        for row in range(n):
            if row == col:
                continue
            factor = a[row][col]
            for j in range(col, n + 1):
                a[row][j] -= factor * a[col][j]
    return [a[i][-1] for i in range(n)]


def fit_radial(points: list[tuple[float, float, float]],
               axes: tuple[float, ...], degree: int) -> tuple[list[float], float]:
    k = degree + 1
    normal = [[0.0] * k for _ in range(k)]
    right = [0.0] * k
    for x, y, z in points:
        r = radius(x, y, axes)
        basis = [r ** power for power in range(k)]
        for i in range(k):
            right[i] += basis[i] * z
            for j in range(k):
                normal[i][j] += basis[i] * basis[j]
    beta = solve_linear(normal, right)
    rss = sum((z - predict(x, y, axes, beta)) ** 2 for x, y, z in points)
    bic = len(points) * math.log(max(rss / len(points), 1e-18)) + k * math.log(len(points))
    return beta, bic


def predict(x: float, y: float, axes: tuple[float, ...],
            beta: list[float]) -> float:
    r = radius(x, y, axes)
    return max(0.0, sum(coefficient * r ** power
                        for power, coefficient in enumerate(beta)))


def convex_hull(points: list[tuple[float, float, float]]) -> list[tuple[float, float]]:
    xy = sorted({(point[0], point[1]) for point in points})
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower = []
    for point in xy:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    upper = []
    for point in reversed(xy):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    return lower[:-1] + upper[:-1]


def inside_hull(x: float, y: float, hull: list[tuple[float, float]]) -> bool:
    for i, (ax, ay) in enumerate(hull):
        bx, by = hull[(i + 1) % len(hull)]
        if (bx - ax) * (y - ay) - (by - ay) * (x - ax) < -1e-10:
            return False
    return True


def write_ascii(path: Path, values: list[list[float]],
                xll: float, yll: float, cell: float, mask: bool) -> None:
    nrows, ncols = len(values), len(values[0])
    with path.open("w", encoding="ascii", newline="\n") as handle:
        handle.write(f"ncols {ncols}\nnrows {nrows}\n")
        handle.write(f"xllcorner {xll:.10f}\nyllcorner {yll:.10f}\n")
        handle.write(f"cellsize {cell:.10f}\nNODATA_value {NODATA}\n")
        for row in values:
            if mask:
                handle.write(" ".join(str(int(value)) for value in row) + "\n")
            else:
                handle.write(" ".join(f"{value:.6f}" for value in row) + "\n")


def generate(source: Path, destination: Path, name: str,
             grid_size: int, train_count: int, validation_count: int) -> dict:
    path = source / f"{name}.csv"
    points = read_points(path)
    order = list(range(len(points)))
    random.Random(20261026 + sum(ord(char) for char in name)).shuffle(order)
    training = [points[index] for index in order[:train_count]]
    validation = [points[index] for index in order[train_count:train_count + validation_count]]
    if len(training) != train_count or len(validation) != validation_count:
        raise ValueError(f"{name}: not enough points for requested split")

    axes = xy_axes(training)
    candidate = {degree: fit_radial(training, axes, degree) for degree in (1, 2)}
    degree = min(candidate, key=lambda candidate_degree: candidate[candidate_degree][1])
    beta, _ = candidate[degree]
    hull = convex_hull(points)
    x_values = [point[0] for point in points]
    y_values = [point[1] for point in points]
    span = max(max(x_values) - min(x_values), max(y_values) - min(y_values))
    cell = math.ceil(span * 1.12 / grid_size * 100) / 100
    xll = (min(x_values) + max(x_values) - grid_size * cell) / 2
    yll = (min(y_values) + max(y_values) - grid_size * cell) / 2

    initial = []
    mask = []
    for row in range(grid_size):
        y = yll + (grid_size - row - 0.5) * cell
        initial_row = []
        mask_row = []
        for col in range(grid_size):
            x = xll + (col + 0.5) * cell
            initial_row.append(predict(x, y, axes, beta))
            mask_row.append(1 if inside_hull(x, y, hull) else NODATA)
        initial.append(initial_row)
        mask.append(mask_row)

    write_ascii(destination / f"{name}_initial.asc", initial, xll, yll, cell, False)
    write_ascii(destination / f"{name}_mask.asc", mask, xll, yll, cell, True)
    direct_rmse = math.sqrt(sum((z - predict(x, y, axes, beta)) ** 2
                                for x, y, z in validation) / len(validation))
    interior = lambda point: (xll + 1.5 * cell <= point[0] <= xll + (grid_size - 1.5) * cell
                              and yll + 1.5 * cell <= point[1] <= yll + (grid_size - 1.5) * cell)
    return {
        "source": path.name,
        "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "source_points": len(points),
        "training_points": len(training),
        "validation_points": len(validation),
        "source_extent": [min(x_values), min(y_values), max(x_values), max(y_values)],
        "source_z_range": [min(point[2] for point in points), max(point[2] for point in points)],
        "grid": {"ncols": grid_size, "nrows": grid_size, "xllcorner": xll,
                 "yllcorner": yll, "cellsize": cell, "nodata": NODATA},
        "hull_vertices": len(hull),
        "mask_valid_cells": sum(value == 1 for row in mask for value in row),
        "points_within_hasm_interior": sum(interior(point) for point in points),
        "radial_degree": degree,
        "radial_coefficients": beta,
        "radial_axes": {"center_x": axes[0], "center_y": axes[1],
                        "major_scale": axes[2], "minor_scale": axes[3],
                        "rotation_radians": axes[4]},
        "model_validation_rmse": direct_rmse,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    default_data = Path(__file__).resolve().parents[1] / "data"
    parser.add_argument("--source-dir", type=Path, default=default_data)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--grid-size", type=int, default=51)
    parser.add_argument("--train-count", type=int, default=1200)
    parser.add_argument("--validation-count", type=int, default=1200)
    args = parser.parse_args()
    if args.grid_size < 8:
        parser.error("grid-size must be at least 8")
    output_dir = args.output_dir or args.source_dir
    output_dir.mkdir(parents=True, exist_ok=True)
    summary = {}
    for name in ("tree", "shrup"):
        summary[name] = generate(args.source_dir, output_dir, name,
                                 args.grid_size, args.train_count, args.validation_count)
        print(f"{name}: {summary[name]['source_points']} points, "
              f"{summary[name]['grid']['ncols']}x{summary[name]['grid']['nrows']} grid, "
              f"cell={summary[name]['grid']['cellsize']:.2f} in source units, "
              f"radial degree={summary[name]['radial_degree']}, "
              f"model validation RMSE={summary[name]['model_validation_rmse']:.4f}")
    with (output_dir / "preparation_summary.json").open("w", encoding="utf-8") as handle:
        json.dump(summary, handle, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
