from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT.parents[1] / "previews" / "parasite-skeletons-cartoon-pixel-v2.png"
OUTPUT = ROOT / "assets" / "enemies" / "parasite_skeletons"


def trim(image: Image.Image, threshold: int = 10, padding: int = 12) -> Image.Image:
    alpha = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
    box = alpha.getbbox()
    if box is None:
        raise RuntimeError("sprite crop contains no visible pixels")
    left, top, right, bottom = box
    return image.crop(
        (
            max(0, left - padding),
            max(0, top - padding),
            min(image.width, right + padding),
            min(image.height, bottom + padding),
        )
    )


def main() -> None:
    sheet = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)

    ranges = {
        "pig": (0, 800),
        "dog": (745, 1560),
        "human": (1535, sheet.width),
    }
    for name, (left, right) in ranges.items():
        sprite = sheet.crop((left, 0, right, sheet.height))
        # The generated presentation sheet lets a few tendrils cross column
        # boundaries. Clear only those foreign edge fragments before trimming.
        alpha = sprite.getchannel("A")
        cut = Image.new("L", sprite.size, 255)
        draw = ImageDraw.Draw(cut)
        if name == "pig":
            draw.polygon([(745, 0), (800, 0), (800, 340), (765, 365), (745, 320)], fill=0)
        elif name == "dog":
            draw.polygon([(0, 350), (45, 380), (45, 824), (0, 824)], fill=0)
            draw.polygon([(785, 0), (815, 0), (815, 350), (792, 330)], fill=0)
        else:
            draw.polygon([(0, 430), (42, 470), (42, 824), (0, 824)], fill=0)
        alpha = Image.composite(alpha, Image.new("L", sprite.size, 0), cut)
        sprite.putalpha(alpha)
        sprite = trim(sprite)
        sprite.save(OUTPUT / f"parasite_{name}.png")

    sheet.save(OUTPUT / "parasite_skeletons_source.png")


if __name__ == "__main__":
    main()
