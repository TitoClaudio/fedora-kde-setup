"""Read and write VS Code style JSON files (comments and trailing commas allowed)."""
import json


def _skip(text, i):
    """Index of the next character that isn't whitespace or a comment."""
    n = len(text)
    while i < n:
        if text[i].isspace():
            i += 1
        elif text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            i = n if j < 0 else j + 2
        else:
            break
    return i


def load_jsonc(path, default):
    if not path.is_file():
        return default
    text = path.read_text(encoding="utf-8-sig")
    out, i, n = [], 0, len(text)
    while i < n:
        j = _skip(text, i)
        if j > i:
            out.append(" ")
            i = j
            continue
        c = text[i]
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            out.append(text[i:j + 1])
            i = j + 1
        elif c == "," and (k := _skip(text, i + 1)) < n and text[k] in "}]":
            i += 1  # trailing comma
        else:
            out.append(c)
            i += 1
    clean = "".join(out).strip()
    return json.loads(clean) if clean else default


def write_json(path, data):
    path.write_text(json.dumps(data, indent=4, ensure_ascii=False) + "\n", encoding="utf-8")
