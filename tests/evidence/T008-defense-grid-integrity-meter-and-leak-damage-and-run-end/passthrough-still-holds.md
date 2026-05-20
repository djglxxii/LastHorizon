# Passthrough Still Holds

T008 does not add player/enemy body collision response.

The only new Grid debit path is baseline enemy leak detection at `planet_line_y`. The player ship still has no collision handler for enemy bodies, and enemies passing through the ship area do not stop, bounce, drain typed-weapon energy, damage the Grid by collision, or trigger invulnerability.

Collision interception remains M6 / T015 scope.
