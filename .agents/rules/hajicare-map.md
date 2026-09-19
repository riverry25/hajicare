---
trigger: always_on
---

# Hajicare Map Engineering Rules

## Architecture
- Preserve flutter_map.
- Preserve CARTO basemap.
- Preserve GetX.
- Reuse existing MapController, PoiService, RouteService, MapPoi abstractions.
- Do not create duplicate map/routing services.

## Geographic Data
- Never hardcode hotel coordinates.
- Never fabricate coordinates.
- Use OpenStreetMap/Overpass for nearby public hotel POIs.
- Validate all coordinates.
- Keep OSM attribution visible.

## Routing
- Use real road/path routing.
- Never use straight-line routing as navigation.
- Never use hand-generated walking waypoints for production routing.
- Use GeoJSON route geometry.
- Preserve longitude/latitude ordering correctly.

## GPS
- Null means GPS unavailable.
- default coordinates are never real GPS.
- Do not query POIs from fallback coordinates.

## Performance
- Never call POI APIs on every GPS tick.
- Never call routing APIs on every GPS tick.
- Use debouncing, caching, cooldowns and in-flight request guards.
- Avoid rebuilding the entire map on every state change.

## Security
- Never commit API secrets.
- Never log API secrets.
- Do not assume dart-define makes a mobile API key secure.
- Prefer server-side proxy for provider keys.

## UI
- Preserve current Hajicare visual language.
- Do not redesign unrelated screens.
- Maintain room-member markers and navigation UI.

## Validation
- Run dart format.
- Run flutter analyze.
- Run relevant flutter tests after changes.
- Do not claim verification without actually running commands.