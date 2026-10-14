# Changelog

## THC AutoForage client update - 2026-10-14

- Added native AutoForage slash commands: `/autoforage`, `/startforage`,
  `/stopforage`, `/keepitem`, and `/destroyitem`.
- Synchronize the Forage hotbutton's red cooldown display with the server,
  including automatic attempts and restored login/zoning cooldowns.
- Tested in game with Brakk; no MacroQuest dependency.

## THC patch manifest refresh - 2026-09-26

- Regenerated the RoF patch manifest from the synchronized THC client payload.

## [1.0.4] 2023-02-11

- Introduced new CICD-friendly pipeline
- Added self updating support (yay)
- Added HTTPS support
- Fixed background threading and context cancellation, so it runs smoother (and cancels smoother)
- Added progress in the taskbar icon
- Added option to point to your self built hosting inside the CICD
- Added a pipeline that makes it easy to pull down upstream changes without impacting your version 
- Fix virustotal from falsely identifying as virus
