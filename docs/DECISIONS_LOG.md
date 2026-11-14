# Decisions log (builder: one line per choice you made where a doc was ambiguous or an asset was missing)

- M0: export preset excludes docs/ and tools/ from the pck; thread support off (itch.io friendly); screens use `.tscn` text files written by hand.
- docs/ has a .gdignore so Godot does not import the docs CSV as a translation.
