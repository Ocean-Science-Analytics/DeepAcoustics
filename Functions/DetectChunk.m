% --- Method for detecting calls in an image length worth of audio
function  [nbboxes, scores, Class] = DetectChunk(fr,ti,pow,network)

% Create standardized image input for network
pow(pow==0)=.01;
pow = log10(pow);
pow = rescale(imcomplement(abs(pow)));

% Create Adjusted Image for Identification
xTile=ceil(size(pow,1)/50);
yTile=ceil(size(pow,2)/50);
if xTile>1 && yTile>1
    im = adapthisteq(flipud(pow),'NumTiles',[xTile yTile],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);
else
    im = adapthisteq(flipud(pow),'NumTiles',[2 2],'ClipLimit',.005,'Distribution','rayleigh','Alpha',.4);    
end

if size(network.detector.InputSize,2) == 3
    map = gray(256);
    im = ind2rgb(im2uint8(im),map);
end

% Detect!
[bboxes, scores, Class] = detect(network.detector, im, 'ExecutionEnvironment','auto','SelectStrongest',1);

% Convert bboxes to ints (I'm not sure why they're not...)
nbboxes = int16(bboxes);
% Check bbox limits
% No zeros (must be at least 1)
nbboxes(nbboxes<=0) = 1;
% start time index must be at least 1 less than length of ti-1
nbboxes(nbboxes(:,1) > length(ti)-2,1) = length(ti)-2;
% 3+1 = right edge of box needs to be <= length(ti) (right edge of image)
nbboxes((nbboxes(:,3)+nbboxes(:,1)) >= length(ti),3) = length(ti)-1-nbboxes((nbboxes(:,3)+nbboxes(:,1)) >= length(ti),1);
% start freq index must be at least 1 less than length of fr-1
nbboxes(nbboxes(:,2) > length(fr)-2,2) = length(fr)-2;
% 4+2 = bottom edge of box needs to be <= length(fr) (bottom edge of image)
nbboxes((nbboxes(:,4)+nbboxes(:,2)) >= length(fr),4) = length(fr)-1-nbboxes((nbboxes(:,4)+nbboxes(:,2)) >= length(fr),2);