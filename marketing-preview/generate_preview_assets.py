from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path("/Users/user/Desktop/BB counter/marketing-preview")
RAW_DIR = ROOT / "raw" / "check-scenarios"
OUT_DIR = ROOT / "final"

WIDTH = 1320
HEIGHT = 2868

ZH_FONT = "/System/Library/Fonts/STHeiti Medium.ttc"


SCENARIOS = [
    {
        "slug": "01-chips",
        "source": "chips.png",
        "headline": "快速記錄籌碼",
        "subtitle": "面額按鈕直接累加，不用心算。",
        "headline_size": 152,
        "main_y": 660,
        "colors": ((28, 27, 33), (61, 36, 54), (242, 111, 170), (255, 198, 75)),
    },
    {
        "slug": "02-blinds",
        "source": "blinds.png",
        "headline": "一鍵設定盲注",
        "subtitle": "只問大盲，預設等級滑一下就好。",
        "headline_size": 152,
        "main_y": 664,
        "colors": ((26, 28, 39), (32, 47, 86), (104, 155, 255), (188, 219, 255)),
    },
    {
        "slug": "03-result",
        "source": "result.png",
        "headline": "升盲後還剩幾 BB",
        "subtitle": "記一手輸贏，深度與倒數同時更新。",
        "headline_size": 126,
        "main_y": 752,
        "colors": ((16, 27, 23), (21, 55, 44), (110, 218, 137), (255, 214, 95)),
    },
    {
        "slug": "04-handline",
        "source": "handline.png",
        "headline": "照規則記下這手牌",
        "subtitle": "3-Bet、4-Bet 尺寸自動換算成 bb。",
        "headline_size": 126,
        "main_y": 752,
        "colors": ((20, 20, 32), (46, 34, 74), (152, 128, 255), (255, 188, 232)),
    },
]


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def add_vertical_gradient(base: Image.Image, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> None:
    px = base.load()
    for y in range(HEIGHT):
        t = y / (HEIGHT - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(WIDTH):
            px[x, y] = color


def add_blobs(base: Image.Image, colors: tuple[tuple[int, int, int], ...]) -> Image.Image:
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    accent_a, accent_b = colors[2], colors[3]
    draw.ellipse((-140, 1480, 920, 3080), fill=accent_a + (62,))
    draw.ellipse((620, -120, 1520, 980), fill=accent_b + (48,))
    draw.ellipse((840, 1450, 1480, 2500), fill=accent_b + (35,))
    return Image.alpha_composite(base.convert("RGBA"), overlay).filter(ImageFilter.GaussianBlur(42))


def wrap_text(draw: ImageDraw.ImageDraw, text: str, text_font: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = list(text)
    lines: list[str] = []
    current = ""
    for ch in words:
        trial = current + ch
        if draw.textbbox((0, 0), trial, font=text_font)[2] <= max_width or not current:
            current = trial
        else:
            lines.append(current)
            current = ch
    if current:
        lines.append(current)
    return lines


def add_shadow(card: Image.Image, radius: int = 32, offset: tuple[int, int] = (0, 24), alpha: int = 115) -> Image.Image:
    shadow = Image.new("RGBA", (card.width + radius * 4, card.height + radius * 4), (0, 0, 0, 0))
    mask = rounded_mask(card.size, 72)
    shadow_mask = Image.new("L", shadow.size, 0)
    shadow_mask.paste(mask, (radius * 2 + offset[0], radius * 2 + offset[1]))
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(radius))
    shadow.paste((0, 0, 0, alpha), (0, 0), shadow_mask)
    shadow.paste(card, (radius * 2, radius * 2), card)
    return shadow


def build_card(source: Image.Image, width: int, crop_box: tuple[int, int, int, int] | None = None) -> Image.Image:
    image = source.crop(crop_box) if crop_box else source
    ratio = width / image.width
    resized = image.resize((width, int(image.height * ratio)), Image.Resampling.LANCZOS).convert("RGBA")
    mask = rounded_mask(resized.size, 74)
    card = Image.new("RGBA", resized.size, (0, 0, 0, 0))
    card.paste(resized, (0, 0), mask)

    border = Image.new("RGBA", resized.size, (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border)
    border_draw.rounded_rectangle(
        (2, 2, resized.width - 2, resized.height - 2),
        radius=74,
        outline=(255, 255, 255, 42),
        width=3,
    )
    card = Image.alpha_composite(card, border)
    return add_shadow(card)


def add_title_block(canvas: Image.Image, scenario: dict) -> None:
    draw = ImageDraw.Draw(canvas)
    headline_size = scenario.get("headline_size", 152)
    headline_font = font(ZH_FONT, headline_size)
    subtitle_font = font(ZH_FONT, 54)

    x = 106
    line_height = int(headline_size * 1.05)
    lines = wrap_text(draw, scenario["headline"], headline_font, 1050)

    # 沒有圖示與角標後上方會空一大塊，把文字塊往下靠、離手機上緣留一段固定的呼吸空間。
    block_height = line_height * len(lines) + 90
    phone_top = scenario.get("main_y", 660) + 64
    text_y = max(200, phone_top - block_height - 120)

    for line in lines:
        draw.text((x, text_y), line, font=headline_font, fill=(247, 247, 250))
        text_y += line_height

    draw.text((x, text_y + 10), scenario["subtitle"], font=subtitle_font, fill=(232, 233, 239, 180))


def create_preview(scenario: dict) -> None:
    base = Image.new("RGB", (WIDTH, HEIGHT))
    add_vertical_gradient(base, scenario["colors"][0], scenario["colors"][1])
    canvas = add_blobs(base, scenario["colors"]).convert("RGBA")

    add_title_block(canvas, scenario)

    source = Image.open(RAW_DIR / scenario["source"]).convert("RGBA")
    main_card = build_card(source, width=932)
    main_x = (WIDTH - main_card.width) // 2
    main_y = scenario.get("main_y", 660)
    canvas.alpha_composite(main_card, (main_x, main_y))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT_DIR / f"{scenario['slug']}.png")


def main() -> None:
    for scenario in SCENARIOS:
        create_preview(scenario)


if __name__ == "__main__":
    main()
