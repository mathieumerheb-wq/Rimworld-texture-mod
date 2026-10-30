# Previous PigPenis design. The tested PNGs are kept in ArtInventory/GeneratedPigPenis.
# Running this file does not write the live Textures folder.
# 512x512 RGBA, centered, transparent.
# Resting: bulky preputial sheath. Erect: 2-3 coil shaft, thicker with size, with a tip.
# Does not modify installed mods.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class PigPenisSprites
{
    static readonly Color Outline = Color.FromArgb(255, 12, 8, 10);
    static readonly Color FleshHi = Color.FromArgb(255, 255, 248, 246);
    static readonly Color Flesh = Color.FromArgb(255, 244, 214, 214);
    static readonly Color FleshShade = Color.FromArgb(255, 214, 156, 164);
    static readonly Color Groove = Color.FromArgb(255, 186, 112, 128);
    static readonly Color TipPink = Color.FromArgb(255, 228, 150, 162);
    static readonly Color BackHi = Color.FromArgb(255, 206, 164, 170);
    static readonly Color BackShade = Color.FromArgb(255, 148, 96, 110);
    static readonly Color SheathIn = Color.FromArgb(255, 112, 64, 78);

    public static void Build(string textureRoot, string previewPath)
    {
        string penis = Path.Combine(textureRoot, "Penis");
        string horny = Path.Combine(penis, "Horny");
        string balls = Path.Combine(penis, "Balls");
        Directory.CreateDirectory(penis);
        Directory.CreateDirectory(horny);
        Directory.CreateDirectory(balls);

        for (int size = 0; size <= 5; size++)
        {
            Save(DrawRestSouth(size), Path.Combine(penis, "PigPenis_" + size + "_south.png"));
            Save(DrawRestEast(size), Path.Combine(penis, "PigPenis_" + size + "_east.png"));
            Save(BlankNorth(), Path.Combine(penis, "PigPenis_" + size + "_north.png"));
            Save(DrawArousedSouth(size), Path.Combine(horny, "PigPenis_" + size + "_south.png"));
            Save(DrawArousedEast(size), Path.Combine(horny, "PigPenis_" + size + "_east.png"));
            Save(BlankNorth(), Path.Combine(horny, "PigPenis_" + size + "_north.png"));
            Save(DrawBalls(size, false), Path.Combine(balls, "PigPenis_" + size + "_south.png"));
            Save(DrawBalls(size, true), Path.Combine(balls, "PigPenis_" + size + "_east.png"));
            Save(DrawBalls(size, false), Path.Combine(balls, "PigPenis_" + size + "_north.png"));
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
        using (var g = Graphics.FromImage(bmp))
        {
            g.Clear(Color.Transparent);
        }
        return bmp;
    }

    static Graphics G(Bitmap bmp)
    {
        var g = Graphics.FromImage(bmp);
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.PixelOffsetMode = PixelOffsetMode.HighQuality;
        g.CompositingQuality = CompositingQuality.HighQuality;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        return g;
    }

    static Bitmap BlankNorth()
    {
        var bmp = new Bitmap(4, 4, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(bmp)) g.Clear(Color.Transparent);
        return bmp;
    }

    static Pen PenOf(float width)
    {
        var pen = new Pen(Outline, Math.Max(1.4f, width));
        pen.LineJoin = LineJoin.Round;
        pen.StartCap = LineCap.Round;
        pen.EndCap = LineCap.Round;
        return pen;
    }

    // Horse content-box curve, used only as the length and footprint target.
    static readonly float[] RestW = { 28, 28, 33, 40, 49, 58 };
    static readonly float[] RestH = { 23, 23, 32, 39, 52, 53 };
    static readonly float[] AroW = { 25, 25, 30, 39, 47, 59 };
    static readonly float[] AroH = { 52, 67, 92, 120, 147, 186 };

    sealed class HelixSample
    {
        public float X;
        public float Y;
        public float Z;
        public float T;
    }

    static void SheathSize(int size, out float length, out float bulk, out float stroke)
    {
        length = 40f + size * 9f;
        bulk = 34f + size * 8f;
        stroke = 1.85f + size * 0.28f;
    }

    static void ShaftSize(int size, out float tubeR, out float helixR, out float turns)
    {
        tubeR = 3.2f + size * 1.25f;
        helixR = 6.2f + size * 1.55f;
        turns = 2f + size * 0.2f;
    }

    static Bitmap DrawRestSouth(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp))
        {
            float length = 40f + size * 9f;
            DrawSheath(g, 256f, 270f - length * 0.52f, size, true);
        }
        return bmp;
    }

    static Bitmap DrawRestEast(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp))
        {
            float length = 40f + size * 9f;
            // Attachment stays at the crotch. The opening points right, same way as the erect tip.
            DrawSheath(g, 256f + length * 0.18f, 252f, size, false);
        }
        return bmp;
    }

    static Bitmap DrawArousedSouth(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp))
        {
            float tubeR, helixR, turns;
            ShaftSize(size, out tubeR, out helixR, out turns);
            float length = AroH[size];
            float glansH = Math.Min(length * 0.26f, Math.Max(13f, tubeR * 3.15f));
            float cx = 256f;
            // HorsePenis keeps the base on the crotch and grows the tip upward.
            float bottom = 266f;
            float top = bottom - length;
            float neck = top + glansH * 0.92f;
            float coilCy = (neck + bottom) * 0.5f;
            DrawRoot(g, cx, bottom, tubeR, true);
            DrawGlans(g, cx, top, glansH, tubeR * 1.75f, tubeR * 1.05f, true);
            DrawCorkscrew(g, cx, coilCy, bottom - neck, tubeR, helixR, turns, true);
        }
        return bmp;
    }

    static Bitmap DrawArousedEast(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp))
        {
            float tubeR, helixR, turns;
            ShaftSize(size, out tubeR, out helixR, out turns);
            float length = AroH[size] * 0.92f;
            float glansL = Math.Min(length * 0.26f, Math.Max(13f, tubeR * 3.15f));
            float cy = 248f;
            // HorsePenis east base is at the crotch and the tip points right. West mirrors this.
            float baseX = 250f;
            float tipX = baseX + length;
            float neck = tipX - glansL * 0.92f;
            float coilCx = (baseX + neck) * 0.5f;
            DrawRoot(g, baseX, cy, tubeR, false);
            DrawGlans(g, tipX, cy, glansL, tubeR * 1.75f, tubeR * 1.05f, false);
            DrawCorkscrew(g, coilCx, cy, neck - baseX, tubeR, helixR, turns, false);
        }
        return bmp;
    }

    static void DrawSheath(Graphics g, float cx, float cy, int size, bool front)
    {
        float length, bulk, stroke;
        SheathSize(size, out length, out bulk, out stroke);
        using (var path = front ? SheathFrontPath(cx, cy, bulk, length) : SheathSidePath(cx, cy, length, bulk))
        {
            RectangleF bounds = path.GetBounds();
            bounds.Inflate(2f, 2f);
            if (bounds.Width < 1f) bounds.Width = 1f;
            if (bounds.Height < 1f) bounds.Height = 1f;
            using (var brush = new LinearGradientBrush(bounds, FleshHi, FleshShade, front ? LinearGradientMode.Horizontal : LinearGradientMode.Vertical))
                g.FillPath(brush, path);
            using (var pen = PenOf(stroke))
                g.DrawPath(pen, path);
        }

        if (front)
        {
            var mouth = new RectangleF(cx - bulk * 0.15f, cy - length * 0.20f, bulk * 0.30f, length * 0.26f);
            using (var brush = new SolidBrush(SheathIn))
                g.FillEllipse(brush, mouth);
            using (var pen = PenOf(Math.Max(1.3f, stroke * 0.7f)))
            {
                g.DrawEllipse(pen, mouth);
                g.DrawArc(pen, cx - bulk * 0.30f, cy - length * 0.38f, bulk * 0.60f, length * 0.34f, 205f, 130f);
            }
            using (var pen = new Pen(Groove, Math.Max(1.1f, stroke * 0.4f)))
                g.DrawLine(pen, cx, mouth.Bottom - 1f, cx, cy + length * 0.16f);
        }
        else
        {
            float mouthW = bulk * 0.28f;
            float mouthH = bulk * 0.30f;
            var mouth = new RectangleF(cx + length * 0.50f - mouthW, cy - mouthH * 0.5f, mouthW, mouthH);
            using (var brush = new SolidBrush(SheathIn))
                g.FillEllipse(brush, mouth);
            using (var pen = PenOf(Math.Max(1.3f, stroke * 0.7f)))
                g.DrawEllipse(pen, mouth);
        }
    }

    static GraphicsPath SheathFrontPath(float cx, float cy, float width, float height)
    {
        var pts = new[] {
            new PointF(cx, cy - height * 0.46f),
            new PointF(cx + width * 0.32f, cy - height * 0.28f),
            new PointF(cx + width * 0.50f, cy + height * 0.02f),
            new PointF(cx + width * 0.44f, cy + height * 0.30f),
            new PointF(cx + width * 0.18f, cy + height * 0.48f),
            new PointF(cx, cy + height * 0.52f),
            new PointF(cx - width * 0.18f, cy + height * 0.48f),
            new PointF(cx - width * 0.44f, cy + height * 0.30f),
            new PointF(cx - width * 0.50f, cy + height * 0.02f),
            new PointF(cx - width * 0.32f, cy - height * 0.28f)
        };
        var path = new GraphicsPath();
        path.AddClosedCurve(pts, 0.52f);
        return path;
    }

    static GraphicsPath SheathSidePath(float cx, float cy, float length, float bulk)
    {
        var pts = new[] {
            new PointF(cx + length * 0.46f, cy - bulk * 0.06f),
            new PointF(cx + length * 0.20f, cy - bulk * 0.40f),
            new PointF(cx - length * 0.16f, cy - bulk * 0.48f),
            new PointF(cx - length * 0.46f, cy - bulk * 0.16f),
            new PointF(cx - length * 0.50f, cy + bulk * 0.18f),
            new PointF(cx - length * 0.18f, cy + bulk * 0.48f),
            new PointF(cx + length * 0.16f, cy + bulk * 0.40f),
            new PointF(cx + length * 0.44f, cy + bulk * 0.14f)
        };
        var path = new GraphicsPath();
        path.AddClosedCurve(pts, 0.55f);
        return path;
    }

    static void DrawRoot(Graphics g, float x, float y, float tubeR, bool vertical)
    {
        float along = tubeR * 1.7f;
        float across = tubeR * 2.35f;
        var rect = vertical
            ? new RectangleF(x - across, y - along, across * 2f, along * 2f)
            : new RectangleF(x - along, y - across, along * 2f, across * 2f);
        using (var brush = new LinearGradientBrush(rect, Flesh, FleshShade, vertical ? LinearGradientMode.Horizontal : LinearGradientMode.Vertical))
            g.FillEllipse(brush, rect);
        using (var pen = PenOf(Math.Max(1.5f, tubeR * 0.28f)))
            g.DrawEllipse(pen, rect);
    }

    static void DrawGlans(Graphics g, float tipX, float tipY, float length, float halfWidth, float neck, bool vertical)
    {
        using (var path = GlansPath(tipX, tipY, length, halfWidth, neck, vertical))
        {
            RectangleF bounds = path.GetBounds();
            bounds.Inflate(2f, 2f);
            if (bounds.Width < 1f) bounds.Width = 1f;
            if (bounds.Height < 1f) bounds.Height = 1f;
            using (var brush = new LinearGradientBrush(bounds, FleshHi, TipPink, vertical ? LinearGradientMode.Horizontal : LinearGradientMode.Vertical))
                g.FillPath(brush, path);
            using (var pen = PenOf(Math.Max(1.5f, neck * 0.28f)))
                g.DrawPath(pen, path);
        }
        using (var pen = new Pen(Groove, Math.Max(1.1f, neck * 0.22f)))
        {
            pen.StartCap = LineCap.Round;
            pen.EndCap = LineCap.Round;
            if (vertical)
                g.DrawLine(pen, tipX, tipY + length * 0.16f, tipX, tipY + length * 0.40f);
            else
                g.DrawLine(pen, tipX - length * 0.16f, tipY, tipX - length * 0.40f, tipY);
        }
    }

    static PointF GlansPoint(float tipX, float tipY, float along, float side, bool vertical)
    {
        if (vertical) return new PointF(tipX + side, tipY + along);
        return new PointF(tipX - along, tipY + side);
    }

    static GraphicsPath GlansPath(float tipX, float tipY, float length, float halfWidth, float neck, bool vertical)
    {
        var pts = new[] {
            GlansPoint(tipX, tipY, length, -neck, vertical),
            GlansPoint(tipX, tipY, length * 0.70f, -halfWidth, vertical),
            GlansPoint(tipX, tipY, length * 0.26f, -halfWidth * 0.62f, vertical),
            GlansPoint(tipX, tipY, 0.5f, 0f, vertical),
            GlansPoint(tipX, tipY, length * 0.26f, halfWidth * 0.62f, vertical),
            GlansPoint(tipX, tipY, length * 0.70f, halfWidth, vertical),
            GlansPoint(tipX, tipY, length, neck, vertical)
        };
        var path = new GraphicsPath();
        path.AddClosedCurve(pts, 0.42f);
        return path;
    }

    sealed class CoilSeg
    {
        public int A;
        public int B;
        public float Z;
    }

    // Coil shaft only. Vertical tip-end is up. Horizontal tip-end is right.
    // Turns are fixed at about 2 to 3. Thickness comes from the caller.
    static void DrawCorkscrew(Graphics g, float cx, float cy, float length, float tubeR, float helixR, float turns, bool vertical)
    {
        if (turns < 1.6f) turns = 1.6f;
        if (length < 8f) length = 8f;
        int count = Math.Max(48, (int)Math.Round(turns * 64f));
        var samples = new List<HelixSample>(count + 1);
        for (int i = 0; i <= count; i++)
        {
            float t = i / (float)count;
            float theta = (float)(Math.PI * 0.5 + (t - 1.0) * turns * Math.PI * 2.0);
            var s = new HelixSample();
            s.T = t;
            s.Z = (float)Math.Sin(theta);
            float coil = (float)Math.Cos(theta);
            if (vertical)
            {
                s.X = cx + helixR * coil;
                s.Y = (cy + length * 0.5f) - t * length;
            }
            else
            {
                s.X = (cx - length * 0.5f) + t * length;
                s.Y = cy + helixR * coil;
            }
            samples.Add(s);
        }

        var cuts = new List<int>();
        cuts.Add(0);
        for (int i = 1; i < samples.Count; i++)
        {
            if (samples[i - 1].Z * samples[i].Z < 0f) cuts.Add(i);
        }
        cuts.Add(samples.Count - 1);

        int overlap = Math.Max(4, count / Math.Max(8, (int)Math.Round(turns * 14f)));
        var segs = new List<CoilSeg>();
        for (int c = 0; c < cuts.Count - 1; c++)
        {
            int a = Math.Max(0, cuts[c] - (c == 0 ? 0 : overlap));
            int b = Math.Min(samples.Count - 1, cuts[c + 1] + (c == cuts.Count - 2 ? 0 : overlap));
            if (b - a < 2) continue;
            float z = 0f;
            int n = 0;
            for (int i = cuts[c]; i <= cuts[c + 1]; i++) { z += samples[i].Z; n++; }
            var seg = new CoilSeg();
            seg.A = a;
            seg.B = b;
            seg.Z = z / Math.Max(1, n);
            segs.Add(seg);
        }
        segs.Sort(delegate(CoilSeg a, CoilSeg b) { return a.Z.CompareTo(b.Z); });
        for (int i = 0; i < segs.Count; i++)
            StrokeCoil(g, samples, segs[i], tubeR, vertical);
    }

    static void StrokeCoil(Graphics g, List<HelixSample> samples, CoilSeg seg, float tubeR, bool vertical)
    {
        int len = seg.B - seg.A + 1;
        if (len < 2) return;
        var spine = new PointF[len];
        float hx = vertical ? -tubeR * 0.12f : -tubeR * 0.34f;
        float hy = vertical ? -tubeR * 0.34f : -tubeR * 0.1f;
        var lit = new PointF[len];
        for (int i = 0; i < len; i++)
        {
            HelixSample s = samples[seg.A + i];
            spine[i] = new PointF(s.X, s.Y);
            lit[i] = new PointF(s.X + hx, s.Y + hy);
        }

        bool front = seg.Z >= 0f;
        bool tip = samples[seg.B].T > 0.86f;
        bool roundStart = seg.A == 0;
        bool roundEnd = seg.B == samples.Count - 1;
        float diameter = tubeR * 2f;
        Color body = tip ? TipPink : (front ? Flesh : BackShade);
        Color edgeLight = front ? FleshHi : BackHi;

        using (var outline = TubePen(Outline, diameter + Math.Max(2.3f, tubeR * 0.85f), roundStart, roundEnd))
        using (var fill = TubePen(body, diameter, roundStart, roundEnd))
        using (var highlight = TubePen(edgeLight, Math.Max(1.15f, diameter * 0.42f), roundStart, roundEnd))
        {
            g.DrawLines(outline, spine);
            g.DrawLines(fill, spine);
            if (front) g.DrawLines(highlight, lit);
        }
    }

    static Pen TubePen(Color color, float width, bool roundStart, bool roundEnd)
    {
        var pen = new Pen(color, Math.Max(1f, width));
        pen.LineJoin = LineJoin.Round;
        pen.StartCap = roundStart ? LineCap.Round : LineCap.Flat;
        pen.EndCap = roundEnd ? LineCap.Round : LineCap.Flat;
        return pen;
    }

    static Bitmap DrawBalls(int size, bool side)
    {
        var bmp = Canvas();
        using (var g = G(bmp))
        {
            float s = 36f + size * 9f;
            float cx = 256f;
            float cy = 258f;
            float outline = 1.8f + size * 0.22f;
            if (!side)
            {
                var left = new RectangleF(cx - s * 0.72f, cy - s * 0.38f, s * 0.78f, s * 0.86f);
                var right = new RectangleF(cx - s * 0.06f, cy - s * 0.38f, s * 0.78f, s * 0.86f);
                var outer = new RectangleF(cx - s * 0.72f, cy - s * 0.46f, s * 1.44f, s * 0.96f);
                using (var brush = new LinearGradientBrush(outer, FleshHi, FleshShade, LinearGradientMode.Horizontal))
                {
                    g.FillEllipse(brush, left);
                    g.FillEllipse(brush, right);
                }
                using (var pen = PenOf(outline))
                {
                    g.DrawArc(pen, left, 90f, 180f);
                    g.DrawArc(pen, right, 270f, 180f);
                    g.DrawArc(pen, left, 200f, 80f);
                    g.DrawArc(pen, right, 260f, 80f);
                    g.DrawLine(pen, cx, cy - s * 0.22f, cx, cy + s * 0.18f);
                }
                using (var pen = new Pen(Groove, Math.Max(1.1f, outline * 0.4f)))
                    g.DrawLine(pen, cx, cy - s * 0.12f, cx, cy + s * 0.12f);
            }
            else
            {
                var body = new RectangleF(cx - s * 0.55f, cy - s * 0.48f, s * 1.05f, s * 0.95f);
                using (var brush = new LinearGradientBrush(body, FleshHi, FleshShade, LinearGradientMode.Vertical))
                    g.FillEllipse(brush, body);
                using (var pen = PenOf(outline))
                    g.DrawEllipse(pen, body);
                using (var pen = new Pen(Groove, Math.Max(1.1f, outline * 0.4f)))
                    g.DrawArc(pen, cx - s * 0.18f, cy - s * 0.12f, s * 0.36f, s * 0.4f, 200f, 140f);
            }
        }
        return bmp;
    }

    static void BuildPreview(string previewPath)
    {
        int cell = 168;
        int labelW = 70;
        int header = 48;
        int cols = 5;
        int rows = 6;
        int gap = 6;
        int width = 16 + labelW + cols * (cell + gap);
        int height = 16 + header + rows * (cell + gap) + 28;
        var frames = new Bitmap[rows, cols];
        int maxDim = 1;
        for (int size = 0; size <= 5; size++)
        {
            frames[size, 0] = DrawRestSouth(size);
            frames[size, 1] = DrawRestEast(size);
            frames[size, 2] = DrawArousedSouth(size);
            frames[size, 3] = DrawArousedEast(size);
            frames[size, 4] = DrawBalls(size, false);
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
            g.SmoothingMode = SmoothingMode.AntiAlias;
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;
            using (var title = new Font("Segoe UI", 13f, FontStyle.Bold))
            using (var small = new Font("Segoe UI", 8f))
            using (var white = new SolidBrush(Color.FromArgb(255, 236, 232, 220)))
            using (var muted = new SolidBrush(Color.FromArgb(255, 176, 172, 160)))
            {
                g.DrawString("PigPenis sheath and shaft", title, white, 14f, 8f);
                g.DrawString("Resting sheath. Erect shaft coils 2-3 times, thicker at larger sizes, with a tip. Shared scale.", small, muted, 14f, 30f);
                string[] headers = { "Rest south", "Rest east", "Aroused south", "Aroused east", "Balls south" };
                for (int c = 0; c < cols; c++)
                {
                    var rect = new RectangleF(16 + labelW + c * (cell + gap), header - 4, cell, 20);
                    using (var fmt = new StringFormat { Alignment = StringAlignment.Center })
                        g.DrawString(headers[c], small, white, rect, fmt);
                }
                for (int size = 0; size <= 5; size++)
                {
                    int y = header + 18 + size * (cell + gap);
                    g.DrawString("size " + size, small, white, 12f, y + cell * 0.45f);
                    for (int c = 0; c < cols; c++)
                    {
                        int x = 16 + labelW + c * (cell + gap);
                        DrawCell(g, frames[size, c], new Rectangle(x, y, cell, cell), shared);
                        frames[size, c].Dispose();
                    }
                }
                g.DrawString("512x512 RGBA, centered. North files stay blank.", small, muted, 14f, height - 22);
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
            int stride = data.Stride;
            int bytes = Math.Abs(stride) * sprite.Height;
            var buffer = new byte[bytes];
            System.Runtime.InteropServices.Marshal.Copy(data.Scan0, buffer, 0, bytes);
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
        finally
        {
            sprite.UnlockBits(data);
        }
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
        if (box.Width <= 0 || box.Height <= 0) return;
        int dw = Math.Max(1, (int)Math.Round(box.Width * scale));
        int dh = Math.Max(1, (int)Math.Round(box.Height * scale));
        int dx = cell.X + (cell.Width - dw) / 2;
        int dy = cell.Y + (cell.Height - dh) / 2;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.DrawImage(sprite, new Rectangle(dx, dy, dw, dh), box, GraphicsUnit.Pixel);
    }
}
"@

Write-Host "Previous generator left unused. Live textures come from Build-PigPenisV2.ps1. Archive: ArtInventory\GeneratedPigPenis"
