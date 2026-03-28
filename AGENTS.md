# Agents

## Code Style

Do not use abbreviations in variable names, function names, or comments. Always use full, descriptive names (e.g. `parameter` not `p`, `configuration` not `config`, `application` not `app`).

## Flutter Widgets

Never use `_build*` helper methods to construct UI subtrees. Extract them into separate widget classes instead. This improves readability, enables the framework to optimize rebuilds, and keeps widget trees explicit.

## Code Quality

Always run `dart analyze` after making changes. There must be zero issues (errors, warnings, or infos) in any code you write or modify. Run `dart fix --apply` first to auto-fix what it can, then resolve any remaining issues manually.

## Database

All DDL and schema changes must be written as migration files under `supabase/migrations/` (named `YYYYMMDDHHMMSS_description.sql`). Never apply DDL directly via `execute_sql` or the `apply_migration` MCP tool — always create a migration file first. Migrations are applied automatically by the CI/CD pipeline and should not be applied manually.

## Hardware Reference

The Plinky is a synthesizer. The firmware lives at https://github.com/ember-labs-io/Plinky_LPE and the docs/manual at https://plinkysynth.com/docs/manual — consult these for anything related to how the Plinky works (synth parameters, protocols, MIDI/USB communication, hardware capabilities, etc.).

For details on the UF2 format (memory map, sample encoding, presets, SampleInfo metadata), read `docs/uf2.md`.

The Plinky web player lives at https://github.com/plinkysynth/plinky-web — reference this for the player functionality we're building in PlinkyHub.

The wavetable generator lives at https://github.com/plinkysynth/wavetable — reference this for wavetable generation functionality.
