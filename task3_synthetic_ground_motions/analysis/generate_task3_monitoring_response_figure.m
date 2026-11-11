function paths = generate_task3_monitoring_response_figure(outputDir)
%GENERATE_TASK3_MONITORING_RESPONSE_FIGURE Task 3-specific model composite.
% Amin's clean engineering redraw is used as the visual source. The marker
% layer is rebuilt from the Task 2 DWG so that the plate contains the ten
% documented response-extraction locations and no spurious foundation points.

analysisDir = fileparts(mfilename('fullpath'));
root = fileparts(analysisDir);
sourceDir = fullfile(analysisDir,'figure_sources');
if nargin < 1 || isempty(outputDir)
    cfg = task3_config(root);
    outputDir = fullfile(cfg.output_root,'compact_pointwise_fmrvr');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end

plate = imread(fullfile(sourceDir,'amin_cross_section_without_callouts.png'));
plate = remove_source_markers(plate);
[plate,rowOffset,colOffset] = trim_uniform_border(plate,248);
plate = recolor_task3_materials(plate);

f = figure('Visible','off','Color','w','Position',[40 40 1500 1120]);
ax = axes(f,'Position',[0.015 0.015 0.97 0.97]);
image(ax,plate); axis(ax,'image','off');
draw_monitoring_points(ax,rowOffset,colOffset,'task3');

paths.png = fullfile(outputDir,'task3_monitoring_response_composite.png');
paths.pdf = fullfile(outputDir,'task3_monitoring_response_composite.pdf');
exportgraphics(f,paths.png,'Resolution',300);
exportgraphics(f,paths.pdf,'ContentType','image');
close(f);
end

function recolored = recolor_task3_materials(imageData)
% Apply a DWG-consistent natural palette to the section and its legend.
% Hue and saturation distinguish the source fills; the monitoring markers
% are drawn afterward and therefore retain the Task 3 teal identity.
rgb = im2double(imageData);
hsvImage = rgb2hsv(rgb);
h = hsvImage(:,:,1); s = hsvImage(:,:,2); v = hsvImage(:,:,3);
colored = s > 0.08 & v > 0.28;
[nRows,nCols,~] = size(rgb);
rowFraction = repmat((1:nRows)'/nRows,1,nCols);
columnFraction = repmat((1:nCols)/nCols,nRows,1);

shell = colored & h >= 0.055 & h <= 0.16 & s < 0.42;
groutColor = colored & h >= 0.06 & h <= 0.18 & s >= 0.35;
alluvium = colored & h >= 0.22 & h <= 0.45;
blueFamily = colored & h >= 0.535 & h <= 0.70;
redFamily = colored & (h >= 0.94 | h <= 0.055);

% Amin's raster merged each filter/drainage pair into one blue strip.  The
% authoritative DWG shows filter next to the core and drainage outside it.
% Split each sloping strip row by row, preserving its original boundaries.
verticalAssembly = rowFraction < 0.59 & ...
    columnFraction >= 0.39 & columnFraction <= 0.61;
sectionDrainage = rowFraction >= 0.40 & rowFraction < 0.61 & ...
    columnFraction > 0.565 & columnFraction <= 0.80;
sectionToe = rowFraction >= 0.40 & rowFraction < 0.61 & ...
    columnFraction > 0.76;
legendRow = rowFraction >= 0.77 & rowFraction <= 0.90;
legendFilter = legendRow & columnFraction >= 0.22 & columnFraction < 0.31;
legendDrainage = legendRow & columnFraction >= 0.31 & columnFraction < 0.40;
legendToe = legendRow & columnFraction >= 0.40 & columnFraction < 0.49;
[verticalFilter,verticalDrain] = split_vertical_blue_strips( ...
    blueFamily & verticalAssembly,columnFraction);
filter = verticalFilter | (blueFamily & legendFilter);
drainage = verticalDrain | (blueFamily & sectionDrainage) | ...
    (blueFamily & legendDrainage);
% Close only small color-mask gaps at the downstream L-junction while
% retaining the original engineering outlines and grid.
drainage = imclose(drainage,strel('disk',2,0)) & blueFamily;
toeDrainage = colored & h >= 0.45 & h < 0.535 & (sectionToe | legendToe);

sectionCore = rowFraction < 0.59 & columnFraction >= 0.43 & columnFraction <= 0.57;
sectionBedrock = rowFraction >= 0.60 & rowFraction < 0.76;
legendCore = legendRow & columnFraction >= 0.04 & columnFraction < 0.13;
legendBedrock = legendRow & columnFraction >= 0.68 & columnFraction < 0.78;
core = redFamily & (sectionCore | legendCore);
bedrock = redFamily & (sectionBedrock | legendBedrock);

sectionGrout = rowFraction >= 0.50 & rowFraction < 0.73 & ...
    columnFraction >= 0.485 & columnFraction <= 0.525;
legendGrout = legendRow & columnFraction >= 0.49 & columnFraction < 0.59;
% Use the geometric curtain mask as well as source hue so JPEG edge pixels
% cannot retain yellow/orange fragments inside the curtain.
grout = (colored & sectionGrout) | (groutColor & legendGrout);

% Task 3 palette: warm embankment, muted clay, pale granular filter,
% charcoal drainage, light toe drain, taupe alluvium, and dark bedrock.
h(shell)=0.085; s(shell)=max(0.18,min(0.30,s(shell)));
h(core)=0.025; s(core)=max(0.30,min(0.48,s(core)));
h(filter)=0.145; s(filter)=max(0.38,min(0.56,s(filter))); v(filter)=max(v(filter),0.80);
h(drainage)=0.59; s(drainage)=max(0.20,min(0.34,s(drainage))); v(drainage)=max(0.46,min(0.62,v(drainage)));
h(toeDrainage)=0.42; s(toeDrainage)=max(0.12,min(0.22,s(toeDrainage))); v(toeDrainage)=max(0.72,min(0.84,v(toeDrainage)));
h(grout)=0.00; s(grout)=min(s(grout),0.05); v(grout)=max(0.62,min(0.78,v(grout)));
h(alluvium)=0.25; s(alluvium)=max(0.12,min(0.22,s(alluvium))); v(alluvium)=max(v(alluvium),0.74);
h(bedrock)=0.02; s(bedrock)=max(0.05,min(0.10,s(bedrock))); v(bedrock)=max(0.38,min(0.55,v(bedrock)));

hsvImage(:,:,1)=h; hsvImage(:,:,2)=s; hsvImage(:,:,3)=v;
recolored=im2uint8(hsv2rgb(hsvImage));
end

function [filterMask,drainMask] = split_vertical_blue_strips(mask,columnFraction)
% The DWG section shows the filter and drainage bands at comparable drawn
% widths. Divide the merged raster strip at its centerline, with the filter
% touching the core and drainage touching the shell.
filterMask = false(size(mask)); drainMask = false(size(mask));
for r = 1:size(mask,1)
    left = find(mask(r,:) & columnFraction(r,:) < 0.50);
    if ~isempty(left)
        cut = min(left) + 0.50*(max(left)-min(left));
        drainMask(r,left(left <= cut)) = true;
        filterMask(r,left(left > cut)) = true;
    end
    right = find(mask(r,:) & columnFraction(r,:) > 0.50);
    if ~isempty(right)
        cut = min(right) + 0.50*(max(right)-min(right));
        filterMask(r,right(right <= cut)) = true;
        drainMask(r,right(right > cut)) = true;
    end
end
end

function cleaned = remove_source_markers(imageData)
% Remove only the compact bright-green circular markers in Amin's raster.
green = imageData(:,:,2) > 135 & ...
    double(imageData(:,:,2)) > 1.30*double(imageData(:,:,1)) & ...
    double(imageData(:,:,2)) > 1.15*double(imageData(:,:,3));
cc = bwconncomp(green);
stats = regionprops(cc,'Area','BoundingBox');
markerMask = false(size(green));
for k = 1:cc.NumObjects
    box = stats(k).BoundingBox;
    if stats(k).Area >= 90 && stats(k).Area <= 260 && box(3) <= 22 && box(4) <= 22 && box(2) < 780
        markerMask(cc.PixelIdxList{k}) = true;
    end
end
markerMask = imdilate(markerMask,strel('disk',4,0));
% Exemplar filling retains the local material color and numerical grid;
% diffusion filling leaves pale circular scars in the textured zones.
cleaned = inpaintExemplar(imageData,markerMask, ...
    'FillOrder','tensor','PatchSize',11);
end

function draw_monitoring_points(ax,rowOffset,colOffset,style)
% Coordinates are transferred from the authoritative Task 2 DWG to the
% Amin redraw using the crest-to-base similarity transformation.
xy = [731 542; 733 425; 736 306; 592 425; 561 542; ...
      624 306; 894 542; 866 425; 837 306; 739 192];
xy(:,1) = xy(:,1)-colOffset;
xy(:,2) = xy(:,2)-rowOffset;
labels = compose('P%d',1:10);
if strcmp(style,'task3')
    face = [0.00 0.53 0.48]; edge = [0.00 0.22 0.25];
else
    face = [0.82 0.30 0.48]; edge = [0.35 0.08 0.22];
end
hold(ax,'on');
scatter(ax,xy(:,1),xy(:,2),72,'o','filled','MarkerFaceColor',face, ...
    'MarkerEdgeColor',edge,'LineWidth',1.1);
dx = [10 10 10 -34 -34 -34 10 10 10 10];
dy = [16 0 0 0 16 0 16 0 0 -15];
for k = 1:10
    text(ax,xy(k,1)+dx(k),xy(k,2)+dy(k),labels{k}, ...
        'FontName','Arial','FontSize',9,'FontWeight','bold','Color',edge, ...
        'BackgroundColor','w','Margin',0.5,'Clipping','on');
end
scatter(ax,1158-colOffset,911-rowOffset,72,'o','filled', ...
    'MarkerFaceColor',face,'MarkerEdgeColor',edge,'LineWidth',1.1);
hold(ax,'off');
end

function [trimmed,rowOffset,colOffset] = trim_uniform_border(imageData,threshold)
if size(imageData,3) == 1
    mask = imageData < threshold;
else
    mask = any(imageData < threshold,3);
end
rows = find(any(mask,2)); cols = find(any(mask,1));
if isempty(rows) || isempty(cols)
    trimmed = imageData; rowOffset = 0; colOffset = 0; return
end
pad = 4;
r1 = max(1,rows(1)-pad); r2 = min(size(imageData,1),rows(end)+pad);
c1 = max(1,cols(1)-pad); c2 = min(size(imageData,2),cols(end)+pad);
trimmed = imageData(r1:r2,c1:c2,:);
rowOffset = r1-1; colOffset = c1-1;
end
