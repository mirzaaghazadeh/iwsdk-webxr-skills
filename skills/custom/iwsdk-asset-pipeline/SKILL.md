---
name: iwsdk-asset-pipeline
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Prepares 3D models, textures, HDR maps and audio for an IWSDK WebXR app on
  Meta Quest: which formats and glTF extensions IWSDK 1.x can load (Draco and
  KTX2 yes, Meshopt no), converting FBX/OBJ in Blender, optimizing GLB files
  with gltf-transform using IWSDK-safe flags (`--compress draco`,
  `--texture-compress ktx2`), checking files with a bundled script, sourcing
  assets (metavr asset search, @iwsdk/example-assets), and registering them in
  `src/assets.ts` with the right load priority. Use when the user says "add
  this model", "import FBX", "optimize GLB", "compress textures", "KTX2",
  "Draco", "meshopt", "model won't load", "setMeshoptDecoder must be called",
  "the app is slow to load", "asset too big", or asks about Meta Spatial Editor
  scenes.
---

# IWSDK asset pipeline

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

IWSDK 1.x doesn't optimise assets for you: "Vite copies files from `public/` without rewriting
them" (guide 08). The `@iwsdk/vite-plugin-gltf-optimizer` was retired in 0.5. So every model and
texture should be optimised **before** it goes into `public/`.

Hand-offs: building a procedural model in code → **`iwsdk-build-model`**; placing assets in a
scene → **`iwsdk-compose-scene`**; frame-time budgets → **`iwsdk-performance`**.

## Ground rules

- Ask before the first `npx @gltf-transform/cli …` (downloads a package) and before installing
  KTX-Software or Blender.
- Never overwrite the source file. Write `name.opt.glb` next to it, compare, then swap.
- Check the licence of every downloaded asset and record where it came from.
- Run the checker after every change: `node <this skill>/scripts/check-gltf.mjs file.glb`.

## 1. What IWSDK loads

| `AssetType` | Loader (IWSDK 1.0.1) | Use for |
|---|---|---|
| `GLTF` | three `GLTFLoader` + `DRACOLoader` + `KTX2Loader` | `.glb` / `.gltf` models (the only supported 3D format) |
| `Texture` | `TextureLoader` | JPG, PNG, WebP images. **Not `.ktx2`**: put KTX2 textures inside a glTF instead |
| `HDRTexture` | `HDRLoader` / `EXRLoader` | `.hdr` / `.exr` environment maps |
| `Audio` | `AudioLoader` | MP3, WAV, OGG (IWSDK guide 04) |
| `UIKitML` | runtime parser | `public/ui/*.uikitml` |

**glTF extensions** (super-three 0.181.0 `GLTFLoader`, as wired by IWSDK):

- Load: `KHR_draco_mesh_compression`, `KHR_texture_basisu` (KTX2), `KHR_mesh_quantization`,
  `EXT_mesh_gpu_instancing`, `EXT_texture_webp`, `EXT_texture_avif`, `KHR_texture_transform`,
  `KHR_lights_punctual`, `KHR_materials_*` (unlit, emissive_strength, clearcoat, sheen,
  transmission, volume, ior, specular, iridescence, anisotropy, dispersion), `EXT_materials_bump`.
- **Fail:** `EXT_meshopt_compression`. IWSDK sets no Meshopt decoder, so three throws
  "setMeshoptDecoder must be called before loading compressed files". This matters because
  `gltf-transform optimize` uses Meshopt **by default**.
- The Draco decoder and Basis transcoder are fetched at runtime from
  `https://unpkg.com/three@0.181.0/examples/jsm/libs/…`; IWSDK 1.0.1 has no project setting for
  local copies. The app needs network access to unpkg.com (and to `cdn.jsdelivr.net` for
  controller models).
- When a native scene loads, IWSDK stages its glTF assets with limits of **64 MiB per model** and
  **256 MiB in total**, counting the GLB/glTF plus external buffers and images
  (`MAX_SCENE_MODEL_PAYLOAD_BYTES`, `GLTFLoadTransaction`).

## 2. Get the asset

- **Your own / converted:** FBX, OBJ, 3DS → Blender **File → Import**, then **File → Export →
  glTF 2.0** (GLB). Apply scale so 1 unit = 1 m; +Y up; the asset's origin where it touches the
  floor (or its pivot); forward along -Z (the convention of IWSDK's model template).
- **Meta's asset library:** `npm exec metavr -- asset search "wooden crate" -c 5` (the project's
  `metavr` dev dependency; the `metavr` MCP server exposes the same search). Copy chosen files into
  the project; don't hot-link a transient CDN URL (`iwsdk-build-model`).
- **IWSDK stock models:** the immutable `@iwsdk/example-assets@0.4.2` package on jsDelivr. Pin
  that exact version; for production, mirror the full `assets/<id>/` folders under `public/` and
  set `VITE_IWSDK_EXAMPLE_ASSET_BASE_URL` (guide 04). The scaffold's own `src/assets.ts` loads its
  starter desk, plant and robot from that CDN, so replace or mirror them before release.
- **Meta Spatial Editor / GLXF scenes** are not supported since 0.5. Recreate them as native scene
  JSON with **`iwsdk-migrate-0-5`**; export individual models from Spatial Editor or Blender as
  GLB and run them through this pipeline.

## 3. Inspect

```bash
node <skill>/scripts/check-gltf.mjs public/gltf/crate.glb      # loadability + weight, no deps
npx @gltf-transform/cli inspect public/gltf/crate.glb           # full report (meshes, textures, sizes, extensions)
```

`check-gltf.mjs` exits 1 for a file IWSDK can't load (Meshopt, a required unknown extension,
missing external buffer, parse error) and warns about textures over `--max-texture` (default
2048), non-power-of-two images, non-KTX2 textures and uncompressed geometry. It reports
primitives (a floor for draw calls) and approximate triangles. `--json` for scripts.

## 4. Optimise (IWSDK-safe)

```bash
npx @gltf-transform/cli optimize in.glb out.glb \
  --compress draco \
  --texture-compress ktx2 \
  --texture-size 2048
node <skill>/scripts/check-gltf.mjs out.glb
```

Flags verified in `@gltf-transform/cli` 4.5.1 (`optimize --help` for the full list):

| Flag | Default | IWSDK advice |
|---|---|---|
| `--compress` | `meshopt` | **Always pass `draco`** (or `quantize`, which needs no decoder). Never leave the default |
| `--texture-compress` | `auto` (re-encode in the original format) | `ktx2` (GPU-compressed; lower VRAM). Needs KTX-Software **4.4.0+** (`ktx --version`). `optimize` then uses UASTC for normal, occlusion and metal-roughness maps and ETC1S for the rest. `webp` shrinks the download but stays uncompressed in GPU memory |
| `--texture-size` | `2048` | `1024` for small props; `2048` for hero or large surfaces |
| `--flatten`, `--join`, `--join-named` | `true` | They merge meshes to cut draw calls, **including named ones**. If code or animations address parts by name (`getObjectByName`, articulated parts, grabbable children), pass `--join-named false` or `--flatten false --join false` |
| `--instance` | `true` | Uses `EXT_mesh_gpu_instancing` for repeated meshes (supported) |
| `--palette` | `true` | Merges simple materials into palette textures |
| `--simplify`, `--simplify-error` | `true`, `0.0001` | Conservative. For a stronger reduction use `simplify` on its own, then review in the headset |

Without KTX-Software, ask before installing it (https://github.com/KhronosGroup/KTX-Software
releases). Meta's WebXR guidance: use KTX2/Basis, and a different compression type for colour
maps than for normal maps.

Then compare `in.glb` and `out.glb` in the app (or with `npx @iwsdk/cli asset render-preview`,
see `iwsdk-build-model`) from the same viewpoint before replacing the original.

## 5. Register it

```ts
// src/assets.ts (shared by runtime and editor: no World, DOM, timers)
import { AssetType, defineAssets } from '@iwsdk/core';

const publicAssetUrl = (p: string) =>
  `${import.meta.env.BASE_URL}${p.replace(/^\/+/u, '')}`;

export default defineAssets({
  crate: { type: AssetType.GLTF, url: publicAssetUrl('gltf/crate.glb'), priority: 'background' },
  hall: { type: AssetType.GLTF, url: publicAssetUrl('gltf/hall.glb'), priority: 'critical' },
});
```

- Priorities (guide 04): `critical` blocks `World.create()` until loaded (use sparingly);
  `background` starts right after the critical ones; **`lazy`** registers without fetching (loads
  on first scene placement or explicit load). **An entry without `priority` is treated as
  critical** (`asset-manager.ts`), so set it explicitly. Each load has a 30-second timeout; a critical failure
  rejects `World.create()` with `AssetLoadError`.
- Build URLs from `import.meta.env.BASE_URL`, never a bare `/models/...` (breaks subpath hosting
  and the editor route).
- A file in `public/` isn't available to a scene until it is registered here. Place it from scene
  JSON (`"content": { "type": "asset", "asset": "crate" }`) with `iwsdk-compose-scene`.
- `AssetManager.getGLTF(id)` returns a fresh scene-graph clone with **shared** geometry and
  materials. Clone a material before changing one instance's colour; use `entity.dispose()` (not
  `destroy()`) for code-created GPU objects.
- Colour textures loaded as `AssetType.Texture` need `texture.colorSpace = SRGBColorSpace`.

## 6. Verify

1. `node <skill>/scripts/check-gltf.mjs public/gltf/*.glb` passes.
2. `npm run build` and sort `dist/assets` by size: no surprise multi-MB files.
3. In the running app: `npx @iwsdk/cli browser logs --count 50`, no loader errors; then check on
   the headset (`iwsdk-quest-device-testing`) for load time and frame rate.

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `setMeshoptDecoder must be called before loading compressed files` | File uses `EXT_meshopt_compression`. Re-run `optimize` with `--compress draco` |
| `setKTX2Loader must be called before loading KTX2 textures` | Loaded with a raw `GLTFLoader`. Use `AssetManager` / the manifest |
| Model loads offline in dev but fails on a locked-down network | Draco/Basis decoders come from unpkg.com at runtime |
| A named part disappeared after optimising | `--join`/`--flatten` merged it; re-run with `--join-named false` |
| Textures look washed out | Colour texture without `SRGBColorSpace` |
| `.ktx2` file in the manifest won't load | `AssetType.Texture` uses `TextureLoader`; embed the KTX2 texture in a glTF |
| `Model payload "<url>" is N bytes; the configured limit is M bytes` | Over 64 MiB (one model) or 256 MiB (all scene models): split or compress |

## Sources

- https://github.com/facebook/immersive-web-sdk (1.0.1): `packages/core/src/asset/loaders/gltf-loader.ts`, `texture-loader.ts`, `hdr-texture-loader.ts`, `asset-manager.ts`, `packages/scene-composition/src/validation.ts`, `docs/guides/04-external-assets.md`, `docs/guides/08-build-deploy.md`, `docs/public/skills/iwsdk-migrate-0-5/SKILL.md`, `packages/create/guidance/claude/.claude/rules/assets-and-manifest.md`
- https://unpkg.com/super-three@0.181.0/examples/jsm/loaders/GLTFLoader.js (extension list, Meshopt error)
- https://github.com/donmccurdy/glTF-Transform/blob/v4.5.1/packages/cli/src/cli.ts (`optimize` defaults), `packages/cli/src/transforms/toktx.ts` (KTX-Software 4.4.0+), `packages/functions/src/join.ts`, `simplify.ts`
- https://developers.meta.com/horizon/documentation/web/webxr-perf-bp/ (KTX2/Basis, separate compression for normal maps)
- `docs/metavr-cli-reference.md` in this library (`metavr asset search`)

Last verified: 2026-10-16
