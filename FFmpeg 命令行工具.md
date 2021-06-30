# ffprobe
```
ffprobe test.mp3
```
    输出格式信息 format_name、 时间长度 duration、文件大小 size、 比特率
bit_rate、流的数目 nb_streams等。
```
ffprobe -show_format test.mp4
```
    以 JSON 格式的形式输出具体每一个流最详细的信息
```
ffprobe -print_format json -show_streams test2.mp4
```
    显示帧信息
```
ffprobe -show_frames test2.mp4
```
    查看包信息
```
ffprobe -show_packets test2.mp4
```

# ffmpeg
```
列出ffmpeg支持的所有格式
ffmpeg -formats
```

```
剪切一段媒体文件
ffmpeg -i test1.mp4 -ss 00:00:10.0 -codec copy -t 20 out1.map4
-ss 指定偏移时间( timeOffset), -t指定的时长( duration)
表示将文件test1.mp4从第10s开始剪切20s的时间，输出到out1.mp4

ffmpeg -i test1.mp4 -t 00:00:20 -c copy out1.mp4 -ss 00:00:20 -codec copy out2.mp4
```

    提取视频文件中的音频文件
```
ffmpeg -i test1.mp4 -vn -acodec copy out1.m4a
```

    使一个视频中的音频静音，只保留视频
```
ffmpeg -i test1.mp4 -an -vcodec copy out1.mp4
```
    从 MP4 文件中抽取视频流导出为裸 H264 数据:
```
ffmpeg -i test1.mp4 -an -vcodec copy -bsf:v h264_mp4toannexb out1.h264
```

    使用 AAC 音频数据和 H264 的视频生成 MP4 文件:
```
提取aac数据
ffmpeg -i test1.mp4 -vn -acodec copy out1.aac

提取h264数据
ffmpeg -i test1.mp4 -an -vcodec copy -bsf:v h264_mp4toannexb out1.h264

aac+h264 -> mp4
ffmpeg -i out1.aac -i out1.h264 -acodec copy -bsf:a aac_adtstoasc -vcodec copy -f mp4 out2.mp4
```

    将一个 MP4 格式的视频转换成为 gif格式的动图
```
ffmpeg -i test2.mp4 -vf scale=100:-1 -t 5 -r 10 image.gif
上述代码按照分辨比例不变 宽度改为 100 (使用 VideoFilter 的 scaleFilter)，帧率改为 10 (-r)，只处理前 5 秒钟(-t)的视频，生成 gif。
```

    将一个视频的画面部分生成图片
```
ffmpeg -i test2.mp4 -r 0.25 frames_%04d.png
每4秒钟截取一帧视频画面生成一张图片，生成的图片从frames 0001.png开 始一直递增下去
0.25 = 1.0 / 4
```

    使用一组图片可以组成一个 gif
```
ffmpeg -i frames_%04d.png -r 5 image.gif
```

    改变音频媒体文件的音量
```
ffmpeg -i test.wav -af 'volume=0.5' out.wav
```

    将两路声音合并
```
ffmpeg -i test1.mp3 -i test2.mp3 -filter_complex amix=inputs=2:duration=shortest out.mp3
```

    对声音进行变速
```
0.5倍速
ffmpeg -i test2.mp3 -filter_complex atempo=0.5 out.wav 
```

    视频添加水印
```
ffmpeg -i input.mp4 -vf "movie=logo.png[watermark];[in][watermark] overlay=main_w-overlay_w-10:main_h-overlay_h-10[out]" output.mp4

上述命令包含了几个内置参数， main_w 代表主视频宽度， overlay_w 代表水印宽度， main_h 代表主视频高度， overlay_h 代表水印高度 。
```