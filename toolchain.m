clear all
close all

a = timeLapse('raw30fps',30,0);

a.prepVideo();
a.compileVideo('file');

w = [840 1110 2500 2040];
wind = [w(1) w(2) w(3)-w(1) w(4)-w(2)];

a.setCurrentWindow(wind)
a.cropAll();

a.prepAlign(10,'cropped')
a.xcorrAll('cropped')

a.alignAll('cropped')

figure(); contourf(a.xcorr'); pbaspect([size(a.reference,2) size(a.reference,1) 1]);
figure(); imshow(a.reference);
figure(); imshow(a.cropped);




% a.prepVideo(12);
% a.compileVideo('cropped');