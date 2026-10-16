#!/usr/bin/env node
// Check that .glb/.gltf files will load in IWSDK 1.x and report their weight.
// No dependencies. Usage: node check-gltf.mjs <file.glb|file.gltf> [...more] [--max-texture 2048] [--json]
// Exit code: 0 = loadable, 1 = will fail or can't be read, 2 = bad usage.
//
// Extension support = super-three 0.181.0 GLTFLoader built-ins, with the
// DRACOLoader and KTX2Loader that IWSDK wires in packages/core/src/asset/loaders/gltf-loader.ts.
// IWSDK sets no Meshopt decoder, so EXT_meshopt_compression fails to load.

import { readFileSync, existsSync, statSync } from 'node:fs';
import path from 'node:path';

const SUPPORTED = new Set([
  'KHR_binary_glTF', 'KHR_draco_mesh_compression', 'KHR_lights_punctual',
  'KHR_materials_clearcoat', 'KHR_materials_dispersion', 'KHR_materials_ior',
  'KHR_materials_sheen', 'KHR_materials_specular', 'KHR_materials_transmission',
  'KHR_materials_iridescence', 'KHR_materials_anisotropy', 'KHR_materials_unlit',
  'KHR_materials_volume', 'KHR_texture_basisu', 'KHR_texture_transform',
  'KHR_mesh_quantization', 'KHR_materials_emissive_strength', 'EXT_materials_bump',
  'EXT_texture_webp', 'EXT_texture_avif', 'EXT_mesh_gpu_instancing',
]);
const BLOCKED = {
  EXT_meshopt_compression:
    'IWSDK sets no Meshopt decoder ("setMeshoptDecoder must be called before loading compressed files"). Re-export with --compress draco or quantize.',
  KHR_meshopt_compression: 'Not handled by the GLTFLoader in super-three 0.181.0. Use Draco or quantize.',
};

const args = process.argv.slice(2);
const json = args.includes('--json');
let maxTexture = 2048;
const files = [];
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--json') continue;
  if (args[i] === '--max-texture') {
    maxTexture = Number(args[++i]);
    if (!Number.isFinite(maxTexture) || maxTexture <= 0) usage('--max-texture needs a positive number');
    continue;
  }
  if (args[i].startsWith('--')) usage(`unknown option ${args[i]}`);
  files.push(args[i]);
}
if (files.length === 0) usage('no input files');

function usage(msg) {
  console.error(`check-gltf: ${msg}\nusage: node check-gltf.mjs <file.glb|file.gltf> [...] [--max-texture 2048] [--json]`);
  process.exit(2);
}

function readModel(file) {
  const buf = readFileSync(file);
  if (buf.length >= 12 && buf.readUInt32LE(0) === 0x46546c67) {
    // GLB: header (magic, version, length), then chunks (length, type, data)
    if (buf.readUInt32LE(4) !== 2) throw new Error(`GLB version ${buf.readUInt32LE(4)} (need 2)`);
    let offset = 12;
    let gltf = null;
    let bin = null;
    while (offset + 8 <= buf.length) {
      const len = buf.readUInt32LE(offset);
      const type = buf.readUInt32LE(offset + 4);
      const data = buf.subarray(offset + 8, offset + 8 + len);
      if (type === 0x4e4f534a) gltf = JSON.parse(data.toString('utf8'));
      else if (type === 0x004e4942) bin = data;
      offset += 8 + len;
    }
    if (!gltf) throw new Error('GLB has no JSON chunk');
    return { gltf, bin, container: 'glb' };
  }
  return { gltf: JSON.parse(buf.toString('utf8')), bin: null, container: 'gltf' };
}

function imageBytes(model, image, baseDir) {
  if (image.bufferView !== undefined) {
    const bv = model.gltf.bufferViews?.[image.bufferView];
    if (!bv) return null;
    const buffer = model.gltf.buffers?.[bv.buffer ?? 0];
    let data = null;
    if (model.bin && (bv.buffer ?? 0) === 0 && !buffer?.uri) data = model.bin;
    else if (buffer?.uri) data = uriBytes(buffer.uri, baseDir);
    return data ? data.subarray(bv.byteOffset ?? 0, (bv.byteOffset ?? 0) + bv.byteLength) : null;
  }
  return image.uri ? uriBytes(image.uri, baseDir) : null;
}

function uriBytes(uri, baseDir) {
  if (uri.startsWith('data:')) return Buffer.from(uri.slice(uri.indexOf(',') + 1), 'base64');
  if (/^[a-z]+:\/\//i.test(uri)) return null; // remote: not checked
  const p = path.join(baseDir, decodeURIComponent(uri));
  return existsSync(p) ? readFileSync(p) : null;
}

function imageSize(b) {
  if (!b || b.length < 24) return null;
  if (b.readUInt32BE(0) === 0x89504e47) return { format: 'png', w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
  if (b[0] === 0xff && b[1] === 0xd8) {
    let o = 2;
    while (o + 9 < b.length) {
      if (b[o] !== 0xff) { o++; continue; }
      const marker = b[o + 1];
      const len = b.readUInt16BE(o + 2);
      if (marker >= 0xc0 && marker <= 0xcf && ![0xc4, 0xc8, 0xcc].includes(marker)) {
        return { format: 'jpeg', w: b.readUInt16BE(o + 7), h: b.readUInt16BE(o + 5) };
      }
      o += 2 + len;
    }
    return { format: 'jpeg', w: null, h: null };
  }
  if (b.subarray(1, 7).toString('latin1') === 'KTX 20') return { format: 'ktx2', w: b.readUInt32LE(20), h: b.readUInt32LE(24) };
  if (b.subarray(0, 4).toString('latin1') === 'RIFF' && b.subarray(8, 12).toString('latin1') === 'WEBP') {
    const kind = b.subarray(12, 16).toString('latin1');
    if (kind === 'VP8X') return { format: 'webp', w: 1 + b.readUIntLE(24, 3), h: 1 + b.readUIntLE(27, 3) };
    if (kind === 'VP8 ') return { format: 'webp', w: b.readUInt16LE(26) & 0x3fff, h: b.readUInt16LE(28) & 0x3fff };
    if (kind === 'VP8L') {
      const bits = b.readUInt32LE(21);
      return { format: 'webp', w: (bits & 0x3fff) + 1, h: ((bits >> 14) & 0x3fff) + 1 };
    }
    return { format: 'webp', w: null, h: null };
  }
  return null;
}

function check(file) {
  const out = { file, ok: true, errors: [], warnings: [], stats: {} };
  if (!existsSync(file)) {
    out.ok = false;
    out.errors.push('file not found');
    return out;
  }
  let model;
  try {
    model = readModel(file);
  } catch (e) {
    out.ok = false;
    out.errors.push(`cannot parse: ${e.message}`);
    return out;
  }
  const { gltf } = model;
  const baseDir = path.dirname(file);
  const used = gltf.extensionsUsed ?? [];
  const required = new Set(gltf.extensionsRequired ?? []);
  for (const ext of used) {
    if (BLOCKED[ext]) {
      out.ok = false;
      out.errors.push(`${ext}: ${BLOCKED[ext]}`);
    } else if (!SUPPORTED.has(ext)) {
      if (required.has(ext)) {
        out.ok = false;
        out.errors.push(`${ext} is required but not supported by IWSDK's loader`);
      } else {
        out.warnings.push(`${ext} is not handled by the loader and will be ignored`);
      }
    }
  }

  let triangles = 0;
  let primitives = 0;
  for (const mesh of gltf.meshes ?? []) {
    for (const prim of mesh.primitives ?? []) {
      primitives++;
      const mode = prim.mode ?? 4;
      const acc = prim.indices !== undefined ? gltf.accessors?.[prim.indices] : gltf.accessors?.[prim.attributes?.POSITION];
      const n = acc?.count ?? 0;
      if (mode === 4) triangles += Math.floor(n / 3);
      else if (mode === 5 || mode === 6) triangles += Math.max(0, n - 2);
    }
  }
  const textures = [];
  for (const [i, image] of (gltf.images ?? []).entries()) {
    const size = imageSize(imageBytes(model, image, baseDir));
    const entry = { index: i, name: image.name ?? image.uri ?? `image ${i}`, mimeType: image.mimeType ?? null, ...(size ?? {}) };
    textures.push(entry);
    if (size?.w && size?.h) {
      if (size.w > maxTexture || size.h > maxTexture) out.warnings.push(`${entry.name}: ${size.w}x${size.h} exceeds --max-texture ${maxTexture}`);
      if (size.format !== 'ktx2' && (size.w & (size.w - 1) || size.h & (size.h - 1))) out.warnings.push(`${entry.name}: ${size.w}x${size.h} is not power-of-two`);
    } else if (image.uri && /^[a-z]+:\/\//i.test(image.uri)) {
      out.warnings.push(`${entry.name}: remote image not checked`);
    }
  }
  const uncompressed = textures.filter((t) => t.format && t.format !== 'ktx2').length;
  if (uncompressed > 0) out.warnings.push(`${uncompressed} texture(s) are not KTX2: they are fully uncompressed in GPU memory`);
  if (!used.includes('KHR_draco_mesh_compression') && !used.includes('KHR_mesh_quantization') && triangles > 10000) {
    out.warnings.push('geometry is not Draco- or quantize-compressed');
  }
  for (const buffer of gltf.buffers ?? []) {
    if (buffer.uri && !buffer.uri.startsWith('data:') && !/^[a-z]+:\/\//i.test(buffer.uri) && !existsSync(path.join(baseDir, decodeURIComponent(buffer.uri)))) {
      out.ok = false;
      out.errors.push(`missing external buffer ${buffer.uri}`);
    }
  }

  out.stats = {
    container: model.container,
    fileBytes: statSync(file).size,
    extensionsUsed: used,
    extensionsRequired: [...required],
    nodes: gltf.nodes?.length ?? 0,
    meshes: gltf.meshes?.length ?? 0,
    primitives,
    triangles,
    materials: gltf.materials?.length ?? 0,
    animations: gltf.animations?.length ?? 0,
    textures,
  };
  return out;
}

const results = files.map(check);
if (json) {
  console.log(JSON.stringify(results, null, 2));
} else {
  for (const r of results) {
    console.log(`\n${r.ok ? 'OK  ' : 'FAIL'} ${r.file}`);
    const s = r.stats;
    if (s.container) {
      console.log(`  ${s.container}, ${(s.fileBytes / 1024).toFixed(1)} KiB, nodes ${s.nodes}, meshes ${s.meshes}, primitives ${s.primitives} (rough draw-call floor), triangles ~${s.triangles}, materials ${s.materials}, animations ${s.animations}`);
      console.log(`  extensions: ${s.extensionsUsed.length ? s.extensionsUsed.join(', ') : 'none'}`);
      for (const t of s.textures) console.log(`  texture ${t.name}: ${t.format ?? t.mimeType ?? '?'} ${t.w ?? '?'}x${t.h ?? '?'}`);
    }
    for (const e of r.errors) console.log(`  ERROR ${e}`);
    for (const w of r.warnings) console.log(`  warn  ${w}`);
  }
}
process.exit(results.every((r) => r.ok) ? 0 : 1);
