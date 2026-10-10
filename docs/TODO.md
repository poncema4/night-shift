# Master list: everything to be fully happy with the game and its popularity

Legend: [x] done and merged, [~] built, needs your eyes in Studio, [ ] to do, [YOU] only you can do it.

## 0. Rule: the studio (group) logo appears ONLY on the group icon. Never on game thumbnails, banners, the icon or in-game screens.

## 1. Make sure it works (this week)
- [YOU] Run `docs/PLAYTEST.md` in Studio and send screenshots (spiral stairs, lockers, holding cell countdown, flashlight in hotbar, darkness, lobby menu).
- [YOU] Publish the place, then test a party teleport with two accounts (Studio cannot teleport). See `docs/LOBBY.md`.
- [YOU] Enable Studio API access (Game Settings > Security) so saving can be tested.
- [~] Lobby, parties, 30 s / 5 s queue, per-party servers, loading screens.
- [~] One-tap lockers with a view out; Night Manager starts caged with a countdown; flashlight hotbar item; darker hotel; wider map (+4 rooms per floor, sewer wing).
- [ ] Tune after the first playtest: darkness, jail time (30 s), escalation (1.4x), hotel size.

## 2. Look and sound (what makes clips and thumbnails)
- [YOU] Import the Blender FBX models (`docs/ART.md`) so props look hand-made, not boxes.
- [~] Lobby pods, flickering lobby, return-to-lobby, animated cage (bars rise, lamp pulses). See `docs/LOBBY.md`.
- [ ] Real sound (full plan in `docs/AUDIO.md`): replace the placeholder ids in `Config.Sounds` (heartbeat, his footsteps, the cage alarm, locker creak, lights buzz). Sound sells horror more than anything.
- [~] Store art generated from real renders with the group logo unchanged: `brand/store_icon_512.png`, `brand/store_thumb_corridor.png`, `brand/store_thumb_face.png` (re-run `python3 brand/make_store_art.py`). UPLOADED 2026-10-09 to the experience (icon + 2 home-page thumbnails, active, pending Roblox moderation). Still wanted: a spiral-well and a sewer render, and a gameplay video.
- [ ] A 30 s trailer clip captured from a real match (this is also your first TikTok).

## 3. Store page (Creator Hub, before publishing)
- DONE in Creator Hub (2026-10-09): name `THE NIGHT MANAGER 🛎️ [HORROR]` and the description. Not changed by Claude: visibility (check it before you share the link), genre, max players (8).
- Description: lead with the hook ("He hears everything. Run, hide, vote."), keywords: horror, hotel, multiplayer, co-op, survive, sewer, stealth.
- [YOU] Accurate thumbnails only (Roblox penalises misleading ones). Fill group, social links, enable private servers, enable "Allow copying" off.

## 4. Growth loop (Roblox discovery signals)
- First 60 s decides bounce: the lobby already shows a menu and a queue; make sure a first-timer is in a match in under 90 s (Quick Play).
- Play-through and session length: nights are about 4 minutes; keep one more reason to queue again (XP, cosmetics, streaks are built).
- Co-play: parties of any size, Quick Play, invite friends (add Roblox invite prompt next).
- [ ] Daily reward / login streak, a weekly event night, a limited cosmetic each month.
- [ ] Group: pin the game, post update notes, run a group event, collect members before launch.

## 5. TikTok loop
- Hook moments that exist in the game: he is caged with a visible countdown; "HE IS LOOSE"; he gets faster as tasks finish; the flashlight blinds him; hiding in a locker while he searches.
- Post formula from the live feed: 1 monster + 1 hook line, 3 to 5 tags (#roblox #robloxhorror #nightmanager #scary #fyp), reaction caption, 15 to 30 s.
- [YOU] TikTok bio still shows the old game name (the save kept being rejected). Set: `Roblox horror THE NIGHT MANAGER. Join us: roblox.com/communities/749648777`.
- [ ] Add a record-friendly mode: hide HUD, "clip moment" camera shake on near misses.

- [YOU] Voice chat: turn it on in Creator Hub (see `docs/AUDIO.md`).

## 6. Money (cosmetic only)
- [~] Shop, Starlight pass, tips packs. [YOU] create the pass and products in Creator Hub and paste the ids (`docs/MONETIZATION.md`).
- [ ] Seasonal cosmetics, subscription, private servers.

## 7. Content depth (keeps players)
- [ ] More saboteur abilities, a second Night Manager variant, hotel events (blackout waves, flooded basement), a second map.
- [ ] Spectator chat, emotes, end-of-night awards, a leaderboard.
- [ ] Options saved to the profile; cross-server Quick Play (MemoryStore) so small parties across lobby servers can merge.

## 8. Housekeeping
- [YOU] Delete the `poncema4/night-shift-logs` GitHub repo (`gh auth refresh -h github.com -s delete_repo`), close the old PowerShell `scripts/logs` window, delete its folder.
- [YOU] Open Cloud publish key if you want publishing from CI.
- [YOU] Group cover photo is pending Roblox review.
- Pair Extraordinaire: tracked in `docs/PAIR_TRACKER.md`.
