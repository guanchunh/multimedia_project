% part1: Waveform

[data,fs]=audioread('voice.wav'); % read .wav file
% info=audioinfo("voicd.wav");
%data=data/abs(max(data)); % normalize data
%sound(data,fs);

figure;
t = [0 : 1/fs : length(data)/fs]; % time in sec
t = t(1:end - 1);

subplot(5,1,1);
plot(t,data);
title('Waveform');


% part2: Energy contour

% do framing
f_d=0.025;
frames = framing(data, fs, f_d);% it is like 0% overlap with rectangular window

% calculate frames energy
[r, c] = size(frames);
ste = 0;
for i = 1 : r
    ste(i)=sum(abs(frames(i,:)));
    %ste(i) = sum(frames(i,:).^2);
end

%ste = ste./max(ste); % normalize the data

f_size = round(f_d * fs); % how many samples in a frame
ste_wave = 0;
for j = 1 : length(ste)
    l = length(ste_wave);
    ste_wave(l : l + f_size) = ste(j);
end

% plot the STE with Signal
t = [0 : 1/fs : length(data)/fs]; % time in sec
t = t(1:end - 1);
t1 = [0 : 1/fs : length(ste_wave)/fs];
t1 = t1(1:end - 1);

subplot(5,1,2);
plot(t1,ste_wave,'r','LineWidth',1);
title('Energy contour');


% part3: Zero-crossing rate contour

x=frames(110,:);
ZCR = sum(abs(diff(x > 0)));
%[r, c] = size(frames); % finding ZCR of all frames

for i = 1 : r
    x = frames(i, :);
    ZCRf(i) = sum(abs(diff(x > 0)));
end

% calculating rate
ZCRr = ZCRf/length(x);
%ZCRr = ZCRr/max(ZCRr2);

zcr_wave = 0;
for j = 1 : length(ZCRr)
    l = length(zcr_wave);
    zcr_wave(l : l + f_size) = ZCRr(j);
end

% plot the ZCR with Signal
t1 = [0 : 1/fs : length(zcr_wave)/fs];
t1 = t1(1:end - 1);
subplot(5,1,3); 
plot(t1,zcr_wave*length(x),'r','LineWidth',1);
title('Zero-crossing rate contour');


% part5: Pitch contour

[f0,idx] = pitch(data,fs, ...
          'Method','PEF', ...
          'WindowLength',round(fs*0.08), ...
          'OverlapLength',round(fs*(0.08-0.01)), ...
          'Range',[60,1000], ...
          'MedianFilterLength',3);
%figure;      
t0 = (idx - 1)/fs;
subplot(5,1,5); 
plot(t0,f0,'r','LineWidth',1);
xlabel('time(s)');
title('Pitch contour');


%part4: End point detection

frameSize = 256;
overlap = 128;
y=data-mean(data);				% zero-mean substraction

frameMat=enframe(y, frameSize, overlap);	% frame blocking
frameNum=size(frameMat, 2);			% no. of frames

volume=frame2volume(frameMat);		% volume
volumeTh=median(volume)*6;			% volume threshold 

index = find(volume>volumeTh);
endPoint=frame2sampleIndex(index, frameSize, overlap);
subplot(5,1,4);


t=(1:length(y))/fs;
plot(t, y);
title('End Point Detection');
axis([-inf inf -1 1]);
line(t(endPoint(  1))*[1 1], [-1, 1], 'color', 'k');
line(t(endPoint(end))*[1 1], [-1, 1], 'color', 'k');



