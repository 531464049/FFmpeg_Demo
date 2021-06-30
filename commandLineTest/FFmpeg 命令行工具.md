# ffprobe
## ffprobe查看一个音频的文件
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