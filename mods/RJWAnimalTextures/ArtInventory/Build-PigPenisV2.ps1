# PigPenis is the RJW Genes screw icon, stamped whole.
# Rest is the pale bulb. Aroused is the whole icon, bulb and screw together.
# Ball files are blank. North penis files are blank 4x4.
# This is the live texture set. The previous design stays in ArtInventory/GeneratedPigPenis.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class PigPenisV2
{
    static readonly Color Outline = Color.FromArgb(255, 0, 0, 0);
    static readonly Color BulbHi = Color.FromArgb(255, 200, 147, 137);
    static readonly Color Bulb = Color.FromArgb(255, 183, 130, 121);
    static readonly Color BulbShade = Color.FromArgb(255, 150, 104, 96);
    static readonly Color Screw = Color.FromArgb(255, 147, 38, 34);
    static readonly Color ScrewHi = Color.FromArgb(255, 176, 50, 46);
    static readonly Color ScrewShade = Color.FromArgb(255, 104, 22, 22);
    static readonly Color Mouth = Color.FromArgb(255, 92, 18, 20);

    static readonly float[] AroH = { 52, 67, 92, 120, 147, 186 };

    public static void Build(string penisRoot, string previewPath)
    {
        string horny = Path.Combine(penisRoot, "Horny");
        string balls = Path.Combine(penisRoot, "Balls");
        Directory.CreateDirectory(penisRoot);
        Directory.CreateDirectory(horny);
        Directory.CreateDirectory(balls);
        for (int size = 0; size <= 5; size++)
        {
            Save(Stamp(size, false, false), Path.Combine(penisRoot, "PigPenis_" + size + "_south.png"));
            Save(Stamp(size, true, false), Path.Combine(penisRoot, "PigPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(penisRoot, "PigPenis_" + size + "_north.png"));
            Save(Stamp(size, false, true), Path.Combine(horny, "PigPenis_" + size + "_south.png"));
            Save(Stamp(size, true, true), Path.Combine(horny, "PigPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(horny, "PigPenis_" + size + "_north.png"));
            Save(Blank(), Path.Combine(balls, "PigPenis_" + size + "_south.png"));
            Save(Blank(), Path.Combine(balls, "PigPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(balls, "PigPenis_" + size + "_north.png"));
        }
        BuildPreview(previewPath);
    }

    static void Save(Bitmap bmp, string path)
    {
        bmp.Save(path, ImageFormat.Png);
        bmp.Dispose();
    }

    static Bitmap Canvas()
    {
        var bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) g.Clear(Color.Transparent);
        return bmp;
    }

    static Graphics G(Bitmap bmp)
    {
        var g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.CompositingQuality = CompositingQuality.HighQuality;
        return g;
    }

    static Bitmap Blank()
    {
        var bmp = new Bitmap(4, 4, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) g.Clear(Color.Transparent);
        return bmp;
    }

    static Pen Line(Color color, float width)
    {
        var pen = new Pen(color, Math.Max(1.2f, width));
        pen.LineJoin = LineJoin.Round;
        pen.StartCap = LineCap.Round;
        pen.EndCap = LineCap.Round;
        return pen;
    }

    static void StrokeOpenShaft(Graphics g, PointF[] pts, Color color, float width)
    {
        using (var pen = Line(color, width))
        {
            g.DrawLines(pen, new PointF[] { pts[0], pts[1], pts[2], pts[3], pts[4], pts[5], pts[6], pts[7], pts[8], pts[9], pts[10] });
            g.DrawLine(pen, pts[10], pts[11]);
            g.DrawLine(pen, pts[12], pts[0]);
        }
    }

    static void ShaftSize(int size, out float tubeR, out float helixR, out float turns)
    {
        tubeR = 3.4f + size * 1.15f;
        helixR = 8.5f + size * 1.7f;
        turns = 2.25f + size * 0.1f;
    }

    static void SheathSize(int size, out float along, out float bulk)
    {
        along = 29f + size * 6.0f;
        bulk = 31f + size * 6.8f;
    }

    public static string CoilSource;
    static Bitmap CoilBmp;
    static Bitmap FullBmp;
    static Bitmap RestBmp;
    static PointF PaleAnchor;
    static float StampAngle;
    static PointF CoilBase;
    static float CoilLen;
    static float CoilAngle;
    static float CoilRoot;
    static float CoilStub;
    static float CoilFlare;

    static bool Opaque(Color c)
    {
        return c.A >= 12;
    }

    static float SampleWidth(PointF origin, float px, float py)
    {
        float reach = 0f;
        for (int sign = -1; sign <= 1; sign += 2)
        {
            for (float d = 0f; d < 80f; d += 1f)
            {
                int sx = (int)Math.Round(origin.X + px * d * sign);
                int sy = (int)Math.Round(origin.Y + py * d * sign);
                if (sx < 0 || sy < 0 || sx >= CoilBmp.Width || sy >= CoilBmp.Height || !Opaque(CoilBmp.GetPixel(sx, sy)))
                {
                    reach += Math.Max(0f, d - 1f);
                    break;
                }
            }
        }
        return Math.Max(1f, reach);
    }

    static void LoadCoil()
    {
        if (CoilBmp != null) return;
        using (var src = new Bitmap(CoilSource))
        {
            int cut = 206;
            int minX = src.Width, minY = src.Height, maxX = -1, maxY = -1;
            for (int y = 60; y < 356; y++)
            for (int x = cut; x < src.Width; x++)
            {
                if (!Opaque(src.GetPixel(x, y))) continue;
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }
            int w = maxX - minX + 1;
            int h = maxY - minY + 1;
            CoilBmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            float tipX = 0f, tipY = 0f, tipN = 0f;
            int baseX = -1, baseMin = 0, baseMax = 0;
            for (int y = minY; y <= maxY; y++)
            for (int x = minX; x <= maxX; x++)
            {
                Color c = src.GetPixel(x, y);
                if (!Opaque(c)) continue;
                int lx = x - minX;
                int ly = y - minY;
                CoilBmp.SetPixel(lx, ly, c);
                if (baseX < 0 || lx < baseX) { baseX = lx; baseMin = ly; baseMax = ly; }
                else if (lx == baseX) { if (ly < baseMin) baseMin = ly; if (ly > baseMax) baseMax = ly; }
                if (x > maxX - 18) { tipX += lx; tipY += ly; tipN++; }
            }
            CoilBase = new PointF(baseX, (baseMin + baseMax) * 0.5f);
            var tip = new PointF(tipX / tipN, tipY / tipN);
            float dx = tip.X - CoilBase.X;
            float dy = tip.Y - CoilBase.Y;
            CoilLen = (float)Math.Sqrt(dx * dx + dy * dy);
            float ang = (float)Math.Atan2(-dy, dx);
            CoilAngle = ang * 180f / (float)Math.PI;
            float ax = (float)Math.Cos(ang);
            float ay = -(float)Math.Sin(ang);
            float px = (float)Math.Sin(ang);
            float py = (float)Math.Cos(ang);
            CoilRoot = SampleWidth(new PointF(CoilBase.X + ax * 10f, CoilBase.Y + ay * 10f), px, py);
            CoilStub = 12f;
            for (float d = 6f; d < CoilLen; d += 2f)
            {
                float width = SampleWidth(new PointF(CoilBase.X + ax * d, CoilBase.Y + ay * d), px, py);
                if (width > CoilRoot * 1.22f)
                {
                    CoilStub = d;
                    break;
                }
            }
            for (int y = 0; y < h; y++)
            for (int x = 0; x < w; x++)
            {
                Color c = CoilBmp.GetPixel(x, y);
                if (c.A == 0) continue;
                float along = (x - CoilBase.X) * ax + (y - CoilBase.Y) * ay;
                float t = along / CoilStub;
                if (t >= 1f) continue;
                float fade = t <= 0f ? 0f : t * t * (3f - 2f * t);
                CoilBmp.SetPixel(x, y, Color.FromArgb((int)(c.A * fade), c.R, c.G, c.B));
            }
            CoilFlare = SampleWidth(new PointF(CoilBase.X + ax * CoilStub, CoilBase.Y + ay * CoilStub), px, py);
            int fMinX = src.Width, fMinY = src.Height, fMaxX = -1, fMaxY = -1;
            for (int y = 0; y < src.Height; y++)
            for (int x = 0; x < src.Width; x++)
            {
                if (!Opaque(src.GetPixel(x, y))) continue;
                if (x < fMinX) fMinX = x;
                if (y < fMinY) fMinY = y;
                if (x > fMaxX) fMaxX = x;
                if (y > fMaxY) fMaxY = y;
            }
            int fw = fMaxX - fMinX + 1;
            int fh = fMaxY - fMinY + 1;
            FullBmp = new Bitmap(fw, fh, PixelFormat.Format32bppArgb);
            RestBmp = new Bitmap(fw, fh, PixelFormat.Format32bppArgb);
            double psx = 0, psy = 0;
            int pn = 0;
            for (int y = fMinY; y <= fMaxY; y++)
            for (int x = fMinX; x <= fMaxX; x++)
            {
                Color c = src.GetPixel(x, y);
                if (!Opaque(c)) continue;
                int lx = x - fMinX;
                int ly = y - fMinY;
                FullBmp.SetPixel(lx, ly, c);
                if (c.A >= 16 && c.R > 140 && c.G > 90 && c.G > c.B && c.R > c.G - 10)
                {
                    RestBmp.SetPixel(lx, ly, c);
                    psx += lx;
                    psy += ly;
                    pn++;
                }
            }
            PaleAnchor = new PointF((float)(psx / pn), (float)(psy / pn));
            float farPx = -1f, endX = PaleAnchor.X, endY = PaleAnchor.Y;
            for (int y = 0; y < fh; y++)
            for (int x = 0; x < fw; x++)
            {
                Color c = FullBmp.GetPixel(x, y);
                if (c.A < 16 || RestBmp.GetPixel(x, y).A >= 16) continue;
                float dx2 = x - PaleAnchor.X;
                float dy2 = y - PaleAnchor.Y;
                float d2 = dx2 * dx2 + dy2 * dy2;
                if (d2 > farPx) { farPx = d2; endX = x; endY = y; }
            }
            StampAngle = (float)(Math.Atan2(-(endY - PaleAnchor.Y), endX - PaleAnchor.X) * 180.0 / Math.PI);
            Console.WriteLine("STAMP pale=" + pn + " angle=" + StampAngle.ToString("0.0"));
        }
    }

    static Bitmap Stamp(int size, bool east, bool full)
    {
        LoadCoil();
        float scale = 0.22f + size * 0.07f;
        Bitmap art = full ? FullBmp : RestBmp;
        var bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
            g.TranslateTransform(east ? 248f : 256f, 286f);
            g.RotateTransform(StampAngle - (east ? StampAngle : 90f));
            g.ScaleTransform(scale, scale);
            g.TranslateTransform(-PaleAnchor.X, -PaleAnchor.Y);
            g.InterpolationMode = InterpolationMode.HighQualityBicubic;
            g.PixelOffsetMode = PixelOffsetMode.HighQuality;
            g.DrawImage(art, 0, 0);
        }
        return bmp;
    }

    static void DrawCoil(Graphics g, float destX, float destY, float angleDeg, float scale)
    {
        LoadCoil();
        var state = g.Save();
        g.TranslateTransform(destX, destY);
        g.RotateTransform(CoilAngle - angleDeg);
        g.ScaleTransform(scale, scale);
        g.TranslateTransform(-CoilBase.X, -CoilBase.Y);
        var old = g.InterpolationMode;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.DrawImage(CoilBmp, 0, 0);
        g.InterpolationMode = old;
        g.Restore(state);
    }

    static void DrawStraight(Graphics g, float x0, float y0, float x1, float y1, float radius, float endRadius)
    {
        float dx = x1 - x0;
        float dy = y1 - y0;
        float len = (float)Math.Sqrt(dx * dx + dy * dy);
        if (len < 1f) return;
        float ux = dx / len;
        float uy = dy / len;
        float px = -uy;
        float py = ux;
        float r0 = radius;
        float r1 = endRadius;
        var pts = new PointF[13];
        for (int i = 0; i <= 10; i++)
        {
            double a = Math.PI * 0.5 + Math.PI * i / 10.0;
            float c = (float)Math.Cos(a);
            float s = (float)Math.Sin(a);
            pts[i] = new PointF(x0 + ux * c * r0 + px * s * r0, y0 + uy * c * r0 + py * s * r0);
        }
        pts[11] = new PointF(x1 - px * r1, y1 - py * r1);
        pts[12] = new PointF(x1 + px * r1, y1 + py * r1);
        using (var path = new GraphicsPath())
        {
            path.AddPolygon(pts);
            RectangleF bounds = path.GetBounds();
            bounds.Inflate(2f, 2f);
            bool upright = Math.Abs(dy) >= Math.Abs(dx);
            using (var brush = new LinearGradientBrush(bounds, ScrewHi, ScrewShade, upright ? LinearGradientMode.Horizontal : LinearGradientMode.Vertical))
            {
                var blend = new ColorBlend(3);
                blend.Colors = new Color[] { ScrewHi, Screw, ScrewShade };
                blend.Positions = new float[] { 0f, 0.42f, 1f };
                brush.InterpolationColors = blend;
                g.FillPath(brush, path);
            }
            StrokeOpenShaft(g, pts, Outline, Math.Max(2.2f, radius * 0.62f));
        }
    }

    static void DrawShaftAndCoil(Graphics g, float x0, float y0, float x1, float y1, float radius, float angleDeg, float maxReach)
    {
        LoadCoil();
        float dx = x1 - x0;
        float dy = y1 - y0;
        float len = (float)Math.Sqrt(dx * dx + dy * dy);
        float ux = dx / len;
        float uy = dy / len;
        float scale = radius * 2.12f / CoilRoot;
        float reach = (CoilLen - CoilStub) * scale;
        if (reach > maxReach && maxReach > 12f)
        {
            scale *= maxReach / reach;
            radius = CoilRoot * scale / 2.12f;
        }
        float inset = CoilStub * scale;
        float endRadius = Math.Max(radius * 0.96f, CoilFlare * scale * 0.5f);
        DrawStraight(g, x0, y0, x1, y1, radius, endRadius);
        DrawCoil(g, x1 - ux * inset, y1 - uy * inset, angleDeg, scale);
    }

    static Bitmap DrawRestSouth(int size)
    {
        return Blank();
    }

    static Bitmap DrawRestEast(int size)
    {
        return Blank();
    }

    static void PlaceSheathSouth(int size, out float along, out float bulk, out float cy, out float mouthY)
    {
        SheathSize(size, out along, out bulk);
        cy = 270f - along * 0.50f;
        mouthY = cy - along * 0.34f;
    }

    static void PlaceSheathEast(int size, out float along, out float bulk, out float cx, out float mouthX)
    {
        SheathSize(size, out along, out bulk);
        cx = 248f + along * 0.50f;
        mouthX = cx + along * 0.28f;
    }

    static Bitmap DrawArousedSouth(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp))
        {
            float along, bulk, cy, mouthY;
            PlaceSheathSouth(size, out along, out bulk, out cy, out mouthY);
            float tubeR, helixR, turns;
            ShaftSize(size, out tubeR, out helixR, out turns);
            float shaft = AroH[size] * 0.32f;
            float room = (mouthY - shaft) - 48f;
            DrawShaftAndCoil(g, 256f, mouthY + along * 0.22f, 256f, mouthY - shaft, tubeR, 90f, room);
        }
        return bmp;
    }

    static Bitmap DrawArousedEast(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp))
        {
            float along, bulk, cx, mouthX;
            PlaceSheathEast(size, out along, out bulk, out cx, out mouthX);
            float tubeR, helixR, turns;
            ShaftSize(size, out tubeR, out helixR, out turns);
            float shaft = AroH[size] * 0.32f;
            float ang = 35f * (float)Math.PI / 180f;
            float ux = (float)Math.Cos(ang);
            float uy = -(float)Math.Sin(ang);
            float southMouth = 270f - along * 0.84f;
            float southShaft = AroH[size] * 0.32f;
            float room = (southMouth - southShaft) - 48f;
            DrawShaftAndCoil(g, mouthX - ux * along * 0.18f, 250f - uy * along * 0.18f, mouthX + ux * shaft, 250f + uy * shaft, tubeR, 35f, room);
        }
        return bmp;
    }

    static PointF BulbPoint(float cx, float cy, float along, float side, bool vertical)
    {
        if (vertical) return new PointF(cx + side, cy + along);
        return new PointF(cx - along, cy + side);
    }

    static void DrawBulb(Graphics g, float cx, float cy, float length, float bulk, bool vertical, bool openNeck)
    {
        var pts = new[] {
            BulbPoint(cx, cy, -length * 0.48f, 0f, vertical),
            BulbPoint(cx, cy, -length * 0.28f, bulk * 0.28f, vertical),
            BulbPoint(cx, cy, length * 0.05f, bulk * 0.50f, vertical),
            BulbPoint(cx, cy, length * 0.42f, bulk * 0.34f, vertical),
            BulbPoint(cx, cy, length * 0.50f, 0f, vertical),
            BulbPoint(cx, cy, length * 0.42f, -bulk * 0.34f, vertical),
            BulbPoint(cx, cy, length * 0.05f, -bulk * 0.50f, vertical),
            BulbPoint(cx, cy, -length * 0.28f, -bulk * 0.28f, vertical)
        };
        using (var path = new GraphicsPath())
        {
            path.AddClosedCurve(pts, 0.55f);
            RectangleF bounds = path.GetBounds();
            bounds.Inflate(2f, 2f);
            using (var brush = new LinearGradientBrush(bounds, BulbHi, BulbShade, vertical ? LinearGradientMode.Horizontal : LinearGradientMode.Vertical))
            {
                var blend = new ColorBlend(3);
                blend.Colors = new Color[] { BulbHi, Bulb, BulbShade };
                blend.Positions = new float[] { 0f, 0.48f, 1f };
                brush.InterpolationColors = blend;
                g.FillPath(brush, path);
            }
            using (var edgePen = Line(Outline, Math.Max(2.4f, bulk * 0.12f)))
            {
                if (!openNeck)
                    g.DrawPath(edgePen, path);
                else
                {
                    var lip = new PointF[7];
                    for (int i = 0; i < 7; i++) lip[i] = pts[i + 1];
                    using (var open = new GraphicsPath())
                    {
                        open.AddCurve(lip, 0.55f);
                        g.DrawPath(edgePen, open);
                    }
                }
            }
        }
        if (openNeck) return;
        float mw = bulk * 0.22f;
        float mh = length * 0.16f;
        RectangleF mouth = vertical
            ? new RectangleF(cx - mw * 0.5f, cy - length * 0.50f, mw, mh)
            : new RectangleF(cx + length * 0.46f - mw, cy - mh * 0.5f, mw, mh);
        using (var brush = new SolidBrush(Mouth))
            g.FillEllipse(brush, mouth);
        using (var pen = Line(Outline, 1.3f))
            g.DrawEllipse(pen, mouth);
    }

    sealed class Sample
    {
        public float X, Y, Z, T;
    }

    // vertical: base at the high Y, tip toward the low Y.
    // horizontal: base at the low X, tip toward the high X.
    static void DrawScrew(Graphics g, float mouthX, float mouthY, float length, float tubeR, float helixR, float turns, bool vertical, float straightFrac, float bury)
    {
        if (length < 8f) length = 8f;
        if (straightFrac < 0f) straightFrac = 0f;
        if (straightFrac > 0.7f) straightFrac = 0.7f;
        if (bury < 1f) bury = 1f;
        float total = length + bury;
        float buriedT = bury / total;
        int count = Math.Max(120, (int)Math.Round(turns * 90f));
        var samples = new List<Sample>(count + 1);
        float ang = 35f * (float)Math.PI / 180f;
        float ux = (float)Math.Cos(ang);
        float uy = -(float)Math.Sin(ang);
        float px = -uy;
        float py = ux;
        for (int i = 0; i <= count; i++)
        {
            float t = i / (float)count;
            float visible = (t - buriedT) / (1f - buriedT);
            if (visible < 0f) visible = 0f;
            if (visible > 1f) visible = 1f;
            float helixU = 0f;
            if (visible > straightFrac)
                helixU = (visible - straightFrac) / (1f - straightFrac);
            float ramp = helixU / 0.16f;
            if (ramp > 1f) ramp = 1f;
            ramp = ramp * ramp * (3f - 2f * ramp);
            float tipFade = 0f;
            if (helixU > 0.8f)
            {
                tipFade = (helixU - 0.8f) / 0.2f;
                ramp *= 1f - tipFade * 0.45f;
            }
            float theta = (float)(Math.PI * 0.5 + (helixU - 1.0) * turns * Math.PI * 2.0);
            var s = new Sample();
            s.T = helixU * 0.28f + tipFade * 0.72f;
            s.Z = (visible <= straightFrac || helixU < 0.06f) ? 1f : (float)Math.Sin(theta);
            float coil = (float)Math.Cos(theta) * ramp;
            float fromStart = t * total;
            if (vertical)
            {
                s.X = mouthX + helixR * coil;
                s.Y = (mouthY + bury) - fromStart;
            }
            else
            {
                float startX = mouthX - ux * bury;
                float startY = mouthY - uy * bury;
                s.X = startX + ux * fromStart + px * helixR * coil;
                s.Y = startY + uy * fromStart + py * helixR * coil;
            }
            samples.Add(s);
        }

        PointF[] left;
        PointF[] right;
        Ribbon(samples, tubeR, out left, out right);
        var cuts = new List<int>();
        cuts.Add(0);
        for (int i = 1; i < samples.Count; i++)
        {
            if (samples[i - 1].Z * samples[i].Z < 0f) cuts.Add(i);
        }
        cuts.Add(samples.Count - 1);
        for (int pass = 0; pass < 2; pass++)
        {
            for (int c = 0; c < cuts.Count - 1; c++)
            {
                int a0 = cuts[c];
                int b0 = cuts[c + 1];
                if (b0 - a0 < 2) continue;
                float z = 0f;
                int n = 0;
                for (int i = a0; i <= b0; i++) { z += samples[i].Z; n++; }
                bool front = z / Math.Max(1, n) >= 0f;
                int a = Math.Max(0, a0 - 2);
                int b = Math.Min(samples.Count - 1, b0 + 2);
                if (front != (pass == 1)) continue;
                bool tip = samples[b].T > 0.82f;
                FillRange(g, left, right, a, b, front ? (tip ? ScrewHi : Screw) : ScrewShade);
            }
        }
        using (var pen = Line(Outline, Math.Max(1.15f, tubeR * 0.18f)))
        {
            g.DrawLines(pen, left);
            g.DrawLines(pen, right);
            g.DrawLine(pen, left[left.Length - 1], right[right.Length - 1]);
        }
    }

    static void Ribbon(List<Sample> samples, float tubeR, out PointF[] left, out PointF[] right)
    {
        int n = samples.Count;
        left = new PointF[n];
        right = new PointF[n];
        for (int i = 0; i < n; i++)
        {
            int i0 = i > 0 ? i - 1 : 0;
            int i1 = i < n - 1 ? i + 1 : n - 1;
            float dx = samples[i1].X - samples[i0].X;
            float dy = samples[i1].Y - samples[i0].Y;
            float len = (float)Math.Sqrt(dx * dx + dy * dy);
            if (len < 0.001f) { dx = 0f; dy = -1f; len = 1f; }
            dx /= len;
            dy /= len;
            float r = RadiusAt(samples[i].T, tubeR);
            left[i] = new PointF(samples[i].X - dy * r, samples[i].Y + dx * r);
            right[i] = new PointF(samples[i].X + dy * r, samples[i].Y - dx * r);
        }
    }

    static void FillRange(Graphics g, PointF[] left, PointF[] right, int a, int b, Color color)
    {
        int n = b - a + 1;
        if (n < 2) return;
        var sideA = new PointF[n];
        var sideB = new PointF[n];
        for (int i = 0; i < n; i++)
        {
            sideA[i] = left[a + i];
            sideB[i] = right[a + i];
        }
        Array.Reverse(sideB);
        using (var path = new GraphicsPath(FillMode.Winding))
        {
            path.AddLines(sideA);
            path.AddLines(sideB);
            path.CloseFigure();
            using (var brush = new SolidBrush(color))
                g.FillPath(brush, path);
        }
    }

    static float RadiusAt(float t, float tubeR)
    {
        if (t <= 0f) return tubeR;
        float r = tubeR * (1f - t);
        if (r < 0.45f) r = 0.45f;
        return r;
    }

    static Bitmap DrawBalls(int size, bool side)
    {
        var bmp = Canvas();
        using (var g = G(bmp))
        {
            if (!side)
            {
                float along, bulk, cy, mouthY;
                PlaceSheathSouth(size, out along, out bulk, out cy, out mouthY);
                DrawBulb(g, 256f, cy, along, bulk, true, false);
            }
            else
            {
                float along, bulk, cx, mouthX;
                PlaceSheathEast(size, out along, out bulk, out cx, out mouthX);
                DrawBulb(g, cx, 250f, along, bulk, false, false);
            }
        }
        return bmp;
    }

    static void BuildPreview(string previewPath)
    {
        int cell = 160;
        int labelW = 64;
        int header = 46;
        int cols = 5;
        int rows = 6;
        int gap = 6;
        int width = 16 + labelW + cols * (cell + gap);
        int height = 16 + header + rows * (cell + gap) + 28;
        var frames = new Bitmap[rows, cols];
        int maxDim = 1;
        for (int size = 0; size <= 5; size++)
        {
            frames[size, 0] = Stamp(size, false, false);
            frames[size, 1] = Stamp(size, true, false);
            frames[size, 2] = Stamp(size, false, true);
            frames[size, 3] = Stamp(size, true, true);
            frames[size, 4] = Blank();
            for (int c = 0; c < cols; c++)
            {
                Rectangle box = ContentBox(frames[size, c]);
                if (box.Width > maxDim) maxDim = box.Width;
                if (box.Height > maxDim) maxDim = box.Height;
            }
        }
        float shared = (cell - 16f) / maxDim;
        using (var sheet = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        using (var g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 22, 22, 26));
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;
            using (var title = new Font("Segoe UI", 13f, FontStyle.Bold))
            using (var small = new Font("Segoe UI", 8f))
            using (var white = new SolidBrush(Color.FromArgb(255, 236, 232, 220)))
            using (var muted = new SolidBrush(Color.FromArgb(255, 176, 172, 160)))
            {
                g.DrawString("PigPenis from the whole gene icon", title, white, 14f, 8f);
                g.DrawString("Rest is the bulb. Aroused is the bulb and screw together. Balls are blank.", small, muted, 14f, 28f);
                string[] headers = { "Rest south", "Rest east", "Aroused south", "Aroused east", "Balls south" };
                for (int c = 0; c < cols; c++)
                {
                    var rect = new RectangleF(16 + labelW + c * (cell + gap), header - 2, cell, 18);
                    using (var fmt = new StringFormat { Alignment = StringAlignment.Center })
                        g.DrawString(headers[c], small, white, rect, fmt);
                }
                for (int size = 0; size <= 5; size++)
                {
                    int y = header + 16 + size * (cell + gap);
                    g.DrawString("size " + size, small, white, 10f, y + cell * 0.45f);
                    for (int c = 0; c < cols; c++)
                    {
                        int x = 16 + labelW + c * (cell + gap);
                        DrawCell(g, frames[size, c], new Rectangle(x, y, cell, cell), shared);
                        frames[size, c].Dispose();
                    }
                }
            }
            sheet.Save(previewPath, ImageFormat.Png);
        }
    }

    static Rectangle ContentBox(Bitmap sprite)
    {
        int minX = sprite.Width, minY = sprite.Height, maxX = -1, maxY = -1;
        var data = sprite.LockBits(new Rectangle(0, 0, sprite.Width, sprite.Height), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try
        {
            int stride = Math.Abs(data.Stride);
            byte[] buffer = new byte[stride * sprite.Height];
            System.Runtime.InteropServices.Marshal.Copy(data.Scan0, buffer, 0, buffer.Length);
            for (int y = 0; y < sprite.Height; y++)
            {
                int row = y * stride;
                for (int x = 0; x < sprite.Width; x++)
                {
                    if (buffer[row + x * 4 + 3] < 16) continue;
                    if (x < minX) minX = x;
                    if (y < minY) minY = y;
                    if (x > maxX) maxX = x;
                    if (y > maxY) maxY = y;
                }
            }
        }
        finally { sprite.UnlockBits(data); }
        if (maxX < 0) return Rectangle.Empty;
        return new Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
    }

    static void DrawCell(Graphics g, Bitmap sprite, Rectangle cell, float scale)
    {
        using (var dark = new SolidBrush(Color.FromArgb(255, 46, 46, 50)))
        using (var lite = new SolidBrush(Color.FromArgb(255, 68, 68, 74)))
        {
            for (int y = 0; y < cell.Height; y += 8)
            for (int x = 0; x < cell.Width; x += 8)
            {
                bool alt = ((x / 8) + (y / 8)) % 2 == 0;
                g.FillRectangle(alt ? dark : lite, cell.X + x, cell.Y + y, 8, 8);
            }
        }
        Rectangle box = ContentBox(sprite);
        if (box.Width <= 0) return;
        int dw = Math.Max(1, (int)Math.Round(box.Width * scale));
        int dh = Math.Max(1, (int)Math.Round(box.Height * scale));
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.DrawImage(sprite, new Rectangle(cell.X + (cell.Width - dw) / 2, cell.Y + (cell.Height - dh) / 2, dw, dh), box, GraphicsUnit.Pixel);
    }
}
"@

[PigPenisV2]::CoilSource = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\reference-Genitalia_screw_icon.png"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$preview = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\preview-PigPenis-v2.png"
[PigPenisV2]::Build($live, $preview)
$review = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\SizedApparel\BodyParts\Human\Penis"
if (Test-Path $review) { Remove-Item $review -Recurse -Force }
Copy-Item $live $review -Recurse
Write-Host "PREVIEW $preview"
Write-Host ("LIVE " + (Get-ChildItem $live -Recurse -Filter *.png).Count)
