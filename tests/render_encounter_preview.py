"""Check the captured journal layout before the native renderer draws it."""
import json
from pathlib import Path

rows = json.loads(Path("ui_encounter_native.json").read_text())
root = next(row for row in rows if row.get("name") == "ForeverCompanionDungeonJournal")
columns = [row for row in rows if row.get("parent") == root["id"] and row.get("height") == 302]
assert [row["width"] for row in columns] == [194, 222, 314]
for left, right in zip(columns, columns[1:]):
    assert left["points"][0][3] + left["width"] < right["points"][0][3]
for column, heading in zip(columns, ("Dungeons", "Bosses", "Drops")):
    children = [row for row in rows if row.get("parent") == column["id"]]
    assert any(row.get("text") == heading for row in children)
    for row in children:
        if row["kind"] == "Button" and row["visible"]:
            x, y = row["points"][0][3:]
            assert 0 <= x < x + row["width"] <= column["width"]
            assert 0 <= -y < -y + row["height"] <= column["height"]
assert any(row.get("text") == "Open boss loot" for row in rows)
print("PASS: dungeon, boss and drop columns fit the journal")
