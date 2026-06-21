# Modular Chests Continued

Modular Chests Continued is the maintained successor to
[Modular Chests](https://mods.factorio.com/mod/LB-Modular-Chests). Place iron
or steel modular chests next to one another and they merge into long storage
chests designed for train loading and unloading.

## Project history

Lord Binary (`krisgreg`) created Modular Chests for Factorio 0.16 in 2018.
Community contributions expanded the available chest lengths, and later
releases added multi-surface support, steel chests, construction-robot merge
handling, and compatibility with Factorio 0.17, 0.18, 1.1, and 2.0. The
Factorio 2.0 port through version 2.0.13 was published by `aaVenger`.

This repository carries that release history forward and continues development
as a new Factorio mod beginning with version 2.0.14. The original work and
this continuation are distributed under the MIT License.

## Migrating from LB-Modular-Chests

The continuation keeps the original prototype names, so existing saves and
blueprints remain compatible:

1. Back up the save.
2. Disable or remove `LB-Modular-Chests`.
3. Install and enable `modular-chests-continued`.
4. Load the save and confirm the mod replacement when Factorio prompts.

The two mods cannot be enabled together because they define the same
prototypes.

## Blueprint and robot support

Merged chest blueprints can be built by construction robots. A merged ghost
requests the appropriate number of ordinary modular iron or steel chest items,
so no unobtainable merged-chest item is required.

## Credits

- Lord Binary (`krisgreg`) — original author
- Gaddhi — additional chest lengths
- DraLUSAD — force-preservation bug report
- `aaVenger` — later maintenance and Factorio 2.0 port
- `jave27` — continuation maintenance and blueprint construction fix
