function sampleIndex=frame2sampleIndex(frameIndex, frameSize, overlap)

sampleIndex=(frameIndex-1)*(frameSize-overlap)+round(frameSize/2);

end