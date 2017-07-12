# caffe2-segmentation-ios
## 性能测试
1. memory: ~70MB on iphone 7, ~42MB on itouch 6
2. speed w/o showing contour: ~22FPS@241x241 on iphone 7, ~8FPS@241x241 on itouch 6
3. time profiling: segmentation ~50%, draw contour ~25%, FG/BG fusion 23%, others 2%

## TODO
可以继续提速的部分：
1. 视频融合部分
2. 描边部分
3. caffe2.predict(.)中的多余check
