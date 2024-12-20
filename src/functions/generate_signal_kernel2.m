function sig = generate_signal_kernel2(dur,shape,srate, harmonize,rNoise, scaling)
start = 0; %0.05*srate; 
stop = dur; % In samples
% assert(stop>3*start,'signal duration is too short')

%% Should shapes be harmonized?
if ~harmonize
    eventsamples =round(start:stop);
else
    eventsamples =round(start:stop+(2*start));
end

sig = zeros(round(2*length(eventsamples)),1);


%% Is real noise used?
if ~rNoise
    multiplier = 1;
else
    multiplier = 10;
end
%% Make kernel
switch shape
    case "hanning"
        sig(eventsamples) = hanning(length(eventsamples));
        sig = sig .* multiplier;
        
    case "scaledHanning"
        sig(eventsamples) = hanning(length(eventsamples));
        sig = sig .* scaling;
        sig = sig .* multiplier;
        
    case "posHalf"
%         posSig = sig;
%         pos2Sig = posSig;
        constantPeakSize= ceil(0.30*srate);%floor(length(eventsamples)/2);
        
        % Constant first half
        tmp1 = hanning(constantPeakSize);
%         posSig(start+1:(start+constantPeakSize/2)) = tmp1(1:end/2);
        % Changing second half
%         tmp2 = hanning(2*(length(eventsamples)-constantPeakSize/2));
%         pos2Sig(start+constantPeakSize/2+1:start+(constantPeakSize/2+length(tmp)/2)) = tmp(end/2+1:end);
        tmp2 = hanning(length(eventsamples));
%         pos2Sig(start+constantPeakSize/2+1:start+(constantPeakSize/2+length(tmp2)/2)) = tmp2(end/2+1:end);
        
%         sig = posSig + pos2Sig;
        sig = vertcat(tmp1(1:ceil(end/2)), tmp2(ceil(end/2)+1:end));
        sig = sig .* multiplier;
        
    case "box"
        sig(eventsamples) = 1;
        sig = sig .* multiplier;
        
    case "posNeg"
        % 50ms posPeak, duration negPeak
        posSig = zeros(length(eventsamples),1);
        negSig = posSig;
        posSize= ceil(0.05*srate);%floor(length(eventsamples)/2);
        posSig(1:posSize) = hanning(posSize);
        negSig((posSize+1):end) = -hanning(length(eventsamples)-posSize);
        sig(eventsamples) = posSig + negSig;
        sig = sig .* multiplier;
        
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
        sig = sig .* multiplier;
        
     
end