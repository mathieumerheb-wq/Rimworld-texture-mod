# CloacalPenis sprites. Rest is a closed slit. Aroused is the gene icon emerging from an open slit.
# CloacalPenis is not in BodypartDetail_Penis.xml, so the filenames have no variation suffix.
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class CloacalPenis
{
    static readonly Color FleshHi = Color.FromArgb(255, 232, 206, 200);
    static readonly Color Flesh = Color.FromArgb(255, 206, 164, 158);
    static readonly Color FleshShade = Color.FromArgb(255, 158, 110, 106);
    static readonly Color Cleft = Color.FromArgb(255, 42, 14, 18);
    static readonly Color Inner = Color.FromArgb(255, 168, 48, 52);
    static readonly Color Rim = Color.FromArgb(255, 92, 28, 32);
    static readonly Color Edge = Color.FromArgb(255, 28, 10, 12);

    public static string OrganSource;
    static Bitmap OrganBmp;
    static PointF OrganBase;
    static float OrganLen;
    static float OrganAngle;

    public static void Build(string penisRoot, string previewPath)
    {
        string horny = Path.Combine(penisRoot, "Horny");
        string balls = Path.Combine(penisRoot, "Balls");
        Directory.CreateDirectory(penisRoot);
        Directory.CreateDirectory(horny);
        Directory.CreateDirectory(balls);
        for (int size = 0; size <= 5; size++)
        {
            Save(DrawRestSouth(size), Path.Combine(penisRoot, "CloacalPenis_" + size + "_south.png"));
            Save(DrawRestEast(size), Path.Combine(penisRoot, "CloacalPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(penisRoot, "CloacalPenis_" + size + "_north.png"));
            Save(DrawArousedSouth(size), Path.Combine(horny, "CloacalPenis_" + size + "_south.png"));
            Save(DrawArousedEast(size), Path.Combine(horny, "CloacalPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(horny, "CloacalPenis_" + size + "_north.png"));
            Save(Blank(), Path.Combine(balls, "CloacalPenis_" + size + "_south.png"));
            Save(Blank(), Path.Combine(balls, "CloacalPenis_" + size + "_east.png"));
            Save(Blank(), Path.Combine(balls, "CloacalPenis_" + size + "_north.png"));
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
        var pen = new Pen(color, Math.Max(1.1f, width));
        pen.LineJoin = LineJoin.Round;
        pen.StartCap = LineCap.Round;
        pen.EndCap = LineCap.Round;
        return pen;
    }

    static bool Opaque(Color c)
    {
        return c.A >= 16;
    }

    static void LoadOrgan()
    {
        if (OrganBmp != null) return;
        using (var src = new Bitmap(OrganSource))
        {
            int minX = src.Width, minY = src.Height, maxX = -1, maxY = -1;
            for (int y = 0; y < src.Height; y++)
            for (int x = 0; x < src.Width; x++)
            {
                if (!Opaque(src.GetPixel(x, y))) continue;
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }
            int w = maxX - minX + 1;
            int h = maxY - minY + 1;
            OrganBmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            float bx = 0f, by = 0f, bn = 0f, tx = 0f, ty = 0f, tn = 0f;
            for (int y = minY; y <= maxY; y++)
            for (int x = minX; x <= maxX; x++)
            {
                Color c = src.GetPixel(x, y);
                if (!Opaque(c)) continue;
                int lx = x - minX;
                int ly = y - minY;
                OrganBmp.SetPixel(lx, ly, c);
                if (lx < 48) { bx += lx; by += ly; bn++; }
                if (lx > w - 28) { tx += lx; ty += ly; tn++; }
            }
            OrganBase = new PointF(bx / bn, by / bn);
            var tip = new PointF(tx / tn, ty / tn);
            float dx = tip.X - OrganBase.X;
            float dy = tip.Y - OrganBase.Y;
            OrganLen = (float)Math.Sqrt(dx * dx + dy * dy);
            OrganAngle = (float)(Math.Atan2(-dy, dx) * 180.0 / Math.PI);
            Console.WriteLine("ORGAN len=" + OrganLen.ToString("0.0") + " angle=" + OrganAngle.ToString("0.0"));
        }
    }

    static void DrawOrgan(Graphics g, float destX, float destY, float angleDeg, float scale)
    {
        LoadOrgan();
        var state = g.Save();
        g.TranslateTransform(destX, destY);
        g.RotateTransform(OrganAngle - angleDeg);
        g.ScaleTransform(scale, scale);
        g.TranslateTransform(-OrganBase.X, -OrganBase.Y);
        var old = g.InterpolationMode;
        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
        g.DrawImage(OrganBmp, 0, 0);
        g.InterpolationMode = old;
        g.Restore(state);
    }

    static void FillFlesh(Graphics g, GraphicsPath path)
    {
        RectangleF bounds = path.GetBounds();
        bounds.Inflate(2f, 2f);
        using (var brush = new LinearGradientBrush(bounds, FleshHi, FleshShade, LinearGradientMode.Vertical))
        {
            var blend = new ColorBlend(3);
            blend.Colors = new Color[] { FleshHi, Flesh, FleshShade };
            blend.Positions = new float[] { 0f, 0.45f, 1f };
            brush.InterpolationColors = blend;
            g.FillPath(brush, path);
        }
    }

    static void DrawClosedSouth(Graphics g, int size)
    {
        float w = 20f + size * 2.2f;
        float h = 18f + size * 1.5f;
        float cx = 256f;
        float cy = 250f;
        var mound = new RectangleF(cx - w * 0.5f, cy - h * 0.42f, w, h);
        using (var path = new GraphicsPath())
        {
            path.AddEllipse(mound);
            FillFlesh(g, path);
            using (var pen = Line(Edge, Math.Max(1.4f, w * 0.06f)))
                g.DrawPath(pen, path);
        }
        var cleft = new RectangleF(cx - w * 0.11f, cy - h * 0.28f, w * 0.22f, h * 0.62f);
        using (var brush = new SolidBrush(Cleft))
            g.FillEllipse(brush, cleft);
        using (var pen = Line(Inner, Math.Max(1.2f, w * 0.045f)))
            g.DrawLine(pen, cx, cleft.Top + cleft.Height * 0.18f, cx, cleft.Bottom - cleft.Height * 0.16f);
    }

    static void DrawClosedEast(Graphics g, int size)
    {
        float w = 12f + size * 1.3f;
        float h = 16f + size * 1.8f;
        float cx = 250f;
        float cy = 250f;
        var mound = new RectangleF(cx - w * 0.35f, cy - h * 0.5f, w, h);
        using (var path = new GraphicsPath())
        {
            path.AddEllipse(mound);
            FillFlesh(g, path);
            using (var pen = Line(Edge, Math.Max(1.3f, h * 0.07f)))
                g.DrawPath(pen, path);
        }
        using (var pen = Line(Cleft, Math.Max(1.6f, w * 0.16f)))
            g.DrawLine(pen, mound.Right - w * 0.28f, cy - h * 0.22f, mound.Right - w * 0.28f, cy + h * 0.22f);
    }

    static float OrganWidth(float frac)
    {
        LoadOrgan();
        float ang = OrganAngle * (float)Math.PI / 180f;
        float ax = (float)Math.Cos(ang);
        float ay = -(float)Math.Sin(ang);
        float px = (float)Math.Sin(ang);
        float py = (float)Math.Cos(ang);
        float ox = OrganBase.X + ax * OrganLen * frac;
        float oy = OrganBase.Y + ay * OrganLen * frac;
        float reach = 0f;
        for (int sign = -1; sign <= 1; sign += 2)
        {
            for (float d = 0f; d < 90f; d += 1f)
            {
                int sx = (int)Math.Round(ox + px * d * sign);
                int sy = (int)Math.Round(oy + py * d * sign);
                if (sx < 0 || sy < 0 || sx >= OrganBmp.Width || sy >= OrganBmp.Height || !Opaque(OrganBmp.GetPixel(sx, sy)))
                {
                    reach += Math.Max(0f, d - 1f);
                    break;
                }
            }
        }
        return Math.Max(8f, reach);
    }

    static void DrawOpenSlit(Graphics g, RectangleF cover, RectangleF mouth)
    {
        using (var hole = new GraphicsPath())
        {
            hole.AddEllipse(mouth);
            g.SetClip(hole, CombineMode.Exclude);
            using (var path = new GraphicsPath())
            {
                path.AddEllipse(cover);
                FillFlesh(g, path);
                using (var pen = Line(Edge, Math.Max(1.4f, Math.Min(cover.Width, cover.Height) * 0.09f)))
                    g.DrawEllipse(pen, cover);
            }
            g.ResetClip();
        }
    }

    static RectangleF BaseBounds(float destX, float destY, float angleDeg, float scale, bool east)
    {
        using (var bmp = new Bitmap(512, 512, PixelFormat.Format32bppArgb))
        {
            using (var probe = G(bmp))
                DrawOrgan(probe, destX, destY, angleDeg, scale);
            int minX = 512, minY = 512, maxX = -1, maxY = -1;
            for (int y = 0; y < bmp.Height; y++)
            for (int x = 0; x < bmp.Width; x++)
            {
                if (bmp.GetPixel(x, y).A < 16) continue;
                if (x < minX) minX = x;
                if (y < minY) minY = y;
                if (x > maxX) maxX = x;
                if (y > maxY) maxY = y;
            }
            if (maxX < 0) return new RectangleF(destX - 6f, destY - 6f, 12f, 12f);
            int bMinX = 512, bMinY = 512, bMaxX = -1, bMaxY = -1;
            int span = east ? maxX - minX : maxY - minY;
            int reach = Math.Max(6, (int)(span * 0.34f));
            for (int y = 0; y < bmp.Height; y++)
            for (int x = 0; x < bmp.Width; x++)
            {
                if (bmp.GetPixel(x, y).A < 16) continue;
                if (!east && y < maxY - reach) continue;
                if (east && x > minX + reach) continue;
                if (x < bMinX) bMinX = x;
                if (y < bMinY) bMinY = y;
                if (x > bMaxX) bMaxX = x;
                if (y > bMaxY) bMaxY = y;
            }
            return RectangleF.FromLTRB(bMinX, bMinY, bMaxX + 1, bMaxY + 1);
        }
    }

    static void DrawEmerging(Graphics g, int size, bool east)
    {
        LoadOrgan();
        float baseFrac = 0.34f;
        float baseW = 18f + size * 4.4f;
        float scale = baseW / OrganWidth(baseFrac);
        float bury = OrganLen * scale * baseFrac;
        float angle = east ? 28f : 90f;
        double rad = angle * Math.PI / 180.0;
        float ux = (float)Math.Cos(rad);
        float uy = -(float)Math.Sin(rad);
        float rootX = east ? 252f : 256f;
        float rootY = 250f;
        float destX = rootX - ux * bury;
        float destY = rootY - uy * bury;
        RectangleF raw = BaseBounds(destX, destY, angle, scale, east);
        float tuck = Math.Max(2.4f, Math.Min(raw.Width, raw.Height) * 0.07f);
        RectangleF mouth = RectangleF.Inflate(raw, -tuck, -tuck);
        if (mouth.Width < 4f || mouth.Height < 4f) mouth = raw;
        float lip = Math.Max(3.2f, Math.Min(mouth.Width, mouth.Height) * 0.14f);
        RectangleF cover = east
            ? new RectangleF(mouth.X - lip * 1.6f, mouth.Y - lip, mouth.Width * 0.62f + lip * 1.6f, mouth.Height + lip * 2f)
            : new RectangleF(mouth.X - lip, mouth.Y - lip * 0.25f, mouth.Width + lip * 2f, mouth.Height + lip * 1.15f);
        DrawOrgan(g, destX, destY, angle, scale);
        DrawOpenSlit(g, cover, mouth);
    }

    static Bitmap DrawRestSouth(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp)) DrawClosedSouth(g, size);
        return bmp;
    }

    static Bitmap DrawRestEast(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp)) DrawClosedEast(g, size);
        return bmp;
    }

    static Bitmap DrawArousedSouth(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp)) DrawEmerging(g, size, false);
        return bmp;
    }

    static Bitmap DrawArousedEast(int size)
    {
        var bmp = Canvas();
        using (var g = G(bmp)) DrawEmerging(g, size, true);
        return bmp;
    }

    static Rectangle ContentBox(Bitmap bmp)
    {
        int minX = bmp.Width, minY = bmp.Height, maxX = -1, maxY = -1;
        for (int y = 0; y < bmp.Height; y++)
        for (int x = 0; x < bmp.Width; x++)
        {
            if (bmp.GetPixel(x, y).A < 12) continue;
            if (x < minX) minX = x;
            if (y < minY) minY = y;
            if (x > maxX) maxX = x;
            if (y > maxY) maxY = y;
        }
        if (maxX < 0) return new Rectangle(0, 0, 1, 1);
        return Rectangle.FromLTRB(minX, minY, maxX + 1, maxY + 1);
    }

    static void BuildPreview(string previewPath)
    {
        int cell = 150;
        int labelW = 58;
        int header = 36;
        int cols = 4;
        int rows = 6;
        int gap = 6;
        int width = 16 + labelW + cols * (cell + gap);
        int height = 16 + header + rows * (cell + gap) + 8;
        var frames = new Bitmap[rows, cols];
        int maxDim = 1;
        for (int size = 0; size <= 5; size++)
        {
            frames[size, 0] = DrawRestSouth(size);
            frames[size, 1] = DrawRestEast(size);
            frames[size, 2] = DrawArousedSouth(size);
            frames[size, 3] = DrawArousedEast(size);
            for (int c = 0; c < cols; c++)
            {
                Rectangle box = ContentBox(frames[size, c]);
                if (box.Width > maxDim) maxDim = box.Width;
                if (box.Height > maxDim) maxDim = box.Height;
            }
        }
        float fit = (cell - 10f) / maxDim;
        var sheet = new Bitmap(width, height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(sheet))
        {
            g.Clear(Color.FromArgb(255, 28, 28, 32));
            g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;
            using (var font = new Font("Segoe UI", 11f, FontStyle.Bold))
            using (var small = new Font("Segoe UI", 8f))
            using (var white = new SolidBrush(Color.White))
            using (var dim = new SolidBrush(Color.FromArgb(255, 180, 180, 186)))
            {
                g.DrawString("CloacalPenis", font, white, new RectangleF(12f, 8f, width, 20f));
                string[] heads = { "Rest south", "Rest east", "Aroused south", "Aroused east" };
                for (int c = 0; c < cols; c++)
                    g.DrawString(heads[c], small, dim, new RectangleF(16 + labelW + c * (cell + gap), 22f, cell, 16f));
                for (int size = 0; size <= 5; size++)
                {
                    float top = 16 + header + size * (cell + gap);
                    g.DrawString("size " + size, small, dim, new RectangleF(8f, top + cell * 0.4f, labelW, 16f));
                    for (int c = 0; c < cols; c++)
                    {
                        Rectangle box = ContentBox(frames[size, c]);
                        float dw = box.Width * fit;
                        float dh = box.Height * fit;
                        float dx = 16 + labelW + c * (cell + gap) + (cell - dw) * 0.5f;
                        float dy = top + (cell - dh) * 0.5f;
                        g.DrawImage(frames[size, c], new RectangleF(dx, dy, dw, dh), box, GraphicsUnit.Pixel);
                        frames[size, c].Dispose();
                    }
                }
            }
        }
        sheet.Save(previewPath, ImageFormat.Png);
        sheet.Dispose();
    }
}
'@

[CloacalPenis]::OrganSource = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\reference-Genitalia_croc_icon.png"
$live = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\Textures\SizedApparel\BodyParts\Human\Penis"
$preview = "C:\Users\mathi\Documents\Rimworld new mods\mods\RJWAnimalTextures\ArtInventory\TextureV2\preview-CloacalPenis.png"
[CloacalPenis]::Build($live, $preview)
Write-Host "PREVIEW $preview"
Write-Host ("LIVE " + (Get-ChildItem $live -Recurse -Filter "CloacalPenis_*.png").Count)
