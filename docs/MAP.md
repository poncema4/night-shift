# The hotel: three floors

Pure data lives in `src/shared/Game/` (Hotel, Floors, Dressing, Building, Furnishing). The builder only turns that data into parts, and the tests prove the geometry: no two pieces overlap, every walking route has a floor under it and headroom over it, stairs are climbable, no furniture blocks a route or a task station.

| Level | Walking height | Rooms |
|---|---|---|
| Upstairs | y = 16 | Room 201-206, Mezzanine, Library, Grand Suite, Rooftop Spa |
| Ground | y = 0 | Kitchen, Boiler Room, Laundry, Storage, Security, Pantry, Lobby, Office, Ballroom, Pool Room |
| Basement | y = -16 | Wine Cellar, Furnace Room, Generator Room, Meat Locker, Dry Storage, Mop Closet, Parking Garage, Maintenance, Flooded Hall, Locker Room |

**Stairs.** Both stairwells are square spirals around an open 8x8 well (West x -76..-60 climbs ground to upstairs; East x 60..76 descends to the basement). Three flights of five 1-stud steps with a landing at each corner; you can look down the well. The floor above has an opening with guard rails. **Basement dressing:** rusted pipe runs overhead and green sludge pools in the damp rooms, under the darker, greener basement lights.

**Tasks (12).** Ground: breaker, minibar, linens, cameras, grand clock, pool chlorine. Upstairs: elevator panel, turn down the bed in Room 204, drain the rooftop spa. Basement: generator, steam valve, fuse box.

**The Night Manager** takes the shortest route through the whole hotel, stairs included. He hears someone on another floor from half as far, and he can only catch you within 6 studs of his own height.

Floor plans and stairwell cutaways are rendered from the real data (`art/renders/plan_*.png`, `stairs_*.png`) with `lune run scripts/export-layout` then `scripts/blender.sh art/blender/hotel_layout.py`.

## v0.7: the wider hotel
- The corridor is now x -80..80 (was -60..60): four new rooms per floor, two at each end. West/East stairwells moved out to x -96..-80 and 80..96.
- Ground: Cloakroom, Chapel (north), Gift Shop, Billiards (south). Upstairs: Room 207, Room 208, Gallery, Observatory. Basement (sewer wing): Sewer Junction, Drain Room, Crypt, Cistern.
- Three new tasks (15 total): sort the lost coats (Cloakroom), light the chapel candles (Chapel), rack the billiard balls (Billiards).
- Co-op needs only a share of the tasks (`TaskBoard.target`): 1 player 62%, 2 players 75%, 3 players 88%, 4+ all of them.
