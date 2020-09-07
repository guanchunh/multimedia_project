function [f0,sampleStamp] = pitch(x, fs,varargin)

validateRequiredInputs(x,fs)

defaults = struct( ...
    'Method',            'NCF', ...
    'Range',             cast([50,400],'like',x), ...
    'WindowLength',      cast(round(fs.*0.052),'like',x), ...
    'OverlapLength',     cast(round(fs*(0.052-0.01)),'like',x), ...
    'MedianFilterLength',cast(1,'like',x), ...
    'SampleRate',        cast(fs,'like',x), ...
    'NumChannels',       cast(size(x,2),'like',x), ...
    'SamplesPerChannel', cast(size(x,1),'like',x));

params = matlabshared.fusionutils.internal.setProperties(defaults, nargin-2, varargin{:});

validateOptionalInputs(x,fs,params)

% Determine pitch
f0 = stepMethod(x,params);

% Create sample stamps corresponding to pitch decisions
hopLength   = params.WindowLength - params.OverlapLength;
numHops     = cast(floor((size(x,1)-params.WindowLength)/hopLength),'like',x);
sampleStamp = cast(((0:numHops)*hopLength + params.WindowLength)','like',x);

% Apply median filtering
if params.MedianFilterLength ~= 1
    f0 = movmedian(f0,params.MedianFilterLength,1);
end

% Trim off zero-padded last estimate
f0 = f0(1:(numHops+1),:);
end

% -------------------------------------------------------------------------
% Validate required inputs
% -------------------------------------------------------------------------
function validateRequiredInputs(x,fs)
validateattributes(x,{'single','double'}, ...
    {'nonempty','2d','real','nonnan','finite'}, ...
    'pitch','audioIn')
validateattributes(fs,{'single','double'}, ...
    {'nonempty','positive','scalar','real','nonnan','finite'}, ...
    'pitch','fs')
end

% -------------------------------------------------------------------------
% Validate optional input
% -------------------------------------------------------------------------
function validateOptionalInputs(x,fs,userInput)
N = size(x,1);
validateattributes(userInput.Range,{'single','double'}, ...
    {'nonempty','increasing','positive','row','ncols',2,'real'}, ...
    'pitch','Range')

coder.internal.errorIf(userInput.WindowLength < 1, ...
    'audio:pitch:BadWindowLength', ...
    'WINDOWLENGTH','[1,size(x,1)]','x','round(fs*0.052)');

validateattributes(userInput.WindowLength,{'single','double'}, ...
    {'nonempty','integer','positive','scalar','real','<=',192000}, ...
    'pitch','WindowLength')
validateattributes(userInput.OverlapLength,{'single','double'}, ...
    {'nonempty','integer','scalar','real'}, ...
    'pitch','OverlapLength')
validateattributes(userInput.MedianFilterLength,{'single','double'}, ...
    {'nonempty','integer','positive','scalar','real'}, ...
    'pitch','MedianFilterLength')

coder.internal.errorIf(sum(strcmp(userInput.Method,{'NCF','PEF','CEP','LHS','SRH'}))~=1, ...
    'audio:pitch:BadMethod', ...
    'NCF','PEF','CEP','LHS','SRH');
coder.internal.errorIf(userInput.WindowLength > N, ...
    'audio:pitch:BadWindowLength', ...
    'WINDOWLENGTH','[1,size(x,1)]','x','round(fs*0.052)');
coder.internal.errorIf(userInput.OverlapLength >= userInput.WindowLength, ...
    'audio:pitch:BadOverlapLength', ...
    'OVERLAPLENGTH', 'WINDOWLENGTH');

switch userInput.Method
    case 'NCF'
        coder.internal.errorIf(fs/userInput.Range(1) >= userInput.WindowLength, ...
            'audio:pitch:BadSpecifications', ...
            'NCF','fs/RANGE(1) < WINDOWLENGTH');
        coder.internal.errorIf(fs/2<userInput.Range(2), ...
            'audio:pitch:BadSpecifications', ...
            'NCF','fs/2 >= RANGE(2)');
    case 'PEF'
        coder.internal.errorIf((userInput.Range(1)<=10) || (userInput.Range(2)>=min(4000,fs/2)), ...
            'audio:pitch:BadSpecifications', ...
            'PEF','RANGE(1) > 10 && RANGE(2) < min(4000,fs/2)');
    case 'CEP'
        coder.internal.errorIf((userInput.Range(2)>=fs/2), ...
            'audio:pitch:BadSpecifications', ...
            userInput.Method,'RANGE(2) < fs/2');
        coder.internal.errorIf(round(fs/userInput.Range(1))>2^nextpow2(2*userInput.WindowLength-1), ...
            'audio:pitch:BadSpecifications', ...
            userInput.Method,'round(fs/RANGE(1)) <= 2^nextpow2(2*WINDOWLENGTH-1)');
    case 'LHS'
        coder.internal.errorIf(((userInput.Range(2)+1)*5>=fs), ...
            'audio:pitch:BadSpecifications', ...
            userInput.Method,'(RANGE(2)+1)*5 < fs');
    case 'SRH'
        coder.internal.errorIf(((userInput.Range(2)+1)*5>=fs), ...
            'audio:pitch:BadSpecifications', ...
            userInput.Method,'(RANGE(2)+1)*5 < fs');
end
% -------------------------------------------------------------------------
end

function f0 = stepMethod(x,params)
oneCast = cast(1,'like',x);
r       = cast(size(x,1),'like',x);
c       = cast(size(x,2),'like',x);
hopLength = params.WindowLength - params.OverlapLength;

numHopsFinal = ceil((r-params.WindowLength)/hopLength) + oneCast;

% The SRH method uses a fixed-size intermediate window and hop
% length to determine the residual signal.
if isequal(params.Method,'SRH')
    N       = round(cast(0.025*params.SampleRate,'like',x));
    hopSize = round(cast(0.005*params.SampleRate,'like',x));
else
    N       = cast(params.WindowLength,'like',x);
    hopSize = cast(hopLength,'like',x);
end
numHops = ceil((r-N)/hopSize) + oneCast;

% Convert to matrix for faster processing
y = zeros(N,numHops*c,'like',x);
for channel = 1:c
    for hop = 1:numHops
        temp = x(1+hopSize*(hop-1):min(N+hopSize*(hop-1),r),channel);
        y(1:min(N,numel(temp)),hop+(channel-1)*numHops) = temp;
    end
end

% Run pitch detection algorithm
extraParams = struct('NumCandidates',1,'MinPeakDistance',1);
switch params.Method
    case 'SRH'
        f0 = audio.internal.pitch.SRH(y,params,extraParams);
    case 'PEF'
        f0 = audio.internal.pitch.PEF(y,params,extraParams);
    case 'CEP'
        f0 = audio.internal.pitch.CEP(y,params,extraParams);
    case 'LHS'
        f0 = audio.internal.pitch.LHS(y,params,extraParams);
    otherwise %'NCF'
        f0 = audio.internal.pitch.NCF(y,params,extraParams);
end

% Force pitch estimate inside band edges
bE = params.Range;
f0(f0<bE(1))   = bE(1);
f0(f0>bE(end)) = bE(end);

% Reshape to multichannel
f0 = reshape(f0,numHopsFinal,c);
end