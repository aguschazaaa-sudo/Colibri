"""
clean_lottie.py — Elimina marcas de agua de Lotties exportados desde Lottielab.

Estrategia:
  - Capas con ind=12345679 o nombre como "Group Layer 8" en esquina inferior derecha
    → SE ELIMINAN (son la capa visual de la marca de agua)
  - Capas con nombre "lottielab.com" de tipo null (ty=3)
    → SE OCULTAN (hd=true + opacidad 0) porque otras capas pueden tenerlas como parent

Uso:
    python clean_lottie.py archivo.json
    python clean_lottie.py *.json          # todos los archivos de la carpeta
    python clean_lottie.py archivo.json --dry-run   # solo muestra qué haría
"""

import json
import sys
import glob
from pathlib import Path

WATERMARK_HIGH_IND = 12345679       # ID inusualmente alto que usa Lottielab
WATERMARK_NULL_NAMES = {"lottielab.com", "lottiefiles.com"}  # null controllers a ocultar


def classify_layer(layer: dict, canvas_w: int, canvas_h: int):
    """
    Retorna:
      'remove' — capa visual de marca de agua, eliminar
      'hide'   — null controller de marca de agua, ocultar pero mantener
      None     — capa legítima, no tocar
    """
    nm = (layer.get("nm") or "").lower()
    ind = layer.get("ind", 0)

    # Null controller conocido (ty=3): ocultar para no romper parents
    if nm in WATERMARK_NULL_NAMES:
        return "hide"

    # ID altísimo → siempre eliminar
    if ind == WATERMARK_HIGH_IND:
        return "remove"

    # Capa en esquina inferior derecha con nombre sospechoso → eliminar
    p = layer.get("ks", {}).get("p", {}).get("k")
    if isinstance(p, list) and len(p) >= 2 and isinstance(p[0], (int, float)):
        x, y = p[0], p[1]
        if x > canvas_w * 0.7 and y > canvas_h * 0.7:
            if nm in ("group layer 8", "watermark", "logo") or ind > 1000:
                return "remove"

    return None


def clean_file(path: Path, dry_run: bool = False) -> None:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    canvas_w = data.get("w", 0)
    canvas_h = data.get("h", 0)

    new_layers = []
    any_change = False

    for layer in data.get("layers", []):
        action = classify_layer(layer, canvas_w, canvas_h)

        if action == "remove":
            print(f"  REMOVIDO: nm={repr(layer.get('nm'))} ind={layer.get('ind')}")
            any_change = True

        elif action == "hide":
            print(f"  OCULTO:   nm={repr(layer.get('nm'))} ind={layer.get('ind')} (null controller, se mantiene como parent)")
            if not dry_run:
                layer["hd"] = True
                layer["ks"]["o"] = {"a": 0, "k": 0}
            new_layers.append(layer)
            any_change = True

        else:
            new_layers.append(layer)

    if not any_change:
        print(f"[{path.name}] Sin marcas de agua detectadas.")
        return

    if dry_run:
        print(f"[{path.name}] (dry-run: no se escribió nada)")
        return

    data["layers"] = new_layers
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, separators=(",", ":"))
    print(f"[{path.name}] Guardado. Capas restantes: {len(new_layers)}")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry_run = "--dry-run" in sys.argv

    if not args:
        print("Uso: python clean_lottie.py archivo.json [--dry-run]")
        sys.exit(1)

    files = []
    for pattern in args:
        matched = glob.glob(pattern)
        files.extend(matched if matched else [pattern])

    for f in files:
        path = Path(f)
        if not path.exists():
            print(f"[{path.name}] No encontrado, saltando.")
            continue
        if path.suffix.lower() != ".json":
            print(f"[{path.name}] No es .json, saltando.")
            continue
        clean_file(path, dry_run=dry_run)


if __name__ == "__main__":
    main()
