clear all
close all

a = timeLapse('sma.mp4',10);

w = [800 400 1960 1301];
wind = [w(1) w(2) w(3)-w(1) w(4)-w(2)];

a.setCurrentWindow(wind)
a.cropAll();

a.prepAlign(10,'cropped')
a.xcorrImage(100,'cropped')

figure(); contourf(a.xcorr'); pbaspect([size(a.reference,2) size(a.reference,1) 1]);
figure(); imshow(a.reference);
figure(); imshow(a.cropped);




% a.prepVideo(12);
% a.compileVideo('cropped');