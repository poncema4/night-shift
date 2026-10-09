# The hotel: three floors

Pure data lives in `src/shared/Game/` (Hotel, Floors, Dressing, Building, Furnishing). The builder only turns that data into parts, and the tests prove the geometry: no two pieces overlap, every walking route has a floor under it and headroom over it, stairs are climbable, no furniture blocks a route or a task station.

| Level | Walking height | Rooms |
|---|---|---|
| Upstairs | y = 16 | Room 201-206, Mezzanine, Library, Grand Suite, Rooftop Spa |
| Ground | y = 0 | Kitchen, Boiler Room, Laundry, Storage, Security, Pantry, Lobby, Office, Ballroom, Pool Room |
| Basement | y = -16 | Wine Cellar, Furnace Room, Generator Room, Meat Locker, Dry Storage, Mop Closet, Parking Garage, Maintenance, Flooded Hall, Locker Room |

**Stairs.** The West stairwell (x -80..-60) climbs from the ground corridor to upstairs; the East stairwell (x 60..80) descends to the basement. Each is a switchback: flight, landing, flight, 1 stud per step. The floor above each flight has an opening with guard rails.

**Tasks (12).** Ground: breaker, minibar, linens, cameras, grand clock, pool chlorine. Upstairs: elevator panel, turn down the bed in Room 204, drain the rooftop spa. Basement: generator, steam valve, fuse box.

**The Night Manager** takes the shortest route through the whole hotel, stairs included. He hears someone on another floor from half as far, and he can only catch you within 6 studs of his own height.

Floor plans and stairwell cutaways are rendered from the real data (`art/renders/plan_*.png`, `stairs_*.png`) with `lune run scripts/export-layout` then `scripts/blender.sh art/blender/hotel_layout.py`.
