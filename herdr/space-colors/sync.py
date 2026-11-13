import json
import os
import subprocess

HERDR = os.environ.get("HERDR_BIN_PATH", "herdr")
SOURCE = "space-colors"
TEAMS_MARKER = "/dev/teams/"
GROUPS = {
    "eu1": "g_eu1",
    "eu2": "g_eu2",
    "nordic": "g_nordic",
    "core": "g_core",
    "infra": "g_infra",
    "asset-finance": "g_asset_finance",
}
FALLBACK = "g_other"
ALL_TOKENS = set(GROUPS.values()) | {FALLBACK}


def query(*args):
    out = subprocess.run([HERDR, *args], capture_output=True, text=True, check=True).stdout
    return json.loads(out)["result"]


def run(*args):
    subprocess.run([HERDR, *args], capture_output=True, check=True)


def team_of(path):
    if TEAMS_MARKER not in path:
        return None
    return path.split(TEAMS_MARKER, 1)[1].split("/", 1)[0]


def group_token(panes):
    for pane in panes:
        team = team_of(pane.get("cwd") or "")
        if team:
            return GROUPS.get(team, FALLBACK)
    return FALLBACK


def main():
    workspaces = query("workspace", "list")["workspaces"]
    panes_by_workspace = {}
    for pane in query("pane", "list")["panes"]:
        panes_by_workspace.setdefault(pane["workspace_id"], []).append(pane)

    for workspace in workspaces:
        workspace_id = workspace["workspace_id"]
        label = workspace["label"]
        wanted = group_token(panes_by_workspace.get(workspace_id, []))
        current = {k: v for k, v in (workspace.get("tokens") or {}).items() if k in ALL_TOKENS}
        if current == {wanted: label}:
            continue
        args = ["workspace", "report-metadata", workspace_id, "--source", SOURCE, "--token", f"{wanted}={label}"]
        for stale in ALL_TOKENS - {wanted}:
            if stale in current:
                args += ["--clear-token", stale]
        run(*args)


main()
