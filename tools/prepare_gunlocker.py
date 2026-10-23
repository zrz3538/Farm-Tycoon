from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\Administrator\Desktop\pictures\gunlocker")
OUTPUT = ROOT / "assets" / "house" / "gunlocker"
FRAME_SIZE = (192, 192)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    animation = Image.open(SOURCE)
    frames: list[Image.Image] = []
    durations: list[int] = []
    for index in range(animation.n_frames):
        animation.seek(index)
        frame = animation.convert("RGBA").resize(FRAME_SIZE, Image.Resampling.NEAREST)
        frame.save(OUTPUT / f"frame_{index:02d}.png")
        frames.append(frame)
        durations.append(int(animation.info.get("duration", 90)))

    contact = Image.new("RGBA", (FRAME_SIZE[0] * 6, FRAME_SIZE[1] * 3), (22, 24, 28, 255))
    for index, frame in enumerate(frames):
        contact.alpha_composite(frame, ((index % 6) * FRAME_SIZE[0], (index // 6) * FRAME_SIZE[1]))
        ImageDraw.Draw(contact).text(((index % 6) * FRAME_SIZE[0] + 5, (index // 6) * FRAME_SIZE[1] + 5), str(index), fill=(255, 220, 100, 255))
    contact.save(OUTPUT / "contact_sheet.png")
    (OUTPUT / "frame_count.txt").write_text(str(len(frames)), encoding="utf-8")


if __name__ == "__main__":
    main()
