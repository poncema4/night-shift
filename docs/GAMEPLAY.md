# Gameplay systems

Rules live in `src/shared/Game` as pure modules with tests; the Roblox services only apply them.

| System | Rules (pure, tested) | Roblox glue |
|---|---|---|
| Sprint | `Stamina`: 4.5 s of running, then winded until recovered | `StealthService` sets WalkSpeed 16 / 24 |
| Flashlight | `Battery`: ~45 s of light, slow recharge, dead until 8 % | `StealthService` owns a SpotLight on the head |
| Hiding | `Stealth.search`: he must linger ~1.5 s within 5 studs | lockers + wardrobes get a Hide prompt; hidden players are invisible and frozen |
| Noise | `Stealth.hearingRange`: sprint x1.5, light x1.25, still x0.4, hidden 0 | `ThreatService` uses it to pick who to hunt |
| Scares | `Scares`: schedule gets busier through the night; blackouts only after 25 % and a minute apart | `ScareDirector` plays them; `Fx` shakes, flickers, subtitles |

Controls: **Shift** run (hold), **F** flashlight, **E** interact / leave a hiding place. On phones the same actions are touch buttons (RUN, LIGHT) plus an on-screen LEAVE button while hiding.

Everything the client sends is a *wish* (`Intent`: sprint / light / leave). The server rate-limits it, validates the types and decides what really happens.
