mex -L/usr/local/lib -lqhyccd -outdir .  -I../headers -ULINUX qhyccdmex.cpp
tic
ImgDat = qhyccdmex;
toc
imshow(ImgDat);
clear qhyccdmex;
