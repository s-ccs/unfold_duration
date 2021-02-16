function sig = generate_signal_kernel(dur,shape,srate, harmonize)
start = 0.05*srate; 
stop = dur;
assert(stop>3*start,'signal duration is too short')

if ~harmonize
    eventsamples =round(start:stop);
else
    eventsamples =round(start:stop+(2*start));
end

sig = zeros(round(2*length(eventsamples)),1);

switch shape
    case "hanning"
        sig(eventsamples) = hanning(length(eventsamples));
    case "box"
        sig(eventsamples) = 1;
    case "posNeg"
        % 50ms posPeak, duration negPeak
        posSig = zeros(length(eventsamples),1);
        negSig = posSig;
        posSize= ceil(0.05*srate);%floor(length(eventsamples)/2);
        posSig(1:posSize) = hanning(posSize);
        negSig((posSize+1):end) = -hanning(length(eventsamples)-posSize);
        sig(eventsamples) = posSig + negSig;
    case "posNegPos"
        % 50ms posPeak, 50ms negPeak, 50ms Rising edge + duration
        % for the falling edge
        
        start = 0.05*srate; 
        stop = dur;
        
        eventsamples =round(start:stop+(2*start));
        sig = zeros(round(2*length(eventsamples)),1);

        
        posSig = sig;
        negSig = posSig;
        pos2Sig = posSig;
        constantPeakSize= ceil(0.05*srate);%floor(length(eventsamples)/2);
        posSig(start+1:(start+constantPeakSize)) = hanning(constantPeakSize);
        negSig(start+constantPeakSize+1:start+2*constantPeakSize) = -hanning(constantPeakSize);
        tmp = hanning(2*constantPeakSize);
        pos2Sig(start+2*constantPeakSize+1:start+3*constantPeakSize) = tmp(1:end/2);
        tmp = hanning(2*(length(eventsamples)-3*constantPeakSize));
        pos2Sig(start+3*constantPeakSize+1:start+(3*constantPeakSize+length(tmp)/2)) = tmp(end/2+1:end);
        sig = posSig + negSig + pos2Sig;
     
end