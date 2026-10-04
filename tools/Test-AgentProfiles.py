"""Validate the project's minimal Codex profiles without invoking agents or the game."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import tomllib


EXPECTED = {
    "cc_gameplay": True,
    "cc_art": True,
    "cc_narrative": True,
    "cc_engineering": False,
    "cc_qa": True,
}
FIELDS = {"name", "description", "developer_instructions", "sandbox_mode"}


def validate_profile(data: dict, name: str) -> None:
    if name not in EXPECTED or data.get("name") != name:
        raise ValueError(f"{name}: identity does not match the five project roles")
    if set(data) - FIELDS:
        raise ValueError(f"{name}: field outside this minimal project schema")
    for field in ("name", "description", "developer_instructions"):
        if not isinstance(data.get(field), str) or not data[field].strip():
            raise ValueError(f"{name}: missing/non-text {field}")
    if EXPECTED[name]:
        if data.get("sandbox_mode") != "read-only":
            raise ValueError(f"{name}: reviewer must declare read-only")
    elif "sandbox_mode" in data:
        raise ValueError(f"{name}: engineering must inherit the session sandbox")


def self_test() -> None:
    valid = {
        "name": "cc_art",
        "description": "Review visual references.",
        "developer_instructions": "Read the assigned references; do not edit.",
        "sandbox_mode": "read-only",
    }
    validate_profile(valid, "cc_art")
    probes = [
        {**valid, "name": "cc_qa"},
        {key: value for key, value in valid.items() if key != "developer_instructions"},
        {**valid, "description": 123},
        {**valid, "sandbox_mode": "workspace-write"},
        {**valid, "model": "unexpected-project-override"},
    ]
    for index, probe in enumerate(probes, 1):
        try:
            validate_profile(probe, "cc_art")
        except ValueError:
            continue
        raise AssertionError(f"invalid profile probe {index} was accepted")
    try:
        tomllib.loads('name = "unfinished')
    except tomllib.TOMLDecodeError:
        pass
    else:
        raise AssertionError("malformed TOML was accepted")
    print("AgentProfiles: PASS - six invalid schema/TOML probes rejected")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    paths = sorted((root / ".codex" / "agents").glob("*.toml"))
    if {path.stem for path in paths} != set(EXPECTED):
        raise ValueError("expected exactly the five project profiles")
    for path in paths:
        with path.open("rb") as stream:
            validate_profile(tomllib.load(stream), path.stem)
    team = root / "docs" / "AGENT_TEAM.md"
    text = team.read_text(encoding="utf-8")
    for name in set(re.findall(r"\b[A-Z][A-Z0-9_]*\.md\b", text)):
        source = root / name if name == "AGENTS.md" else root / "docs" / name
        if not source.is_file():
            raise ValueError(f"team routing source missing: {name}")
    for name in EXPECTED:
        if name not in text:
            raise ValueError(f"team routing does not describe {name}")
    print("AgentProfiles: PASS - five TOML profiles and local routing sources")
    if args.self_test:
        self_test()
    print("Limits: no native discovery, sandbox enforcement or agent judgment verified.")


if __name__ == "__main__":
    main()
