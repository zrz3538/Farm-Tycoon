from __future__ import annotations

from pathlib import Path
from math import cos, sin, radians

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
OUT = ASSETS / "weapons" / "integrated"
FRAME = 128
WEAPON_FRAME = 256

WEAPONS = {
    "ar15": {"row": 0, "size": 82, "body": "player_rifle_grip_4x4.png"},
    "mp5": {"row": 1, "size": 68, "body": "player_rifle_grip_4x4.png"},
    "m1911": {"row": 2, "size": 54, "body": "player_pistol_grip_4x4.png"},
    "shotgun": {"row": 3, "size": 86, "body": "player_rifle_grip_4x4.png"},
}


def paste_centered(canvas: Image.Image, layer: Image.Image, center: tuple[float, float], angle: float) -> None:
    if angle:
        layer = layer.rotate(-angle, resample=Image.Resampling.NEAREST, expand=True)
    x = round(center[0] - layer.width / 2)
    y = round(center[1] - layer.height / 2)
    canvas.alpha_composite(layer, (x, y))


def fit_visible(image: Image.Image, target: int) -> Image.Image:
    box = image.getchannel("A").getbbox()
    if box is None:
        return Image.new("RGBA", (target, target), (0, 0, 0, 0))
    visible = image.crop(box)
    scale = min(target / visible.width, target / visible.height)
    size = (max(1, round(visible.width * scale)), max(1, round(visible.height * scale)))
    return visible.resize(size, Image.Resampling.NEAREST)


def draw_hand(draw: ImageDraw.ImageDraw, point: tuple[float, float]) -> None:
    x, y = point
    draw.rectangle((x - 4, y - 4, x + 4, y + 4), fill="#10234a")
    draw.rectangle((x - 2, y - 2, x + 2, y + 2), fill="#fff1b3")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    weapons = Image.open(ASSETS / "weapons" / "weapon_actions_clean_9x4.png").convert("RGBA")

    for weapon_id, cfg in WEAPONS.items():
        body_sheet = Image.open(ASSETS / cfg["body"]).convert("RGBA")
        output = Image.new("RGBA", (FRAME * 8, FRAME * 4), (0, 0, 0, 0))
        weapon_size = int(cfg["size"])

        for direction_row in range(4):
            for column in range(8):
                walking_column = column if column < 4 else (2 if column in (4, 5, 6) else 0)
                body = body_sheet.crop(
                    (
                        walking_column * FRAME,
                        direction_row * FRAME,
                        (walking_column + 1) * FRAME,
                        (direction_row + 1) * FRAME,
                    )
                )
                frame = body.copy()

                action = 0
                if column == 4:
                    action = 1
                elif column == 5:
                    action = 2
                elif column == 6:
                    action = 3

                points_left = direction_row == 1
                points_back = direction_row == 3
                source_column = 8 if points_back else ((4 + action) if points_left else action)
                source = fit_visible(weapons.crop(
                    (
                        source_column * WEAPON_FRAME,
                        int(cfg["row"]) * WEAPON_FRAME,
                        (source_column + 1) * WEAPON_FRAME,
                        (int(cfg["row"]) + 1) * WEAPON_FRAME,
                    )
                ), weapon_size)

                if points_back:
                    center = (64, 63)
                    angle = 0.0
                    forward = (0.0, -1.0)
                else:
                    angle = 0.0 if direction_row in (1, 2) else 90.0
                    center = (64, 66 if weapon_id != "m1911" else 62)
                    forward = {
                        0: (0.0, 1.0),
                        1: (-1.0, 0.0),
                        2: (1.0, 0.0),
                    }[direction_row]
                paste_centered(frame, source, center, angle)

                # Hands are rasterized into the same frame as the weapon and
                # muzzle flash. This keeps the grip locked during recoil.
                if not points_back:
                    drawer = ImageDraw.Draw(frame)
                    fx, fy = forward
                    grip = (center[0] - fx * 8, center[1] - fy * 8)
                    support_distance = 8 if weapon_id == "m1911" else 18
                    support = (center[0] + fx * support_distance, center[1] + fy * support_distance)
                    draw_hand(drawer, grip)
                    draw_hand(drawer, support)

                output.alpha_composite(frame, (column * FRAME, direction_row * FRAME))

        output.save(OUT / f"cowboy_{weapon_id}_8x4.png")


if __name__ == "__main__":
    main()
