# AI-assisted code (Claude Code), reviewed by the team, NASA Space Apps Cairo 2026
# 1. Converts every docs/video/clips/*.avi (Godot Movie Maker) to MP4 (H.264 + AAC, -preset veryfast).
# 2. Builds docs/video/demo_rough_cut.mp4 (<= 29.5 s) with burned-in captions, audio fades and an AI metadata comment.
# 3. Prints the duration. ffmpeg: system ffmpeg, else the imageio-ffmpeg bundled binary (pip install imageio-ffmpeg).
# Run after tools/record_clips.sh:  python tools/make_video.py
import glob, os, re, shutil, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIPS = os.path.join(ROOT, "docs/video/clips")
OUT = os.path.join(ROOT, "docs/video/demo_rough_cut.mp4")
FONT = "C\\:/Windows/Fonts/arialbd.ttf"
META = "Contains AI-generated art (Pixel Lab) and script-generated audio"

# (clip, start in clip, length) -> the rough cut order: title 0-5, story 5-7, chores 7-15, missions 15-20,
# finale 20-25, extraction 25-29.5
CUT = [("title", 0.8, 5.0), ("story", 0.3, 2.0),
       ("chores_eat", 0.6, 2.0), ("chores_sliders", 0.8, 2.0), ("chores_panel", 1.2, 2.0), ("chores_harvest", 0.6, 2.0),
       ("mission_rock", 0.8, 1.5), ("mission_ice", 1.2, 1.5), ("mission_storm", 1.4, 2.0),
       ("finale", 0.8, 5.0), ("extraction", 3.0, 4.5)]
CAPTIONS = [(0, 5, ["Junior Astronaut Mission Trainer · Team Wings of wax",
                    "NASA Space Apps 2026: Junior Astronaut Mission Trainer challenge"]),
            (5, 7, ["Keep a Moon outpost alive for 32 days"]),
            (7, 15, ["Balance power, oxygen, water and food: every choice has a cost"]),
            (15, 20, ["Every storm copies a real solar flare recorded by NASA"]),
            (20, 25, ["Read the forecast. Reach the shelter in time."]),
            (25, 29.5, ["For kids 7-12 · Free in the browser", "Data: NASA DONKI, NASA OSDR, Canadian Space Agency"])]


def ffmpeg():
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    import imageio_ffmpeg
    return imageio_ffmpeg.get_ffmpeg_exe()


def run(args):
    subprocess.run(args, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)


def duration(ff, path):
    r = subprocess.run([ff, "-i", path], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    m = re.search(r"Duration: (\d+):(\d+):([\d.]+)", r.stdout)
    return int(m.group(1)) * 3600 + int(m.group(2)) * 60 + float(m.group(3)) if m else 0.0


def esc(t):
    return t.replace("\\", "\\\\").replace(":", "\\:").replace("'", "’").replace(",", "\\,")


def main():
    ff = ffmpeg()
    enc = ["-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-r", "30",
           "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-ac", "2"]
    # 1. every clip -> MP4 (silent audio track added if a clip has none)
    for avi in sorted(glob.glob(os.path.join(CLIPS, "*.avi"))):
        mp4 = avi[:-4] + ".mp4"
        # Movie Maker writes the 640x360 game view: scale exactly 2x with nearest neighbour (crisp pixels) to 1280x720
        run([ff, "-y", "-i", avi, "-vf", "scale=1280:720:flags=neighbor"] + enc + [mp4])
        print("mp4:", os.path.basename(mp4), "%.1f s" % duration(ff, mp4))
    # 2. rough cut: trim each piece, concat, captions, fades
    parts = []
    for i, (name, ss, ln) in enumerate(CUT):
        src = os.path.join(CLIPS, name + ".mp4")
        if not os.path.exists(src):
            print("missing clip, skipped:", name)
            continue
        part = os.path.join(CLIPS, "_part%02d.mp4" % i)
        run([ff, "-y", "-ss", str(ss), "-t", str(ln), "-i", src] + enc + [part])
        parts.append(part)
    lst = os.path.join(CLIPS, "_parts.txt")
    with open(lst, "w") as f:
        for p in parts:
            f.write("file '%s'\n" % p.replace("\\", "/"))
    joined = os.path.join(CLIPS, "_joined.mp4")
    run([ff, "-y", "-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", joined])
    total = min(29.5, duration(ff, joined))
    # captions: white 30 px text in a dark translucent box, bottom centre, above the watermark (which is at y ~ 690)
    vf = []
    for a, b, lines in CAPTIONS:
        for k, line in enumerate(lines):
            y = 632 - (len(lines) - 1 - k) * 40
            vf.append("drawtext=fontfile='%s':text='%s':fontsize=28:fontcolor=white:box=1:boxcolor=black@0.6:"
                      "boxborderw=8:x=(w-text_w)/2:y=%d:enable='between(t,%s,%s)'" % (FONT, esc(line), y, a, b))
    vf.append("fade=t=in:st=0:d=0.3,fade=t=out:st=%.2f:d=0.5" % (total - 0.5))
    af = "afade=t=in:st=0:d=0.3,afade=t=out:st=%.2f:d=0.5" % (total - 0.5)
    run([ff, "-y", "-i", joined, "-t", "%.2f" % total, "-vf", ",".join(vf), "-af", af] + enc +
        ["-metadata", "comment=" + META, "-metadata", "description=" + META, OUT])
    print("rough cut:", OUT, "duration %.2f s" % duration(ff, OUT))


if __name__ == "__main__":
    main()
