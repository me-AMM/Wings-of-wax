# Collision decisions (every textured object)

Footprints are computed from the sprite alpha by `tools/footprints.py` (bottom 20-30% of the opaque box, inset 4-8% per side;
ellipse for round buildings) and written as real `StaticBody2D "Footprint"` + `CollisionPolygon2D "Shape"` nodes by
`tools/make_outpost.py`. Origin of every building/prop = bottom centre of its sprite. Player = CharacterBody2D, circle r=5 at the feet.
Press F3 in the Outpost or a mission to see footprints (red), slow zones (cyan) and interaction radii (yellow).

| Object (scene) | Decision | Notes |
|---|---|---|
| habitat (Outpost) | SOLID | ellipse |
| greenhouse (Outpost) | SOLID | ellipse; one unit with the tray; shares one lock label |
| radish tray (Outpost) | SOLID | low box in front of the greenhouse door; same E action as the greenhouse |
| water_recycler (Outpost) | SOLID | ellipse |
| science_lab (Outpost) | SOLID | rect |
| forecast_board (Outpost) | SOLID | rect |
| shelter (Outpost, Mission) | SOLID | ellipse |
| solar panel groups x4 (Outpost) | SOLID | thin strip along the base |
| slider_console, charger (Outpost) | SOLID | rect |
| antenna (Outpost) | SOLID | thin rect |
| cargo_lander, landed (Outpost) | SOLID | enabled only once landed (day 4 07:00) |
| crew_lander (Outpost) | SOLID | enabled only on day 32 |
| rocks_2 (Outpost, "big rocks") | SOLID | rect footprint |
| boulder_wall + world limits (Outpost, Mission) | SOLID | invisible solid walls (WorldWalls) around the map |
| landing_pad (Outpost) | TRIGGER (walkable) | flat; the player walks onto it |
| cargo_crate (Outpost) | DECORATION | not solid |
| rocks_1 (Outpost) | DECORATION | not solid |
| crater_small x3 (Outpost) | DECORATION | walkable, no collision |
| ground_1..3, path (Outpost, Mission) | DECORATION | tiles |
| crater_large x2 (Mission) | SLOW ZONE | Area2D polygon of the crater floor from the sprite alpha, inset from the rim; slower walk and 1.25x suit drain; no collision on the rim |
| ground_dark (Mission) | DECORATION | drawn under the crater |
| sample_spot, ice_deposit, rare_stone, waypoint_flag (Mission) | TRIGGER | distance checks, not solid |
| dust_puff, sparkle, storm_specks, lander touchdown animation | DECORATION | effects |
| icons, UI | DECORATION | screen space |
