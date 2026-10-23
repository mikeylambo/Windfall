// Replace the digits 0-9 of a Pixelify Sans weight with Jersey 10's, scaled
// to Pixelify's cap height so numbers read cleanly ("5" vs "S").
// Usage: npm i opentype.js@1.3.4 wawoff2@2.0.1
//        node merge_digits.js PixelifySans-SemiBold.woff2 Jersey10.woff2 PixelifySans-SemiBold-JD.ttf
const fs = require('fs'), path = require('path');
const ot = require('opentype.js'), w2 = require('wawoff2');
(async () => {
  const [src, donorPath, out] = process.argv.slice(2);
  const load = async p => { let b = fs.readFileSync(p); if (p.endsWith('.woff2')) b = Buffer.from(await w2.decompress(b)); return ot.parse(b.buffer.slice(b.byteOffset, b.byteOffset + b.length)); };
  const f = await load(src), d = await load(donorPath);
  // match the donor digit height to the target cap height (incl. its overshoot)
  const capT = f.charToGlyph('H').getBoundingBox(), capD = d.charToGlyph('0').getBoundingBox();
  const k = (capT.y2 - capT.y1) / (capD.y2 - capD.y1), dy = capT.y1 - capD.y1 * k;
  const pad = Math.round((f.charToGlyph('0').advanceWidth - d.charToGlyph("0").advanceWidth * k) / 4);
  console.log('scale', k.toFixed(4), 'dy', dy, 'pad', pad);
  const chars = '0123456789';
  const glyphs = [];
  for (let i = 0; i < f.glyphs.length; i++) glyphs.push(f.glyphs.get(i));
  for (const ch of chars) {
    const dg = d.charToGlyph(ch), fi = f.charToGlyphIndex(ch);
    const p = new ot.Path();
    for (const c of dg.path.commands) {
      const s = {...c};
      for (const key of ['x', 'x1', 'x2']) if (key in s) s[key] = Math.round(s[key] * k) + pad;
      for (const key of ['y', 'y1', 'y2']) if (key in s) s[key] = Math.round(s[key] * k + dy);
      p.commands.push(s);
    }
    const g = glyphs[fi];
    g.path = p; g.advanceWidth = Math.round(dg.advanceWidth * k) + 2 * pad;
  }
  const nf = new ot.Font({familyName: f.names.fontFamily.en, styleName: f.names.fontSubfamily.en, unitsPerEm: f.unitsPerEm,
    ascender: f.ascender, descender: f.descender, glyphs});
  fs.writeFileSync(out, Buffer.from(nf.toArrayBuffer()));
  console.log('wrote', out);
})();
