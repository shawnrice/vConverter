vConverter
=========

A simple application put together with...
* ffmpeg
* Pashua
* Platypus
* Sox
* avconvert
* And a lot of bash scripting...

To convert and combine video files, also allowing for lightening videos and noise reduction.

Right now it doesn't provide much user feedback, but CocoaDialog is included, and I have the idea
to include progress bars for better information. There are a few unused scripts as well to help with
CD progress bars and ffmpeg progress tracking. I haven't included these yet due to lack of time.

I still need to test out the workflow with other video types. It seems to fail, currently, with AVCHD
because it needs to extract the `mts` file and then convert it so that `avconvert` can deal with it.

Still need to test that on many different levels.