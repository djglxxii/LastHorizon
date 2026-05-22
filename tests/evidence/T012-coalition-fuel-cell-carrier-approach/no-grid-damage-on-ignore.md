# No Grid Damage On Ignore

The traversal still sequence shows an uncollected fuel-cell carrier launching, descending, and exiting through the bottom.

`event-log.txt` records:

```text
fuel_cell_carrier_exited queued=true
fuel_cell_exit_grid 100.0 -> 100.0, grid_damage_events=0
```

This confirms ignored fuel-cell carriers are opportunity-cost-only pickups and do not use the enemy leak-damage path.
