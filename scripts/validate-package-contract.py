#!/usr/bin/env python3
import json
import subprocess
from pathlib import Path


repository_root = Path(__file__).resolve().parent.parent
manifest = json.loads(
    subprocess.run(
        ["swift", "package", "dump-package"],
        cwd=repository_root,
        check=True,
        capture_output=True,
        text=True,
    ).stdout
)

expected_platforms = {
    "macos": "14.0",
    "ios": "17.0",
    "tvos": "17.0",
}
actual_platforms = {
    platform["platformName"]: platform["version"]
    for platform in manifest["platforms"]
}
if actual_platforms != expected_platforms:
    raise SystemExit(
        f"Package platform minimums changed: {actual_platforms!r} != {expected_platforms!r}"
    )

if manifest["toolsVersion"]["_version"] != "6.0.0":
    raise SystemExit("Package must continue using Swift tools 6.0.")

products = {product["name"]: product for product in manifest["products"]}
expected_products = {
    "Sabella": ["Sabella"],
    "SabellaCatalog": ["SabellaCatalog"],
    "SabellaShellExamples": ["SabellaShellExamples"],
}
for name, expected_targets in expected_products.items():
    product = products.get(name)
    if product is None or product["targets"] != expected_targets:
        raise SystemExit(
            f"Package product {name!r} must contain only {expected_targets!r}."
        )

targets = {target["name"]: target for target in manifest["targets"]}
expected_sabella_dependencies = {
    ("product", "KSPlayer", "KSPlayer", ("tvos",)),
    ("target", "SabellaKSPlayerWorkaround", None, ("tvos",)),
}
actual_sabella_dependencies = set()
for dependency in targets["Sabella"]["dependencies"]:
    if "product" in dependency:
        name, package, _, condition = dependency["product"]
        actual_sabella_dependencies.add(
            (
                "product",
                name,
                package,
                tuple(condition.get("platformNames", [])),
            )
        )
    elif "target" in dependency:
        name, condition = dependency["target"]
        actual_sabella_dependencies.add(
            (
                "target",
                name,
                None,
                tuple(condition.get("platformNames", [])),
            )
        )
    else:
        raise SystemExit(f"Unexpected Sabella dependency: {dependency!r}")

if actual_sabella_dependencies != expected_sabella_dependencies:
    raise SystemExit(
        "Sabella dependencies changed: "
        f"{actual_sabella_dependencies!r} != {expected_sabella_dependencies!r}"
    )

print("Package product, platform, and dependency contract passed.")
