from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GENERATED = Path(r"C:\Users\Administrator\.codex\generated_images\01a0d21a-0f2c-7f20-9c19-c7299a112c85")
OUTPUT = ROOT / "assets" / "maps"
SIZE = (1280, 720)


def resize_map(source: Path, destination: Path) -> None:
    image = Image.open(source).convert("RGB")
    image.resize(SIZE, Image.Resampling.NEAREST).save(destination)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    resize_map(GENERATED / "exec-9875d643-93fd-4e50-8bbb-fb7fdd96db86.png", OUTPUT / "farm.png")
    resize_map(GENERATED / "exec-47d5571f-2f5a-48fc-808f-7bc0a28ac377.png", OUTPUT / "corn_house.png")
    resize_map(GENERATED / "exec-c3dbfefb-56f5-48a6-bf28-0ace792c4ce9.png", OUTPUT / "house_interior.png")

    atlas = Image.open(GENERATED / "exec-b6492081-9237-4057-a22e-dfb922135c78.png").convert("RGB")
    cells = [
        (10, 10, 547, 460),
        (567, 10, 1104, 460),
        (1124, 10, 1662, 460),
        (10, 480, 547, 931),
        (567, 480, 1104, 931),
        (1124, 480, 1662, 931),
    ]
    names = ["graveyard", "swamp", "chapel", "canyon", "hatchery", "mine"]
    for name, box in zip(names, cells):
        atlas.crop(box).resize(SIZE, Image.Resampling.NEAREST).save(OUTPUT / f"campaign_{name}.png")


if __name__ == "__main__":
    main()
