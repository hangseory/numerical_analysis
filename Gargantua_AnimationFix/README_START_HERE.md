# Gargantua MATLAB Project – Burn Legend + Phase Panels Update

This update adds:

1. Burn events B1, B2, B3, and B4 to the **legend** in the full mission graph.
2. Three extra live animation panels in `kerrPresentation.m`:
   - Approach
   - Circular orbit
   - Return

## Replace these files
- `plotTrajectory.m`
- `kerrPresentation.m`

## Notes
- B1 and B4 occur at the same station location, so they remain overlapped on the actual trajectory graph, but both are listed separately in the legend.
- The three extra panels are phase-specific views that animate only during their corresponding mission phase.
