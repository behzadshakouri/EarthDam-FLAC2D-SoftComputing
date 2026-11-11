function paths = generate_task4_geometry_scale_figure(outputDir)
%GENERATE_TASK4_GEOMETRY_SCALE_FIGURE Task 4-specific model/scale composite.
% The upper plate documents the numerical-model lineage. The lower comparison
% adds the four Task 4 scale factors on common axes and gives this paper a
% scale-focused composition distinct from the Task 3 monitoring figure.

analysisDir = fileparts(mfilename('fullpath'));
root = fileparts(analysisDir);
sourceDir = fullfile(analysisDir, 'figure_sources');
if nargin < 1 || isempty(outputDir)
    cfg = task4_config(root);
    outputDir = fullfile(cfg.output_root, 'pointwise_fmrvr');
end
if ~exist(outputDir, 'dir'), mkdir(outputDir); end

crossSection = imread(fullfile(sourceDir,'amin_cross_section_without_callouts.png'));
crossSection = remove_source_markers(crossSection);
% Remove the Task 3-style legend and retain the engineering section, grid,
% water level, and point layout. Task 4 defines the scale comparison below.
crossSection = crossSection(1:round(0.74*size(crossSection,1)),:,:);
[crossSection,rowOffset,colOffset] = trim_uniform_border(crossSection,248);
% Use a Task 4-specific material palette so the adapted engineering drawing
% remains visually distinct from the Task 2 and Task 3 presentations.
crossSection = recolor_task4_materials(crossSection);

f = figure('Visible','off','Color','w','Position',[40 40 1600 1400]);

axTop = axes(f,'Position',[0.025 0.38 0.95 0.59]);
image(axTop,crossSection);
draw_monitoring_points(axTop,rowOffset,colOffset);
axis(axTop,'image'); axis(axTop,'off');

scales = [0.25 0.50 1.00 1.50];
colors = [0.20 0.55 0.75; 0.30 0.65 0.48; 0.95 0.62 0.22; 0.70 0.38 0.68];
axLegend = axes(f,'Position',[0.16 0.317 0.68 0.050]);
draw_material_legend(axLegend);
axScale = axes(f,'Position',[0.13 0.085 0.74 0.160]);
draw_scale_comparison(axScale,scales,colors);

paths.png = fullfile(outputDir,'task4_geometry_scale_composite.png');
paths.pdf = fullfile(outputDir,'task4_geometry_scale_composite.pdf');
exportgraphics(f,paths.png,'Resolution',300);
exportgraphics(f,paths.pdf,'ContentType','image');
close(f);
end

function recolored = recolor_task4_materials(imageData)
% Reassign only the broad material fills while retaining grid lines, labels,
% reservoir symbols, and other dark engineering detail from the source plate.
rgb = im2double(imageData);
hsvImage = rgb2hsv(rgb);
h = hsvImage(:,:,1);
s = hsvImage(:,:,2);
v = hsvImage(:,:,3);
[nRows,~,~] = size(rgb);
rowFraction = repmat((1:nRows)'/nRows,1,size(rgb,2));
columnFraction = repmat((1:size(rgb,2))/size(rgb,2),nRows,1);

coloredFill = s > 0.08 & v > 0.32;
shell = coloredFill & h >= 0.055 & h <= 0.18;
alluvium = coloredFill & h >= 0.20 & h <= 0.46;
redFamily = coloredFill & (h >= 0.94 | h <= 0.045);
core = redFamily & rowFraction < 0.78;
bedrock = redFamily & rowFraction >= 0.78;
% Keep the cyan toe-drain source family separate from the darker blue
% drainage family before any spatial recoloring is applied.
toeFamily = coloredFill & h >= 0.43 & h < 0.535;
blueFamily = coloredFill & h >= 0.535 & h <= 0.70;
% Amin's raster merged each filter/drainage pair into one blue strip.  The
% authoritative DWG shows filter next to the core and drainage outside it.
% Split each sloping strip row by row, then retain the downstream blanket.
verticalAssembly = rowFraction >= 0.18 & rowFraction < 0.80 & ...
    columnFraction >= 0.39 & columnFraction <= 0.61;
downstreamBlanket = rowFraction >= 0.50 & rowFraction < 0.80 & ...
    columnFraction > 0.565 & columnFraction <= 0.80;
toeDrainage = toeFamily & rowFraction >= 0.48 & rowFraction < 0.82 & ...
    columnFraction > 0.76;
[filter,verticalDrainage] = split_vertical_blue_strips( ...
    blueFamily & verticalAssembly,columnFraction);
drainage = verticalDrainage | (blueFamily & downstreamBlanket);
drainage = imclose(drainage,strel('disk',2,0)) & blueFamily;
groutSpatial = columnFraction >= 0.495 & columnFraction <= 0.515 & ...
    rowFraction >= 0.62;
% Recolor every colored curtain pixel within its geometric footprint so
% compressed yellow/orange edge pixels do not survive as a mixed zone.
grout = coloredFill & groutSpatial;

% Material-like palette: compacted earth shell, clay core, sand/gravel
% filters, muted granular drainage, natural alluvium, and gray bedrock.
h(shell) = 0.085;
s(shell) = max(0.18,min(0.30,s(shell)));
h(core) = 0.035;
s(core) = max(0.34,min(0.55,s(core)));
h(alluvium) = 0.25;
s(alluvium) = max(0.12,min(0.22,s(alluvium)));
v(alluvium) = max(v(alluvium),0.74);
h(bedrock) = 0.00;
s(bedrock) = min(s(bedrock),0.06);
v(bedrock) = max(0.48,min(0.68,v(bedrock)));
h(filter) = 0.145;
s(filter) = max(0.38,min(0.56,s(filter)));
v(filter) = max(v(filter),0.80);
h(drainage) = 0.59;
s(drainage) = max(0.20,min(0.34,s(drainage)));
v(drainage) = max(0.46,min(0.62,v(drainage)));
h(toeDrainage) = 0.42;
s(toeDrainage) = max(0.12,min(0.22,s(toeDrainage)));
v(toeDrainage) = max(0.72,min(0.84,v(toeDrainage)));
h(grout) = 0.00;
s(grout) = min(s(grout),0.05);
v(grout) = max(0.64,min(0.86,v(grout)));

hsvImage(:,:,1) = h;
hsvImage(:,:,2) = s;
hsvImage(:,:,3) = v;
recolored = im2uint8(hsv2rgb(hsvImage));
end

function [filterMask,drainMask] = split_vertical_blue_strips(mask,columnFraction)
% Match the comparable filter and drainage widths drawn in the DWG. The
% filter is the inner zone beside the core and drainage is the outer zone.
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
green = imageData(:,:,2) > 135 & ...
    double(imageData(:,:,2)) > 1.30*double(imageData(:,:,1)) & ...
    double(imageData(:,:,2)) > 1.15*double(imageData(:,:,3));
cc = bwconncomp(green);
stats = regionprops(cc,'Area','BoundingBox');
markerMask = false(size(green));
for k = 1:cc.NumObjects
    box = stats(k).BoundingBox;
    if stats(k).Area >= 90 && stats(k).Area <= 260 && box(3) <= 22 && box(4) <= 22
        markerMask(cc.PixelIdxList{k}) = true;
    end
end
markerMask = imdilate(markerMask,strel('disk',4,0));
cleaned = inpaintExemplar(imageData,markerMask, ...
    'FillOrder','tensor','PatchSize',11);
end

function draw_monitoring_points(ax,rowOffset,colOffset)
xy = [731 542; 733 425; 736 306; 592 425; 561 542; ...
      624 306; 894 542; 866 425; 837 306; 739 192];
xy(:,1) = xy(:,1)-colOffset;
xy(:,2) = xy(:,2)-rowOffset;
labels = compose('P%d',1:10);
face = [0.82 0.30 0.48]; edge = [0.35 0.08 0.22];
hold(ax,'on');
scatter(ax,xy(:,1),xy(:,2),78,'d','filled','MarkerFaceColor',face, ...
    'MarkerEdgeColor',edge,'LineWidth',1.1);
dx = [10 10 10 -34 -34 -34 10 10 10 10];
dy = [16 0 0 0 16 0 16 0 0 -15];
for k = 1:10
    text(ax,xy(k,1)+dx(k),xy(k,2)+dy(k),labels{k}, ...
        'FontName','Arial','FontSize',9,'FontWeight','bold','Color',edge, ...
        'BackgroundColor','w','Margin',0.5,'Clipping','on');
end
hold(ax,'off');
end

function draw_material_legend(ax)
labels = {'Core','Shell','Filter','Drainage','Toe drainage', ...
    'Grout curtain','Alluvium','Bedrock'};
palette = [0.92 0.62 0.55; 0.93 0.82 0.64; 0.92 0.83 0.35; ...
    0.42 0.52 0.64; 0.66 0.82 0.73; 0.68 0.68 0.68; ...
    0.72 0.82 0.62; 0.48 0.44 0.43];
cla(ax); hold(ax,'on');
for k = 1:numel(labels)
    rectangle(ax,'Position',[k-0.88 0.42 0.72 0.34], ...
        'FaceColor',palette(k,:),'EdgeColor',[0.20 0.20 0.20], ...
        'LineWidth',0.8);
    text(ax,k-0.52,0.28,labels{k},'HorizontalAlignment','center', ...
        'VerticalAlignment','top','FontName','Arial','FontSize',8.5);
end
xlim(ax,[0 8]); ylim(ax,[0 1]); axis(ax,'off'); hold(ax,'off');
end

function draw_scale_comparison(ax,scales,colors)
hold(ax,'on'); box(ax,'on');
handles = gobjects(numel(scales),1);
% Reference cross-section dimensions read from the engineering drawing.
referenceBaseWidth = 270.00;   % m, toe to toe
referenceCrestWidth = 10.95;   % m
referenceHeight = 69.12;       % m, EL 1694.22 - EL 1625.10
referenceCoreBase = 20.23;     % m
referenceCoreTop = 5.00;       % m
% Draw the largest first so every smaller configuration remains visible.
for k = numel(scales):-1:1
    lambda = scales(k); color = colors(k,:);
    base = referenceBaseWidth*lambda;
    crest = referenceCrestWidth*lambda;
    height = referenceHeight*lambda;
    x = [-base/2 -crest/2 crest/2 base/2];
    y = [0 height height 0];
    handles(k) = plot(ax,[x x(1)],[y y(1)],'Color',color,'LineWidth',2.4);
    coreWidthBase = referenceCoreBase*lambda;
    coreWidthTop = referenceCoreTop*lambda;
    plot(ax,[-coreWidthBase/2 -coreWidthTop/2 coreWidthTop/2 coreWidthBase/2], ...
        [0 height height 0],'Color',color,'LineWidth',1.25);
end
plot(ax,[-215 215],[0 0],'Color',[0.20 0.20 0.20],'LineWidth',1.1, ...
    'HandleVisibility','off');
xlim(ax,[-220 220]); ylim(ax,[-6 112]); axis(ax,'equal');
xticks(ax,-200:50:200); yticks(ax,0:20:100);
xlabel(ax,'Horizontal distance from dam centerline (m)');
ylabel(ax,'Elevation above foundation (m)');
legend(ax,handles,compose('\\lambda = %.2f',scales), ...
    'Location','eastoutside','Box','off','Interpreter','tex');
set(ax,'FontName','Arial','FontSize',12,'TickDir','out','LineWidth',0.8, ...
    'XGrid','on','YGrid','on','GridAlpha',0.12);
end

function [trimmed,rowOffset,colOffset] = trim_uniform_border(imageData,threshold)
if size(imageData,3) == 1
    mask = imageData < threshold;
else
    mask = any(imageData < threshold,3);
end
rows = find(any(mask,2)); cols = find(any(mask,1));
if isempty(rows) || isempty(cols)
    trimmed = imageData;
    rowOffset = 0; colOffset = 0;
    return
end
pad = 4;
r1 = max(1,rows(1)-pad); r2 = min(size(imageData,1),rows(end)+pad);
c1 = max(1,cols(1)-pad); c2 = min(size(imageData,2),cols(end)+pad);
trimmed = imageData(r1:r2,c1:c2,:);
rowOffset = r1-1; colOffset = c1-1;
end
